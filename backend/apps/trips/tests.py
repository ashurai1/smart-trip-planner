from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from apps.trips.models import Trip

User = get_user_model()

class TripTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='testuser', password='testpassword')
        self.client.force_authenticate(user=self.user)
        self.trip_data = {
            'title': 'Test Trip',
            'description': 'A trip for testing',
            'start_date': '2024-01-01',
            'end_date': '2024-01-05'
        }

    def test_create_trip(self):
        """Test creating a new trip."""
        response = self.client.post('/api/trips/', self.trip_data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Trip.objects.count(), 1)
        self.assertEqual(Trip.objects.get().title, 'Test Trip')

    def test_get_trips(self):
        """Test retrieving list of trips."""
        Trip.objects.create(owner=self.user, title="Trip 1")
        Trip.objects.create(owner=self.user, title="Trip 2")
        
        response = self.client.get('/api/trips/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Depending on pagination, check results count or length
        # Standard DRF pagination returns 'results' key
        self.assertTrue(len(response.data['results']) >= 2)
