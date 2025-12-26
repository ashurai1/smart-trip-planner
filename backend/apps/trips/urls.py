"""
URL configuration for trips app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TripViewSet, ItineraryItemViewSet, NotificationViewSet, AcceptInviteView, TripInviteViewSet, InviteActionViewSet

app_name = 'trips'

# Create router and register viewsets
router = DefaultRouter()
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'invitations', TripInviteViewSet, basename='trip-invite')
router.register(r'', TripViewSet, basename='trip')

# Nested routes for itinerary items
# Pattern: /api/trips/{trip_pk}/itinerary/
itinerary_list = ItineraryItemViewSet.as_view({
    'get': 'list',
    'post': 'create'
})

itinerary_reorder = ItineraryItemViewSet.as_view({
    'post': 'reorder'
})

urlpatterns = [
    # New Invite Actions (Token Based)
    path('invites/<uuid:token>/accept/', InviteActionViewSet.as_view({'post': 'accept'}), name='invite-accept-token'),
    path('invites/<uuid:token>/decline/', InviteActionViewSet.as_view({'post': 'decline'}), name='invite-decline-token'),

    path('invites/accept/<uuid:token>/', AcceptInviteView.as_view(), name='accept-invite'),
    path('', include(router.urls)),
    
    # Itinerary endpoints
    path('<uuid:trip_pk>/itinerary/', itinerary_list, name='itinerary-list'),
    path('<uuid:trip_pk>/itinerary/reorder/', itinerary_reorder, name='itinerary-reorder'),
    path('<uuid:trip_pk>/itinerary/<int:pk>/', ItineraryItemViewSet.as_view({'delete': 'destroy'}), name='itinerary-detail'),
    
    # AI Guide

]

