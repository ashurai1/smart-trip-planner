"""
Admin configuration for chat app.
"""
from django.contrib import admin
from .models import ChatMessage


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    """
    Admin interface for ChatMessage model.
    """
    
    list_display = ['get_message_preview', 'sender', 'trip', 'created_at']
    list_filter = ['created_at', 'trip', 'sender']
    search_fields = ['message', 'sender__username', 'trip__title']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Message Information', {
            'fields': ('id', 'trip', 'sender', 'message')
        }),
        ('Timestamps', {
            'fields': ('created_at',)
        }),
    )
    
    def get_message_preview(self, obj):
        """Display first 100 characters of message."""
        return obj.message[:100] + '...' if len(obj.message) > 100 else obj.message
    
    get_message_preview.short_description = 'Message'
