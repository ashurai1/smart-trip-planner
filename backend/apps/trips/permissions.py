"""
Custom permissions for Trip management.
"""
from rest_framework import permissions


class IsOwner(permissions.BasePermission):
    """
    Permission class to check if user is the owner of the trip.
    
    Used for actions that only the owner can perform:
    - Update trip details
    - Delete trip
    - Add/remove collaborators
    """
    
    message = "You must be the owner of this trip to perform this action."
    
    def has_object_permission(self, request, view, obj):
        """
        Check if the requesting user is the owner of the trip.
        """
        return obj.owner == request.user


class IsOwnerOrCollaborator(permissions.BasePermission):
    """
    Permission class to check if user is owner or collaborator.
    
    Used for actions that owner and collaborators can perform:
    - View trip details
    - View trip-related data
    """
    
    message = "You must be the owner or a collaborator to access this trip."
    
    def has_object_permission(self, request, view, obj):
        """
        Check if the requesting user is owner or collaborator.
        """
        # Owner always has access
        # Handle objects that have 'owner' field (Trip)
        if hasattr(obj, 'owner') and obj.owner == request.user:
            return True
        # Handle objects that belong to a Trip (Poll, ItineraryItem)
        if hasattr(obj, 'trip') and obj.trip.owner == request.user:
            return True
        
        # Check if user is a collaborator
        # Handle objects that have 'collaborators' field (Trip)
        if hasattr(obj, 'collaborators') and obj.collaborators.filter(id=request.user.id).exists():
             return True
        
        # Handle objects that belong to a Trip (Poll, ItineraryItem)
        if hasattr(obj, 'trip') and obj.trip.collaborators.filter(id=request.user.id).exists():
             return True
             
        return False
