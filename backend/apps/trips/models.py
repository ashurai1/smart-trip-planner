"""
Trip models for Smart Trip Planner.
"""
import uuid
from django.db import models
from django.conf import settings
from django.contrib.auth import get_user_model

User = get_user_model()


class Trip(models.Model):
    """
    Trip model representing a planned trip.
    
    Business Rules:
    - Each trip has one owner (creator)
    - Multiple users can be collaborators
    - Owner has full control (update, delete, manage collaborators)
    - Collaborators can view trip details
    """
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Unique identifier for the trip"
    )
    
    title = models.CharField(
        max_length=200,
        help_text="Title of the trip"
    )
    
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Detailed description of the trip"
    )
    
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Detailed description of the trip"
    )
    
    owner = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='owned_trips',
        help_text="User who created the trip"
    )
    
    collaborators = models.ManyToManyField(
        User,
        related_name='collaborated_trips',
        blank=True,
        help_text="Users who can view and collaborate on the trip"
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Timestamp when trip was created",
        db_index=True
    )
    
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Timestamp when trip was last updated"
    )
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Trip'
        verbose_name_plural = 'Trips'
    
    def __str__(self):
        return f"{self.title} (by {self.owner.username})"
    
    def is_owner(self, user):
        """Check if user is the owner of this trip."""
        return self.owner == user
    
    def is_collaborator(self, user):
        """Check if user is a collaborator on this trip."""
        return self.collaborators.filter(id=user.id).exists()
    
    def has_access(self, user):
        """Check if user has access to this trip (owner or collaborator)."""
        return self.is_owner(user) or self.is_collaborator(user)


class ItineraryItem(models.Model):
    """
    Itinerary item for a trip.
    
    Business Rules:
    - Each item belongs to one trip
    - Items are ordered using the 'order' field
    - New items are automatically appended to the end
    - Only trip owner/collaborators can manage items
    """
    
    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        related_name='itinerary_items',
        help_text="Trip this item belongs to"
    )
    
    title = models.CharField(
        max_length=200,
        help_text="Title of the itinerary item"
    )
    
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Detailed description of the item"
    )

    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='created_itinerary_items',
        help_text="User who created this item",
        null=True, # Allow null for existing items
        blank=True
    )

    
    order = models.PositiveIntegerField(
        default=0,
        help_text="Order position in the itinerary (lower = earlier)"
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Timestamp when item was created",
        db_index=True
    )
    
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Timestamp when item was last updated"
    )
    
    class Meta:
        ordering = ['order', 'created_at']
        verbose_name = 'Itinerary Item'
        verbose_name_plural = 'Itinerary Items'
        # Ensure unique ordering within a trip
        unique_together = [['trip', 'order']]
    
    def __str__(self):
        return f"{self.title} (Trip: {self.trip.title})"
    
    @classmethod
    def get_next_order(cls, trip):
        """
        Get the next order value for a new item in this trip.
        Returns the maximum order + 1, or 1 if no items exist.
        """
        max_order = cls.objects.filter(trip=trip).aggregate(
            models.Max('order')
        )['order__max']
        return (max_order or 0) + 1


class TripInvite(models.Model):
    """
    Email-based invitation to join a trip.
    """
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('ACCEPTED', 'Accepted'),
    ]
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        related_name='invites',
        help_text="Trip the user is invited to"
    )
    
    invited_email = models.EmailField(
        help_text="Email of the invited user",
        db_index=True,
        null=True,
        blank=True
    )

    invited_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='trip_invites',
        help_text="Registered user who is invited"
    )
    
    invited_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_trip_invites',
        help_text="User who sent the invite",
        null=True, # Temporarily null for migration compatibility
        blank=True
    )
    
    token = models.UUIDField(
        default=uuid.uuid4,
        unique=True,
        editable=False,
        help_text="Unique token for accepting the invite"
    )
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Trip Invite'
        verbose_name_plural = 'Trip Invites'
        
    def __str__(self):
        if self.invited_user:
            return f"Invite: {self.invited_user.username} ({self.trip.title})"
        return f"Invite: {self.invited_email} ({self.trip.title})"

    def clean(self):
        from django.core.exceptions import ValidationError
        if not self.invited_email and not self.invited_user:
            raise ValidationError("Either invited_email or invited_user must be provided.")


class TripNotificationState(models.Model):
    """
    Tracks unread notification counts for a user in a specific trip.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='trip_notification_states',
        help_text="User getting notifications"
    )
    
    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        related_name='notification_states',
        help_text="Trip context"
    )
    
    unread_chat_count = models.PositiveIntegerField(default=0)
    unread_poll_count = models.PositiveIntegerField(default=0)
    unread_itinerary_count = models.PositiveIntegerField(default=0)
    
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = [['user', 'trip']]
        indexes = [
            models.Index(fields=['user', 'trip']),
        ]
        

class Notification(models.Model):
    """
    Persistent notification history for a user.
    """
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications', help_text="User receiving the notification")
    actor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='triggered_notifications', help_text="User who triggered the notification")
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name='notifications', null=True, blank=True, help_text="Related trip")
    
    verb = models.CharField(max_length=255, help_text="Action description (e.g. 'sent a message')")
    target_type = models.CharField(max_length=50, choices=[('chat', 'Chat'), ('poll', 'Poll'), ('itinerary', 'Itinerary'), ('invite', 'Invite')])
    
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    
    class Meta:
        ordering = ['-created_at']
        
    def __str__(self):
        return f"Notification for {self.recipient}: {self.verb}"

