"""
Poll models for Smart Trip Planner.
"""
from django.db import models
from django.contrib.auth import get_user_model
from apps.trips.models import Trip

User = get_user_model()


class Poll(models.Model):
    """
    Poll model for trip-related voting.
    
    Business Rules:
    - Each poll belongs to one trip
    - Only trip owner/collaborators can create polls
    - Created by a specific user
    """
    
    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        related_name='polls',
        help_text="Trip this poll belongs to"
    )
    
    question = models.CharField(
        max_length=500,
        help_text="Poll question"
    )
    
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='created_polls',
        help_text="User who created this poll"
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Timestamp when poll was created"
    )
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Poll'
        verbose_name_plural = 'Polls'
    
    def __str__(self):
        return f"{self.question} (Trip: {self.trip.title})"
    
    def has_user_voted(self, user):
        """Check if a user has already voted in this poll."""
        return self.votes.filter(user=user).exists()
    
    def get_results(self):
        """
        Get vote counts for each option.
        Returns a dict: {option_id: vote_count}
        """
        from django.db.models import Count
        results = self.options.annotate(
            vote_count=Count('votes')
        ).values('id', 'text', 'vote_count')
        return list(results)


class PollOption(models.Model):
    """
    Option for a poll.
    
    Business Rules:
    - Each option belongs to one poll
    - Minimum 2 options per poll (enforced at API level)
    """
    
    poll = models.ForeignKey(
        Poll,
        on_delete=models.CASCADE,
        related_name='options',
        help_text="Poll this option belongs to"
    )
    
    text = models.CharField(
        max_length=200,
        help_text="Option text"
    )
    
    class Meta:
        verbose_name = 'Poll Option'
        verbose_name_plural = 'Poll Options'
    
    def __str__(self):
        return f"{self.text} (Poll: {self.poll.question[:50]})"


class Vote(models.Model):
    """
    Vote on a poll option.
    
    Business Rules (CRITICAL):
    - Each user can vote ONLY ONCE per poll
    - Enforced at database level with unique_together constraint
    - User cannot change vote after submitting
    """
    
    poll = models.ForeignKey(
        Poll,
        on_delete=models.CASCADE,
        related_name='votes',
        help_text="Poll being voted on"
    )
    
    option = models.ForeignKey(
        PollOption,
        on_delete=models.CASCADE,
        related_name='votes',
        help_text="Selected option"
    )
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='poll_votes',
        help_text="User who voted"
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Timestamp when vote was cast"
    )
    
    class Meta:
        verbose_name = 'Vote'
        verbose_name_plural = 'Votes'
        # CRITICAL: Ensure one vote per user per poll at database level
        unique_together = ['poll', 'user']
        indexes = [
            models.Index(fields=['poll', 'user']),
        ]
    
    def __str__(self):
        return f"{self.user.username} voted on {self.poll.question[:50]}"
