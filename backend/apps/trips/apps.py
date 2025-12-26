"""
App configuration for trips.
"""
from django.apps import AppConfig


class TripsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.trips'
    
    def ready(self):
        """Import signals when app is ready."""
        import apps.trips.signals  # noqa
    verbose_name = 'Trips'
