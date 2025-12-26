"""
Serializers for Chat management.

DESIGN NOTE:
REST-based chat using polling. No real-time features.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import ChatMessage

User = get_user_model()


class UserBasicSerializer(serializers.ModelSerializer):
    """Basic user information for message sender."""
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email']
        read_only_fields = ['id', 'username', 'email']


class ChatMessageSerializer(serializers.ModelSerializer):
    """
    Serializer for chat messages.
    
    Handles:
    - Sending messages (auto-assigns sender and trip)
    - Displaying messages with sender info
    """
    
    sender = UserBasicSerializer(read_only=True)
    
    class Meta:
        model = ChatMessage
        fields = [
            'id',
            'trip',
            'sender',
            'message',
            'created_at'
        ]
        read_only_fields = ['id', 'trip', 'sender', 'created_at']
    
    def validate(self, data):
        """
        Validate that message is provided.
        """
        message = data.get('message')
        
        if not message:
            raise serializers.ValidationError("Message is required.")
        return data
    
    def create(self, validated_data):
        """
        Create a new message.
        Auto-assigns trip and sender from context.
        """
        trip = self.context.get('trip')
        user = self.context.get('request').user
        
        if not trip:
            raise serializers.ValidationError("Trip context is required.")
        
        message = ChatMessage.objects.create(
            trip=trip,
            sender=user,
            **validated_data
        )
        
        return message
