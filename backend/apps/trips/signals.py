"""
Signals for automatic notification creation.
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import TripInvite, ItineraryItem, Notification
from apps.chat.models import ChatMessage
from apps.polls.models import Poll


@receiver(post_save, sender=TripInvite)
def create_invite_notification(sender, instance, created, **kwargs):
    """Create notification when a trip invite is sent."""
    if created:
        recipient = instance.invited_user if instance.invited_user else None
        if recipient:
            Notification.objects.create(
                recipient=recipient,
                actor=instance.invited_by,
                trip=instance.trip,
                verb=f"invited you to {instance.trip.title}",
                target_type='invite',
            )


@receiver(post_save, sender=ChatMessage)
def create_chat_notification(sender, instance, created, **kwargs):
    """Create notifications for all trip collaborators when a message is sent."""
    if created:
        trip = instance.trip
        # Notify all collaborators except the sender
        collaborators = trip.collaborators.exclude(id=instance.user.id)
        
        notifications = [
            Notification(
                recipient=collaborator,
                actor=instance.user,
                trip=trip,
                verb=f"sent a message in {trip.title}",
                target_type='chat',
            )
            for collaborator in collaborators
        ]
        
        Notification.objects.bulk_create(notifications)


@receiver(post_save, sender=Poll)
def create_poll_notification(sender, instance, created, **kwargs):
    """Create notifications when a poll is created."""
    if created:
        trip = instance.trip
        # Notify all collaborators except the creator
        collaborators = trip.collaborators.exclude(id=instance.created_by.id)
        
        notifications = [
            Notification(
                recipient=collaborator,
                actor=instance.created_by,
                trip=trip,
                verb=f"created a poll in {trip.title}",
                target_type='poll',
            )
            for collaborator in collaborators
        ]
        
        Notification.objects.bulk_create(notifications)


@receiver(post_save, sender=ItineraryItem)
def create_itinerary_notification(sender, instance, created, **kwargs):
    """Create notifications when an itinerary item is added."""
    if created:
        trip = instance.trip
        # Notify all collaborators except the creator
        collaborators = trip.collaborators.exclude(id=instance.created_by.id)
        
        notifications = [
            Notification(
                recipient=collaborator,
                actor=instance.created_by,
                trip=trip,
                verb=f"added '{instance.title}' to {trip.title}",
                target_type='itinerary',
            )
            for collaborator in collaborators
        ]
        
        Notification.objects.bulk_create(notifications)
