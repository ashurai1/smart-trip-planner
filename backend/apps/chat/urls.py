"""
URL configuration for chat app.
"""
from django.urls import path
from .views import ChatMessageViewSet

app_name = 'chat'

# Nested routes for chat under trips
# Pattern: /api/trips/{trip_pk}/chat/
chat_list = ChatMessageViewSet.as_view({
    'get': 'list',
    'post': 'create'
})

urlpatterns = [
    # Chat endpoints (nested under trips)
    path('trips/<uuid:trip_pk>/chat/', chat_list, name='chat-list'),
]
