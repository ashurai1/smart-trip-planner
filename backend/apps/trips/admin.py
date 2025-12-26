"""
Admin configuration for trips app.
"""
from django.contrib import admin
from .models import Trip, ItineraryItem, TripInvite


@admin.register(TripInvite)
class TripInviteAdmin(admin.ModelAdmin):
    list_display = ['trip', 'invited_email', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['invited_email', 'trip__title']
    readonly_fields = ['id', 'token', 'created_at']


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    """
    Admin interface for Trip model.
    """
    
    list_display = ['title', 'owner', 'created_at', 'get_collaborators_count']
    list_filter = ['created_at', 'owner']
    search_fields = ['title', 'description', 'owner__username']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('id', 'title', 'description')
        }),
        ('Ownership', {
            'fields': ('owner', 'collaborators')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
    
    filter_horizontal = ['collaborators']
    
    def get_collaborators_count(self, obj):
        """Display number of collaborators."""
        return obj.collaborators.count()
    
    get_collaborators_count.short_description = 'Collaborators'


@admin.register(ItineraryItem)
class ItineraryItemAdmin(admin.ModelAdmin):
    """
    Admin interface for ItineraryItem model.
    """
    
    list_display = ['title', 'trip', 'order', 'created_at']
    list_filter = ['trip', 'created_at']
    search_fields = ['title', 'description', 'trip__title']
    readonly_fields = ['id', 'created_at', 'updated_at']
    ordering = ['trip', 'order']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('id', 'trip', 'title', 'description')
        }),
        ('Ordering', {
            'fields': ('order',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )

