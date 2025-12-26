"""
Views for Chat management.

DESIGN NOTE:
This is a simplified REST-based chat implementation.
- Messages are fetched via GET requests (polling)
- No WebSockets or real-time push
- Suitable for evaluation and prototyping
- Real-time features are future scope
"""
from rest_framework import viewsets, status, permissions
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.pagination import PageNumberPagination
from apps.trips.models import Trip
from apps.trips.permissions import IsOwnerOrCollaborator
from apps.trips.services import increment_notification_count
from .models import ChatMessage
from .serializers import ChatMessageSerializer


class ChatMessagePagination(PageNumberPagination):
    """
    Pagination for chat messages.
    Returns messages in chronological order.
    """
    page_size = 50
    page_size_query_param = 'page_size'
    max_page_size = 100


class ChatMessageViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Chat Message management.
    
    Nested under trips: /api/trips/{trip_pk}/chat/
    
    IMPORTANT: This is a REST-based chat (not real-time).
    - Messages are fetched via GET requests
    - Clients should poll for new messages
    - WebSocket-based real-time chat is future enhancement
    
    Provides:
    - list: Get all messages for a trip (paginated, chronological)
    - create: Send a new message
    
    Access: Owner or Collaborator of the trip
    """
    
    serializer_class = ChatMessageSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrCollaborator]
    pagination_class = ChatMessagePagination
    
    def get_queryset(self):
        """
        Return messages for the specified trip.
        Ordered by creation time (oldest first).
        """
        trip = self.get_trip()
        if not trip:
             return ChatMessage.objects.none()
             
        if not trip.has_access(self.request.user):
            return ChatMessage.objects.none()
            
        return ChatMessage.objects.filter(trip=trip).select_related(
            'sender', 'trip'
        ).order_by('created_at')
    
    def get_trip(self):
        """
        Get the trip object from URL parameter.
        """
        trip_pk = self.kwargs.get('trip_pk')
        try:
            return Trip.objects.get(pk=trip_pk)
        except Trip.DoesNotExist:
            return None
    
    def list(self, request, *args, **kwargs):
        """
        List all messages for the trip.
        
        Note: This is a polling-based approach.
        Clients should periodically call this endpoint to fetch new messages.
        """
        trip = self.get_trip()
        if not trip:
            return Response(
                {'detail': 'Trip not found or access denied.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check permission explicitly again if needed, though get_queryset handles it
        if not trip.has_access(request.user):
             return Response(
                {'detail': 'Access denied.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        queryset = self.get_queryset()
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def create(self, request, *args, **kwargs):
        """
        Send a new message to the trip chat.
        Auto-assigns trip and sender.
        """
        trip = self.get_trip()
        if not trip:
            return Response(
                {'detail': 'Trip not found or access denied.'},
                status=status.HTTP_404_NOT_FOUND
            )
            
        if not trip.has_access(request.user):
             return Response(
                {'detail': 'Access denied.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Pass trip in context for serializer
        serializer = self.get_serializer(
            data=request.data,
            context={'request': request, 'trip': trip}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        
        # Increment notifications
        increment_notification_count(trip, request.user, 'chat')
        
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED
        )
