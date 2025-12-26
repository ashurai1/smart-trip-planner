"""
Chat models for Smart Trip Planner.

DESIGN NOTE:
This is a simplified REST-based chat implementation suitable for evaluation.
Real-time features (WebSockets, push notifications) are future scope.
Messages are fetched via polling (GET requests).
"""
from django.db import models
from django.contrib.auth import get_user_model
from apps.trips.models import Trip

User = get_user_model()


class ChatMessage(models.Model):
    """
    Chat message for trip communication.
    
    Design Philosophy:
    - Simple REST API approach (no WebSockets)
    - Messages fetched via polling
    - Suitable for evaluation and prototyping
    - Real-time chat is future enhancement
    
    Business Rules:
    - Each message belongs to one trip
    - Only trip owner/collaborators can send/view messages
    - Messages ordered by creation time
    """
    
    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        related_name='chat_messages',
        help_text="Trip this message belongs to"
    )
    
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_messages',
        help_text="User who sent this message"
    )
    
    message = models.TextField(
        help_text="Message content",
        blank=True  # Allow blank if image/video is sent
    )



    
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Timestamp when message was sent"
    )
    
    class Meta:
        ordering = ['created_at']  # Chronological order
        verbose_name = 'Chat Message'
        verbose_name_plural = 'Chat Messages'
        indexes = [
            models.Index(fields=['trip', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.sender.username}: {self.message[:50]} (Trip: {self.trip.title})"
