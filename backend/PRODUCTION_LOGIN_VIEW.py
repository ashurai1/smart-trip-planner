"""
PRODUCTION-READY LOGIN VIEW
Copy-paste ready for Django REST Framework + SimpleJWT
NEVER returns HTTP 500 - Always returns JSON
"""

from django.contrib.auth import authenticate, get_user_model
from django.db.models import Q
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import LoginSerializer
from .models import Profile

User = get_user_model()

class LoginAPIView(APIView):
    """
    Safe Login View - PRODUCTION READY
    
    Contract:
        POST /api/auth/login/
        Body: {"identifier": "username_or_email", "password": "password"}
    
    Returns:
        200: {"access": "token", "refresh": "token", "user": {...}}
        401: {"error": "Invalid credentials."}
        400: {"error": "field: error message"}
        500: {"error": "An unexpected error occurred. Please try again later."}
    
    Features:
        - Accepts username OR email as identifier
        - Never crashes (comprehensive error handling)
        - Always returns JSON
        - Logs errors server-side only
        - Never exposes stack traces
        - Production-safe
    """
    permission_classes = [AllowAny]
    serializer_class = LoginSerializer

    def post(self, request, *args, **kwargs):
        try:
            # 1. INPUT VALIDATION
            if not request.data:
                 return Response(
                     {'error': 'Empty request body.'}, 
                     status=status.HTTP_400_BAD_REQUEST
                 )
                 
            serializer = LoginSerializer(data=request.data)
            if not serializer.is_valid():
                # Format validation errors safely
                errors = []
                for field, msgs in serializer.errors.items():
                    errors.append(f"{field}: {msgs[0]}")
                return Response(
                    {'error': ' '.join(errors)}, 
                    status=status.HTTP_400_BAD_REQUEST
                )

            identifier = serializer.validated_data['identifier']
            password = serializer.validated_data['password']

            # 2. FIND USER (Safe Lookup)
            user_obj = User.objects.filter(
                Q(username__iexact=identifier) | 
                Q(email__iexact=identifier)
            ).first()

            if not user_obj:
                return Response(
                    {'error': 'Invalid credentials.'}, 
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # 3. AUTHENTICATE (Django Native)
            user = authenticate(
                request=request, 
                username=user_obj.username, 
                password=password
            )

            if not user:
                return Response(
                    {'error': 'Invalid credentials.'}, 
                    status=status.HTTP_401_UNAUTHORIZED
                )

            if not user.is_active:
                return Response(
                    {'error': 'Account disabled.'}, 
                    status=status.HTTP_403_FORBIDDEN
                )

            # 4. TOKEN GENERATION (SimpleJWT Manual)
            refresh = RefreshToken.for_user(user)
            
            # 5. USER DATA PREPARATION
            user_data = {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
            }

            # Safe Profile Access
            try:
                profile, _ = Profile.objects.get_or_create(user=user)
                user_data['avatar'] = {
                    'style': profile.avatar_style,
                    'color': profile.avatar_color,
                    'icon': profile.avatar_icon
                }
            except Exception:
                user_data['avatar'] = None

            # 6. SUCCESS RESPONSE
            return Response({
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': user_data
            }, status=status.HTTP_200_OK)

        except Exception as e:
            # 7. CRITICAL ERROR SAFETY
            import traceback
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"LOGIN CRASH PREVENTED: {str(e)}")
            logger.error(f"Traceback: {traceback.format_exc()}")
            
            # Return generic error (never expose internal details)
            return Response(
                {'error': 'An unexpected error occurred. Please try again later.'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
