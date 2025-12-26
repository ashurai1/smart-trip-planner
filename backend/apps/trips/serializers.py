"""
Serializers for Trip management.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.db import transaction, models
from .models import Trip, ItineraryItem

User = get_user_model()


class UserBasicSerializer(serializers.ModelSerializer):
    """
    Basic user information for nested representations.
    """
    class Meta:
        model = User
        fields = ['id', 'username', 'email']
        read_only_fields = ['id', 'username', 'email']



from apps.users.serializers import UserSerializer

class TripSerializer(serializers.ModelSerializer):
    """
    Serializer for Trip model.
    Handles creation, updates, and list display with nested user info.
    """
    owner = UserSerializer(read_only=True)
    collaborators = UserSerializer(many=True, read_only=True)
    is_owner = serializers.SerializerMethodField()
    notifications = serializers.SerializerMethodField()
    
    collaborator_ids = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(),
        many=True,
        write_only=True,
        required=False,
        source='collaborators'
    )
    
    class Meta:
        model = Trip
        fields = [
            'id', 
            'title', 
            'description', 
            'owner', 
            'collaborators', 
            'collaborator_ids', 
            'created_at', 
            'updated_at',
            'is_owner',
            'notifications'
        ]
        read_only_fields = ['id', 'owner', 'created_at', 'updated_at', 'is_owner', 'notifications']
    
    def create(self, validated_data):
        """
        Create a new trip and auto-assign the owner from request.user.
        """
        # Extract collaborators if provided
        collaborators = validated_data.pop('collaborators', [])
        
        # Get the requesting user from context
        request = self.context.get('request')
        if not request or not request.user or not request.user.is_authenticated:
            raise serializers.ValidationError("Authentication required to create a trip.")
        
        # Create trip with owner
        trip = Trip.objects.create(
            owner=request.user,
            **validated_data
        )
        
        # Add collaborators (excluding owner)
        if collaborators:
            # Filter out owner if they're in the collaborators list
            unique_collaborators = [c for c in collaborators if c != request.user]
            trip.collaborators.set(unique_collaborators)
        
        return trip
    
    def validate_collaborator_ids(self, value):
        if len(value) != len(set(value)):
            raise serializers.ValidationError("Duplicate collaborators are not allowed.")
        return value

    def get_is_owner(self, obj):
        try:
            request = self.context.get('request')
            if request and hasattr(request, 'user') and request.user.is_authenticated:
                return obj.owner == request.user
            return False
        except Exception:
            return False

    def get_notifications(self, obj):
        try:
            request = self.context.get('request')
            if not request or not hasattr(request, 'user') or not request.user.is_authenticated:
                return 0
            
            # Use prefetched related if available to avoid N+1
            if hasattr(obj, '_prefetched_objects_cache') and 'notification_states' in obj._prefetched_objects_cache:
                 state = next((s for s in obj.notification_states.all() if s.user_id == request.user.id), None)
            else:
                 state = obj.notification_states.filter(user=request.user).first()
            
            if state:
                return (state.unread_chat_count or 0) + \
                       (state.unread_poll_count or 0) + \
                       (state.unread_itinerary_count or 0)
            return 0
        except Exception:
            return 0


class AddCollaboratorSerializer(serializers.Serializer):
    """
    Serializer for adding a collaborator to a trip.
    """
    
    username = serializers.CharField(required=True)
    
    def validate(self, data):
        """
        Validate business rules for adding collaborator.
        """
        trip = self.context.get('trip')
        username = data.get('username')
        
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            raise serializers.ValidationError({"username": "User does not exist."})
        
        # Check if user is the owner
        if trip.owner == user:
            raise serializers.ValidationError(
                {"username": "Owner cannot be added as a collaborator."}
            )
        
        # Check if user is already a collaborator
        if trip.collaborators.filter(id=user.id).exists():
            raise serializers.ValidationError(
                {"username": "User is already a collaborator on this trip."}
            )
        
        # Store user object for view
        data['user'] = user
        return data


class RemoveCollaboratorSerializer(serializers.Serializer):
    """
    Serializer for removing a collaborator from a trip.
    """
    
    username = serializers.CharField(required=True)
    
    def validate(self, data):
        """
        Validate that user is actually a collaborator.
        """
        trip = self.context.get('trip')
        username = data.get('username')
        
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            raise serializers.ValidationError({"username": "User does not exist."})
        
        # Check if user is a collaborator
        if not trip.collaborators.filter(id=user.id).exists():
            raise serializers.ValidationError(
                {"username": "User is not a collaborator on this trip."}
            )
            
        # Store user object for view
        data['user'] = user
        return data


class ItineraryItemSerializer(serializers.ModelSerializer):
    """
    Serializer for ItineraryItem model.
    
    Handles:
    - Creating items (auto-assigned to trip, auto-ordered at end)
    - Updating items
    - Displaying item details
    """
    
    class Meta:
        model = ItineraryItem
        fields = [
            'id',
            'trip',
            'title',
            'description',
            'order',
            'created_by',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'trip', 'order', 'created_by', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        """
        Create a new itinerary item.
        Auto-assigns trip from context, order at the end, and created_by.
        """
        # Get trip from context (passed from view)
        trip = self.context.get('trip')
        request = self.context.get('request')
        
        if not trip:
            raise serializers.ValidationError("Trip context is required.")
        
        # Get next order value
        next_order = ItineraryItem.get_next_order(trip)
        
        # Create item
        item = ItineraryItem.objects.create(
            trip=trip,
            order=next_order,
            created_by=request.user, # Assign creator
            **validated_data
        )
        
        return item


class ReorderItinerarySerializer(serializers.Serializer):
    """
    Serializer for reordering itinerary items.
    
    Accepts a list of item IDs in the desired order.
    Updates the order field of each item accordingly.
    """
    
    item_ids = serializers.ListField(
        child=serializers.IntegerField(),
        required=True,
        help_text="List of item IDs in desired order"
    )
    
    def validate_item_ids(self, value):
        """
        Validate that:
        - No duplicates in the list
        - All IDs are valid integers
        """
        if len(value) != len(set(value)):
            raise serializers.ValidationError("Duplicate item IDs are not allowed.")
        
        if not value:
            raise serializers.ValidationError("At least one item ID is required.")
        
        return value
    
    def validate(self, data):
        """
        Validate that all item IDs belong to the trip.
        """
        trip = self.context.get('trip')
        item_ids = data.get('item_ids')
        
        # Get all items for this trip
        trip_items = ItineraryItem.objects.filter(trip=trip)
        trip_item_ids = set(trip_items.values_list('id', flat=True))
        
        # Check if all provided IDs belong to this trip
        provided_ids = set(item_ids)
        
        if not provided_ids.issubset(trip_item_ids):
            invalid_ids = provided_ids - trip_item_ids
            raise serializers.ValidationError({
                "item_ids": f"Invalid item IDs: {list(invalid_ids)}. "
                           "These items do not belong to this trip."
            })
        
        # Check if all trip items are included (no missing items)
        if provided_ids != trip_item_ids:
            missing_ids = trip_item_ids - provided_ids
            raise serializers.ValidationError({
                "item_ids": f"Missing item IDs: {list(missing_ids)}. "
                           "All trip items must be included in reorder."
            })
        
        return data
    
    def save(self):
        """
        Update the order of all items atomically.
        
        Logic (Two-Phase Update to avoid unique constraint violations):
        Phase 1: Add a large offset to all items' order values
        Phase 2: Set the final order values
        
        This prevents intermediate constraint violations when swapping orders.
        """
        item_ids = self.validated_data['item_ids']
        trip = self.context.get('trip')
        
        with transaction.atomic():
            # Phase 1: Add large offset (10000) to all items to free up order values
            # This ensures no conflicts during the update
            ItineraryItem.objects.filter(trip=trip).update(
                order=models.F('order') + 10000
            )
            
            # Phase 2: Set final order values based on position in list
            for index, item_id in enumerate(item_ids, start=1):
                ItineraryItem.objects.filter(
                    id=item_id,
                    trip=trip
                ).update(order=index)
        
        # Return updated items in new order
        return ItineraryItem.objects.filter(trip=trip).order_by('order')


from .models import Trip, TripInvite, ItineraryItem, Notification
from apps.users.serializers import UserSerializer





class NotificationSerializer(serializers.ModelSerializer):
    actor = UserSerializer(read_only=True)
    trip_title = serializers.CharField(source='trip.title', read_only=True)
    
    class Meta:
        model = Notification
        fields = ['id', 'actor', 'trip', 'trip_title', 'verb', 'target_type', 'is_read', 'created_at']
        read_only_fields = ['id', 'actor', 'trip', 'verb', 'target_type', 'created_at']


from .utils.exceptions import Conflict

class TripInviteSerializer(serializers.ModelSerializer):
    """
    Unified Serializer for TripInvite.
    Accepts 'identifier' (Email or Username).
    """
    trip_title = serializers.CharField(source='trip.title', read_only=True)
    identifier = serializers.CharField(write_only=True, required=True, help_text="Email or Username")
    invited_by = UserBasicSerializer(read_only=True)
    invited_user = UserBasicSerializer(read_only=True)
    invited_email = serializers.EmailField(read_only=True)
    
    class Meta:
        model = TripInvite
        fields = [
            'id',
            'trip',
            'trip_title',
            'identifier',
            'status',
            'invited_by',
            'invited_user',
            'invited_email',
            'token',
            'created_at',
        ]
        read_only_fields = ['id', 'trip', 'status', 'created_at']

    def validate(self, data):
        """
        Validate unified identifier.
        """
        trip = self.context.get('trip')
        identifier = data.get('identifier').strip()
        
        if not trip:
            raise serializers.ValidationError("Trip context missing.")

        email = None
        username = None
        invited_user = None
        
        # 1. Parse Identifier
        if '@' in identifier:
            email = identifier
        else:
            username = identifier
            
        User = get_user_model()
        
        # 2. Resolve User
        if username:
            try:
                invited_user = User.objects.get(username__iexact=username)
            except User.DoesNotExist:
                raise serializers.ValidationError({"identifier": "User not found."}) # 404-like error
        
        if email:
            try:
                invited_user = User.objects.get(email__iexact=email)
            except (User.DoesNotExist, User.MultipleObjectsReturned):
                pass
                
        # 3. Duplicate Checks
        # A. Already Member
        if invited_user:
            if trip.collaborators.filter(id=invited_user.id).exists() or trip.owner == invited_user:
                raise serializers.ValidationError({"identifier": "User is already a member."})
        elif email:
             if trip.collaborators.filter(email__iexact=email).exists() or trip.owner.email == email:
                raise serializers.ValidationError({"identifier": "User is already a member."})

        # B. Already Invited (Pending)
        if invited_user:
            if TripInvite.objects.filter(trip=trip, invited_user=invited_user, status='PENDING').exists():
                raise serializers.ValidationError({"identifier": "User already invited."})
        if email:
            if TripInvite.objects.filter(trip=trip, invited_email__iexact=email, status='PENDING').exists():
                 raise serializers.ValidationError({"identifier": "User already invited."})

        # 4. Prepare Output Data
        # We store resolved values in internal dictionary to be used in create()
        internal_data = {}
        if invited_user:
            internal_data['invited_user'] = invited_user
            # Ensure email is set even if resolving by username (use user.email)
            # Or if resolving by email (use provided email)
            internal_data['invited_email'] = email if email else invited_user.email
        else:
            internal_data['invited_email'] = email
            
        # Store in serializer context or specific data field for save
        self.context['internal_data'] = internal_data
        
        return data

    def create(self, validated_data):
        internal_data = self.context.get('internal_data', {})
        request = self.context.get('request')
        
        # Extract fields
        identifier = validated_data.pop('identifier', None)
        
        return TripInvite.objects.create(
            invited_by=request.user if request else None,
            **internal_data,
            **validated_data
        )



