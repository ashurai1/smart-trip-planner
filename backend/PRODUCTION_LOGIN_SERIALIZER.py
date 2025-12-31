"""
PRODUCTION-READY LOGIN SERIALIZER
Copy-paste ready for Django REST Framework + SimpleJWT
"""

from rest_framework import serializers
from django.contrib.auth import get_user_model

User = get_user_model()

class LoginSerializer(serializers.Serializer):
    """
    Login serializer accepting identifier (username/email) and password.
    
    Usage:
        POST /api/auth/login/
        Body: {"identifier": "username_or_email", "password": "password"}
    
    Returns:
        200: {"access": "token", "refresh": "token", "user": {...}}
        401: {"error": "Invalid credentials."}
        400: {"error": "field: error message"}
    """
    identifier = serializers.CharField(required=True, help_text="Username or email")
    password = serializers.CharField(required=True, write_only=True, help_text="User password")
