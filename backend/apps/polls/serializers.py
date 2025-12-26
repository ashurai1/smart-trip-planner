"""
Serializers for Poll management.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.db import transaction, IntegrityError
from .models import Poll, PollOption, Vote

User = get_user_model()


class UserBasicSerializer(serializers.ModelSerializer):
    """Basic user information for nested representations."""
    class Meta:
        model = User
        fields = ['id', 'username', 'email']
        read_only_fields = ['id', 'username', 'email']


class PollOptionSerializer(serializers.ModelSerializer):
    """
    Serializer for poll options.
    Includes vote count for display.
    """
    vote_count = serializers.IntegerField(read_only=True, default=0)
    
    class Meta:
        model = PollOption
        fields = ['id', 'text', 'vote_count']
        read_only_fields = ['id', 'vote_count']


class PollSerializer(serializers.ModelSerializer):
    """
    Serializer for Poll model.
    
    Handles:
    - Creating polls with nested options
    - Displaying poll details with results
    - Validation for minimum options
    """
    
    created_by = UserBasicSerializer(read_only=True)
    options = PollOptionSerializer(many=True)
    has_voted = serializers.SerializerMethodField()
    
    class Meta:
        model = Poll
        fields = [
            'id',
            'trip',
            'question',
            'created_by',
            'options',
            'has_voted',
            'created_at'
        ]
        read_only_fields = ['id', 'trip', 'created_by', 'created_at', 'has_voted']
    
    def get_has_voted(self, obj):
        """Check if the requesting user has voted in this poll."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.has_user_voted(request.user)
        return False
    
    def validate_options(self, value):
        """Validate that at least 2 options are provided."""
        if len(value) < 2:
            raise serializers.ValidationError(
                "A poll must have at least 2 options."
            )
        
        # Check for duplicate option texts
        option_texts = [opt['text'].strip().lower() for opt in value]
        if len(option_texts) != len(set(option_texts)):
            raise serializers.ValidationError(
                "Duplicate options are not allowed."
            )
        
        return value
    
    def create(self, validated_data):
        """
        Create poll with nested options atomically.
        """
        options_data = validated_data.pop('options')
        
        # Get trip and user from context
        trip = self.context.get('trip')
        user = self.context.get('request').user
        
        if not trip:
            raise serializers.ValidationError("Trip context is required.")
        
        with transaction.atomic():
            # Create poll
            poll = Poll.objects.create(
                trip=trip,
                created_by=user,
                **validated_data
            )
            
            # Create options
            for option_data in options_data:
                PollOption.objects.create(
                    poll=poll,
                    **option_data
                )
        
        return poll
    
    def to_representation(self, instance):
        """
        Customize representation to include vote counts.
        """
        representation = super().to_representation(instance)
        
        # Get options with vote counts
        options_with_counts = instance.get_results()
        representation['options'] = options_with_counts
        
        return representation


class VoteSerializer(serializers.Serializer):
    """
    Serializer for casting a vote.
    
    Validates:
    - Option belongs to poll
    - User hasn't voted yet
    - User has access to trip
    """
    
    option_id = serializers.IntegerField(required=True)
    
    def validate_option_id(self, value):
        """Validate that the option exists."""
        try:
            option = PollOption.objects.get(id=value)
        except PollOption.DoesNotExist:
            raise serializers.ValidationError("Invalid option ID.")
        return value
    
    def validate(self, data):
        """
        Validate business rules for voting.
        """
        poll = self.context.get('poll')
        user = self.context.get('request').user
        option_id = data.get('option_id')
        
        # Get the option
        try:
            option = PollOption.objects.get(id=option_id)
        except PollOption.DoesNotExist:
            raise serializers.ValidationError({"option_id": "Option does not exist."})
        
        # Ensure option belongs to this poll
        if option.poll != poll:
            raise serializers.ValidationError(
                {"option_id": "This option does not belong to the specified poll."}
            )
        
        # Check if user has already voted (API-level check)
        if poll.has_user_voted(user):
            raise serializers.ValidationError(
                "You have already voted in this poll. Votes cannot be changed."
            )
        
        # Store option for save method
        data['option'] = option
        
        return data
    
    def save(self):
        """
        Create the vote with race condition handling.
        
        Even if two requests pass the validation simultaneously,
        the database unique constraint will catch the duplicate.
        """
        poll = self.context.get('poll')
        user = self.context.get('request').user
        option = self.validated_data['option']
        
        try:
            with transaction.atomic():
                vote = Vote.objects.create(
                    poll=poll,
                    option=option,
                    user=user
                )
            return vote
        except IntegrityError:
            # Database caught a duplicate vote (race condition)
            raise serializers.ValidationError(
                "You have already voted in this poll. Votes cannot be changed."
            )
