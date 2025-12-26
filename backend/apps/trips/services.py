from django.db.models import F
from .models import TripNotificationState, Notification

def increment_notification_count(trip, sender, type):
    """
    Increment notification count for all trip members except the sender.
    type: 'chat', 'poll', 'itinerary'
    """
    field_map = {
        'chat': 'unread_chat_count',
        'poll': 'unread_poll_count',
        'itinerary': 'unread_itinerary_count'
    }
    
    field = field_map.get(type)
    if not field:
        return

    # Get all members (owner + collaborators)
    members = set(trip.collaborators.all())
    members.add(trip.owner)
    
    # Exclude sender
    if sender in members:
        members.remove(sender)
        
    for member in members:
        # Get or create state
        state, _ = TripNotificationState.objects.get_or_create(user=member, trip=trip)
        setattr(state, field, getattr(state, field) + 1)
        state.save()
        
    # Create persistent notifications for all members (except sender)
    # Using bulk_create for efficiency if list gets large, but loop is fine for MVP group sizes
    notifications_to_create = []
    
    # Define verb based on type
    verb_map = {
        'chat': 'sent a new message',
        'poll': 'created a new poll',
        'itinerary': 'updated the itinerary'
    }
    verb = verb_map.get(type, 'made an update')
    
    for member in members:
        notifications_to_create.append(
            Notification(
                recipient=member,
                actor=sender,
                trip=trip,
                verb=verb,
                target_type=type
            )
        )
    
    if notifications_to_create:
        Notification.objects.bulk_create(notifications_to_create)
