from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from django.core import mail
from apps.trips.models import Trip, TripInvite

User = get_user_model()

class TripInviteTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.owner = User.objects.create_user(username='owner', email='owner@example.com', password='password')
        self.user = User.objects.create_user(username='user', email='user@example.com', password='password')
        self.other_user = User.objects.create_user(username='other', email='other@example.com', password='password')
        
        self.trip = Trip.objects.create(owner=self.owner, title="Test Trip")
        
        # Authenticate as owner
        self.client.force_authenticate(user=self.owner)

    def test_send_invite_email_success(self):
        """Test sending an invite to an email (new user)."""
        data = {'identifier': 'newuser@example.com'}
        response = self.client.post(f'/api/trips/{self.trip.id}/invite/', data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(TripInvite.objects.count(), 1)
        invite = TripInvite.objects.first()
        self.assertEqual(invite.invited_email, 'newuser@example.com')
        self.assertIsNone(invite.invited_user)
        self.assertEqual(len(mail.outbox), 1)

    def test_send_invite_username_success(self):
        """Test sending an invite via username."""
        data = {'identifier': 'user'}
        response = self.client.post(f'/api/trips/{self.trip.id}/invite/', data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        invite = TripInvite.objects.first()
        self.assertEqual(invite.invited_user, self.user)
        self.assertEqual(len(mail.outbox), 1)

    def test_send_invite_email_existing_user(self):
        """Test sending invite by email where user exists - should link user."""
        data = {'identifier': 'user@example.com'}
        response = self.client.post(f'/api/trips/{self.trip.id}/invite/', data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        invite = TripInvite.objects.first()
        self.assertEqual(invite.invited_user, self.user)
        self.assertEqual(invite.invited_email, 'user@example.com')

    def test_send_invite_missing_fields(self):
        """Test validation error when fields missing."""
        data = {}
        response = self.client.post(f'/api/trips/{self.trip.id}/invite/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_accept_invite_username_success(self):
        """Test accepting a username-based invite."""
        invite = TripInvite.objects.create(trip=self.trip, invited_user=self.user)
        self.client.force_authenticate(user=self.user)
        response = self.client.get(f'/api/trips/invites/accept/{invite.token}/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        invite.refresh_from_db()
        self.assertEqual(invite.status, 'ACCEPTED')

    def test_accept_invite_wrong_user(self):
        """Test that wrong user cannot accept username-limited invite."""
        invite = TripInvite.objects.create(trip=self.trip, invited_user=self.user)
        self.client.force_authenticate(user=self.other_user)
        response = self.client.get(f'/api/trips/invites/accept/{invite.token}/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_invite_already_member_username(self):
        """Test inviting a user who is already a member (username) returns 400."""
        self.trip.collaborators.add(self.user)
        data = {'identifier': 'user'}
        response = self.client.post(f'/api/trips/{self.trip.id}/invite/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        error_msg = response.data.get('detail')
        self.assertIn("already a member", str(error_msg))

    def test_invite_already_member_email(self):
        """Test inviting a user who is already a member (email) returns 400."""
        self.trip.collaborators.add(self.user)
        data = {'identifier': 'user@example.com'}
        response = self.client.post(f'/api/trips/{self.trip.id}/invite/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
    def test_invite_pending_username(self):
        """Test duplicated pending invite (username) returns 400."""
        TripInvite.objects.create(trip=self.trip, invited_user=self.user)
        data = {'identifier': 'user'}
        response = self.client.post(f'/api/trips/{self.trip.id}/invite/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        error_msg = response.data.get('detail')
        self.assertIn("already invited", str(error_msg))

    def test_invite_pending_email(self):
        """Test duplicated pending invite (email) returns 400."""
        TripInvite.objects.create(trip=self.trip, invited_email='new@example.com')
        data = {'identifier': 'new@example.com'}
        response = self.client.post(f'/api/trips/{self.trip.id}/invite/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
