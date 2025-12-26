"""
Admin configuration for polls app.
"""
from django.contrib import admin
from .models import Poll, PollOption, Vote


class PollOptionInline(admin.TabularInline):
    """Inline admin for poll options."""
    model = PollOption
    extra = 2
    fields = ['text']


@admin.register(Poll)
class PollAdmin(admin.ModelAdmin):
    """
    Admin interface for Poll model.
    """
    
    list_display = ['question', 'trip', 'created_by', 'created_at', 'get_vote_count']
    list_filter = ['created_at', 'trip']
    search_fields = ['question', 'trip__title', 'created_by__username']
    readonly_fields = ['id', 'created_at']
    inlines = [PollOptionInline]
    
    fieldsets = (
        ('Poll Information', {
            'fields': ('id', 'trip', 'question', 'created_by')
        }),
        ('Timestamps', {
            'fields': ('created_at',)
        }),
    )
    
    def get_vote_count(self, obj):
        """Display total number of votes."""
        return obj.votes.count()
    
    get_vote_count.short_description = 'Total Votes'


@admin.register(PollOption)
class PollOptionAdmin(admin.ModelAdmin):
    """
    Admin interface for PollOption model.
    """
    
    list_display = ['text', 'poll', 'get_vote_count']
    list_filter = ['poll']
    search_fields = ['text', 'poll__question']
    
    def get_vote_count(self, obj):
        """Display number of votes for this option."""
        return obj.votes.count()
    
    get_vote_count.short_description = 'Votes'


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    """
    Admin interface for Vote model.
    """
    
    list_display = ['user', 'poll', 'option', 'created_at']
    list_filter = ['created_at', 'poll']
    search_fields = ['user__username', 'poll__question']
    readonly_fields = ['id', 'created_at']
    
    fieldsets = (
        ('Vote Information', {
            'fields': ('id', 'poll', 'option', 'user')
        }),
        ('Timestamps', {
            'fields': ('created_at',)
        }),
    )
