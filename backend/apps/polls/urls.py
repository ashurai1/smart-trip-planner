"""
URL configuration for polls app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PollViewSet, VoteView

app_name = 'polls'

# Nested routes for polls under trips
# Pattern: /api/trips/{trip_pk}/polls/
poll_list = PollViewSet.as_view({
    'get': 'list',
    'post': 'create'
})

urlpatterns = [
    # Poll endpoints (nested under trips)
    path('trips/<uuid:trip_pk>/polls/', poll_list, name='poll-list'),
    path('trips/<uuid:trip_pk>/polls/<int:pk>/', PollViewSet.as_view({'delete': 'destroy'}), name='poll-detail'),
    
    # Vote endpoint (standalone)
    path('polls/<int:poll_id>/vote/', VoteView.as_view(), name='poll-vote'),
]
