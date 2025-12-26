"""
Views for Poll management.
"""
from rest_framework import viewsets, status, views
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from apps.trips.models import Trip
from apps.trips.services import increment_notification_count
from apps.trips.permissions import IsOwnerOrCollaborator
from .models import Poll, Vote
from .serializers import PollSerializer, VoteSerializer


class PollViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Poll management.
    """
    
    serializer_class = PollSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrCollaborator]
    
    def get_queryset(self):
        trip_pk = self.kwargs.get('trip_pk')
        return Poll.objects.filter(trip_id=trip_pk).prefetch_related(
            'options', 'votes', 'created_by'
        )
    
    def get_trip(self):
        trip_pk = self.kwargs.get('trip_pk')
        try:
            trip = Trip.objects.get(pk=trip_pk)
        except Trip.DoesNotExist:
            return None
        
        # Check if user has access to this trip
        if not trip.has_access(self.request.user):
            return None
        
        return trip
    
    def list(self, request, *args, **kwargs):
        trip = self.get_trip()
        if not trip:
            return Response(
                {'detail': 'Trip not found or access denied.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def create(self, request, *args, **kwargs):
        trip = self.get_trip()
        if not trip:
            return Response(
                {'detail': 'Trip not found or access denied.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Pass trip in context for serializer
        serializer = self.get_serializer(
            data=request.data,
            context={'request': request, 'trip': trip}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        
        # Increment Notification
        increment_notification_count(trip, request.user, 'poll')
        
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED
        )

    def destroy(self, request, *args, **kwargs):
        try:
            instance = self.get_object()
            user = request.user
            
            # Check permissions: Creator OR Owner
            is_creator = instance.created_by == user
            is_trip_owner = instance.trip.owner == user
            
            if not (is_creator or is_trip_owner):
                 return Response(
                     {'detail': 'Only the creator or trip owner can delete this poll.'},
                     status=status.HTTP_403_FORBIDDEN
                 )
            
            self.perform_destroy(instance)
            return Response(status=status.HTTP_204_NO_CONTENT)

        except Poll.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            print(f"Delete Poll Error: {e}")
            return Response(
                {'detail': 'Deletion failed.'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class VoteView(views.APIView):
    """
    View for casting votes on polls.
    """
    
    permission_classes = [IsAuthenticated]
    
    def post(self, request, poll_id):
        # Get the poll
        try:
            poll = Poll.objects.select_related('trip').get(id=poll_id)
        except Poll.DoesNotExist:
            return Response(
                {'detail': 'Poll not found.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if user has access to the trip
        if not poll.trip.has_access(request.user):
            return Response(
                {'detail': 'You do not have access to this poll.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Validate and create vote
        serializer = VoteSerializer(
            data=request.data,
            context={'request': request, 'poll': poll}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        
        # Increment Notification (Poll type covers updates too)
        increment_notification_count(poll.trip, request.user, 'poll')
        
        # Return updated poll with results
        poll_serializer = PollSerializer(poll, context={'request': request})
        
        return Response(
            {
                'message': 'Vote recorded successfully.',
                'poll': poll_serializer.data
            },
            status=status.HTTP_200_OK
        )
