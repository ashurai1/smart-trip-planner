from .models import Trip, TripInvite, ItineraryItem, Notification
from .serializers import (
    TripSerializer, 
    AddCollaboratorSerializer, 
    RemoveCollaboratorSerializer, 
    ItineraryItemSerializer, 
    ReorderItinerarySerializer,
    TripInviteSerializer,
    NotificationSerializer
)
from rest_framework.views import APIView
from rest_framework import viewsets, status, serializers
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from django.core.mail import send_mail
from django.conf import settings
from .permissions import IsOwner, IsOwnerOrCollaborator

class TripViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Trip management.
    """
    serializer_class = TripSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        return Trip.objects.filter(
            Q(owner=user) | Q(collaborators=user)
        ).select_related('owner').prefetch_related('collaborators', 'notification_states').distinct()

    def get_permissions(self):
        if self.action in ['retrieve']:
            permission_classes = [IsAuthenticated, IsOwnerOrCollaborator]
        elif self.action in ['update', 'partial_update', 'destroy', 'add_collaborator', 'remove_collaborator', 'invite']:
            # IMPORTANT: Ensure Owners can always access these actions
            permission_classes = [IsAuthenticated, IsOwner]
        else:
            permission_classes = [IsAuthenticated]
        
        return [permission() for permission in permission_classes]
    
    @action(detail=True, methods=['post'], url_path='invite')
    def invite(self, request, pk=None):
        """
        Send an invitation to join the trip (Email or Username).
        Unified robust implementation.
        """
        import logging
        logger = logging.getLogger(__name__)
        
        try:
            trip = self.get_object()
            
            # Use unified serializer
            serializer = TripInviteSerializer(
                data=request.data,
                context={'trip': trip, 'request': request}
            )
            serializer.is_valid(raise_exception=True)
            
            invite = serializer.save(trip=trip)
            logger.info(f"Invite created (ID: {invite.id}) for trip '{trip.title}'")
            
            # Email Dispatch (Best Effort)
            target_email = invite.invited_email
            if target_email:
                try:
                    invite_link = f"http://localhost:8000/api/invites/accept/{invite.token}/"
                    subject = "You're invited to join a trip"
                    user_text = f"User {request.user.username}"
                    trip_text = f"'{trip.title}'"
                    message = f"{user_text} has invited you to join the trip {trip_text}.\n\nClick the link below to join:\n{invite_link}"
                    
                    send_mail(
                        subject,
                        message,
                        settings.DEFAULT_FROM_EMAIL or 'noreply@smarttripplanner.com',
                        [target_email],
                        fail_silently=False,
                    )
                    logger.info(f"Invitation email sent to {target_email}")
                except Exception as e:
                    logger.error(f"Failed to send email to {target_email}: {str(e)}")
                    # Do not fail request
            
            return Response({
                'message': 'Invitation sent successfully', 
            }, status=status.HTTP_200_OK)

        except serializers.ValidationError as e:
            # Return 400/404 based on error content
            # If "User not found" -> 404
            # If "User already..." -> 400
            errors = e.detail
            error_msg = ""
            if isinstance(errors, dict):
                # Flatten
                for k, v in errors.items():
                    if isinstance(v, list): error_msg = v[0]
                    else: error_msg = str(v)
            else:
                error_msg = str(errors)
            
            status_code = status.HTTP_400_BAD_REQUEST
            if "not found" in str(error_msg).lower():
                status_code = status.HTTP_404_NOT_FOUND
            
            return Response({'detail': error_msg}, status=status_code)

        except Exception as e:
            logger.error(f"Invite API Error: {str(e)}")
            return Response({'detail': 'An error occurred while processing the invitation.'}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'], url_path='add-collaborator')
    def add_collaborator(self, request, pk=None):
        """
        Add a collaborator to the trip.
        """
        trip = self.get_object()
        serializer = AddCollaboratorSerializer(data=request.data, context={'trip': trip})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        trip.collaborators.add(user)
        trip_serializer = TripSerializer(trip, context={'request': request})
        return Response({'message': f'User {user.username} added as collaborator.', 'trip': trip_serializer.data})
    
    @action(detail=True, methods=['post'], url_path='remove-collaborator')
    def remove_collaborator(self, request, pk=None):
        """
        Remove a collaborator from the trip.
        """
        trip = self.get_object()
        serializer = RemoveCollaboratorSerializer(data=request.data, context={'trip': trip})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        trip.collaborators.remove(user)
        trip_serializer = TripSerializer(trip, context={'request': request})
        return Response({'message': f'User {user.username} removed from collaborators.', 'trip': trip_serializer.data})


class AcceptInviteView(APIView):
    """
    View to accept a trip invitation via token.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, token):
        invite = get_object_or_404(TripInvite, token=token)
        
        if invite.status != 'PENDING':
            return Response({'detail': 'Invitation is no longer valid.'}, status=status.HTTP_400_BAD_REQUEST)
            
        # Security Check: Ensure the accepting user matches the invited user or email
        if invite.invited_user:
            if request.user != invite.invited_user:
                return Response({'detail': 'This invitation was meant for a different user.'}, status=status.HTTP_403_FORBIDDEN)
        elif invite.invited_email:
            if request.user.email != invite.invited_email:
                 return Response({'detail': 'This invitation was sent to a different email address.'}, status=status.HTTP_403_FORBIDDEN)
             
        # Add to trip
        trip = invite.trip
        trip.collaborators.add(request.user)
        
        # Mark accepted
        invite.status = 'ACCEPTED'
        invite.save()
        
        return Response({
            'message': f'You have successfully joined {trip.title}.',
            'trip_id': trip.id
        })


from .services import increment_notification_count

class TripInviteViewSet(viewsets.GenericViewSet, viewsets.mixins.ListModelMixin):
    """
    ViewSet to list and manage received invitations.
    """
    serializer_class = TripInviteSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        # Fetch invites where the user is explicitly linked
        # OR where the email matches the user's email
        return TripInvite.objects.filter(
            Q(invited_user=user) | Q(invited_email__iexact=user.email),
            status='PENDING'
        ).select_related('trip', 'invited_by').order_by('-created_at')

    @action(detail=True, methods=['post'])
    def respond(self, request, pk=None):
        """
        Accept or Reject an invite.
        """
        invite = self.get_object()
        status_param = request.data.get('status')
        
        if status_param not in ['ACCEPTED', 'REJECTED']:
            return Response({'detail': 'Invalid status.'}, status=status.HTTP_400_BAD_REQUEST)
            
        if invite.status != 'PENDING':
             return Response({'detail': 'Invitation is no longer pending.'}, status=status.HTTP_400_BAD_REQUEST)

        # Update status
        invite.status = status_param
        invite.save()
        
        if status_param == 'ACCEPTED':
            invite.trip.collaborators.add(request.user)
            return Response({'message': f'You joined {invite.trip.title}.'})
        else:
            return Response({'message': 'Invitation rejected.'})

class InviteActionViewSet(viewsets.ViewSet):
    """
    ViewSet for handling Invite Actions (Accept/Decline) via Token.
    """
    permission_classes = [IsAuthenticated]

    def _get_invite(self, token):
        return get_object_or_404(TripInvite, token=token)

    @action(detail=False, methods=['post'])
    def accept(self, request, token=None):
        invite = self._get_invite(token)
        
        # Validation
        if invite.status != 'PENDING':
             return Response({'detail': 'Invitation is no longer pending.'}, status=status.HTTP_400_BAD_REQUEST)

        # Security Check
        if invite.invited_user and request.user != invite.invited_user:
             return Response({'detail': 'This invitation was meant for a different user.'}, status=status.HTTP_403_FORBIDDEN)
        if invite.invited_email and request.user.email.lower() != invite.invited_email.lower():
             return Response({'detail': 'This invitation email does not match your account.'}, status=status.HTTP_403_FORBIDDEN)

        # Perform Action
        invite.status = 'ACCEPTED'
        invite.save()
        invite.trip.collaborators.add(request.user)
        
        return Response({'status': 'ACCEPTED', 'message': f'You joined {invite.trip.title}.'})

    @action(detail=False, methods=['post'])
    def decline(self, request, token=None):
        invite = self._get_invite(token)
        
        if invite.status != 'PENDING':
             return Response({'detail': 'Invitation is no longer pending.'}, status=status.HTTP_400_BAD_REQUEST)
             
        # Security Check (Loose for decline, but safer to enforce)
        if invite.invited_user and request.user != invite.invited_user:
             return Response({'detail': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)
        if invite.invited_email and request.user.email.lower() != invite.invited_email.lower():
             return Response({'detail': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)

        invite.status = 'DECLINED'
        invite.save()
        
        return Response({'status': 'DECLINED', 'message': 'Invitation declined.'})

class ItineraryItemViewSet(viewsets.ModelViewSet):
    serializer_class = ItineraryItemSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrCollaborator]
    
    def get_queryset(self):
        trip_pk = self.kwargs.get('trip_pk')
        return ItineraryItem.objects.filter(trip_id=trip_pk).order_by('order')
    
    def get_trip(self):
        trip_pk = self.kwargs.get('trip_pk')
        try:
            trip = Trip.objects.get(pk=trip_pk)
        except Trip.DoesNotExist:
            return None
        if not trip.has_access(self.request.user):
            return None
        return trip
    
    def list(self, request, *args, **kwargs):
        trip = self.get_trip()
        if not trip:
            return Response({'detail': 'Trip not found or access denied.'}, status=status.HTTP_404_NOT_FOUND)
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def create(self, request, *args, **kwargs):
        trip = self.get_trip()
        if not trip:
            return Response({'detail': 'Trip not found or access denied.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = self.get_serializer(data=request.data, context={'request': request, 'trip': trip})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        increment_notification_count(trip, request.user, 'itinerary')
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def destroy(self, request, *args, **kwargs):
        try:
            instance = self.get_object()
            user = request.user
            trip = instance.trip
            if not (instance.created_by == user or trip.owner == user):
                 return Response({'detail': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)
            self.perform_destroy(instance)
            increment_notification_count(trip, request.user, 'itinerary')
            return Response(status=status.HTTP_204_NO_CONTENT)
        except ItineraryItem.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
        except Exception:
            return Response({'detail': 'Deletion failed.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @action(detail=False, methods=['post'], url_path='reorder')
    def reorder(self, request, trip_pk=None):
        trip = self.get_trip()
        if not trip:
             return Response({'detail': 'Trip not found.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = ReorderItinerarySerializer(data=request.data, context={'trip': trip})
        serializer.is_valid(raise_exception=True)
        updated_items = serializer.save()
        increment_notification_count(trip, request.user, 'itinerary')
        item_serializer = ItineraryItemSerializer(updated_items, many=True, context={'request': request})
        return Response({'message': 'Reordered successfully.', 'items': item_serializer.data})


class NotificationViewSet(viewsets.ViewSet):
    """
    ViewSet for managing User Notifications.
    """
    permission_classes = [IsAuthenticated]
    
    def list(self, request):
        user = request.user
        
        # 1. Invitation Count (Pending only, matched by email)
        invite_count = TripInvite.objects.filter(invited_email=user.email, status='PENDING').count()
        
        # 2. Trip Notifications
        states = TripNotificationState.objects.filter(user=user)
        trips_data = {}
        for s in states:
            trips_data[str(s.trip.id)] = {
                'chat': s.unread_chat_count,
                'poll': s.unread_poll_count,
                'itinerary': s.unread_itinerary_count
            }
            
        return Response({
            'invitations': invite_count,
            'trips': trips_data
        })
        
    @action(detail=False, methods=['get'])
    def history(self, request):
        user = request.user
        notifications = Notification.objects.filter(recipient=user)
        from rest_framework.pagination import PageNumberPagination
        paginator = PageNumberPagination()
        paginator.page_size = 20
        result_page = paginator.paginate_queryset(notifications, request)
        serializer = NotificationSerializer(result_page, many=True)
        return paginator.get_paginated_response(serializer.data)

    @action(detail=False, methods=['post'], url_path='mark-read')
    def mark_read(self, request):
        trip_id = request.data.get('trip_id')
        notif_type = request.data.get('type')
        if not trip_id or not notif_type:
            return Response({'detail': 'Missing parameters'}, status=status.HTTP_400_BAD_REQUEST)
        try:
             state = TripNotificationState.objects.get(user=request.user, trip_id=trip_id)
             if notif_type == 'chat': state.unread_chat_count = 0
             elif notif_type == 'poll': state.unread_poll_count = 0
             elif notif_type == 'itinerary': state.unread_itinerary_count = 0
             state.save()
             return Response({'status': 'ok'})
        except TripNotificationState.DoesNotExist:
             return Response({'status': 'ok'})




