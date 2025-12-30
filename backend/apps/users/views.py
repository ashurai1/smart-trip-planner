import random
from django.utils import timezone
from django.contrib.auth import authenticate, get_user_model
from django.db.models import Q
from rest_framework import viewsets, status, generics
from rest_framework.views import APIView
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Profile
from .serializers import (
    ProfileSerializer, 
    OTPRequestSerializer, 
    UpdateProfileSerializer,
    RegisterSerializer,
    LoginSerializer
)

User = get_user_model()

class LoginAPIView(APIView):
    """
    Safe Login View.
    Contract:
    POST /api/auth/login/
    Body: {"identifier": "u", "password": "p"}
    """
    permission_classes = [AllowAny]
    serializer_class = LoginSerializer

    def post(self, request, *args, **kwargs):
        try:
            # 1. INPUT VALIDATION
            if not request.data:
                 return Response({'error': 'Empty request body.'}, status=status.HTTP_400_BAD_REQUEST)
                 
            serializer = LoginSerializer(data=request.data)
            if not serializer.is_valid():
                # Format validation errors safely
                errors = []
                for field, msgs in serializer.errors.items():
                    errors.append(f"{field}: {msgs[0]}")
                return Response({'error': ' '.join(errors)}, status=status.HTTP_400_BAD_REQUEST)

            identifier = serializer.validated_data['identifier']
            password = serializer.validated_data['password']

            # 2. FIND USER (Safe Lookup)
            user_obj = User.objects.filter(
                Q(username__iexact=identifier) | 
                Q(email__iexact=identifier)
            ).first()

            if not user_obj:
                # Security: Consistent timing/message could be improved, but requirement is 401 JSON
                return Response(
                    {'error': 'Invalid credentials.'}, 
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # 3. AUTHENTICATE (Django Native)
            # We explicitly pass the *username* of the found user to authenticate
            # This ensures compatibility with ModelBackend which expects 'username'
            user = authenticate(request=request, username=user_obj.username, password=password)

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
            # Log the error with full traceback
            import traceback
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"LOGIN CRASH PREVENTED: {str(e)}")
            logger.error(f"Traceback: {traceback.format_exc()}")
            
            # Return generic error (never expose internal details)
            # Return specific error for debugging
            return Response(
                {'error': f'An unexpected error occurred: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ProfileViewSet(viewsets.GenericViewSet):
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        profile, created = Profile.objects.get_or_create(user=self.request.user)
        return profile
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        profile = self.get_object()
        serializer = ProfileSerializer(profile)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'], url_path='generate-otp')
    def generate_otp(self, request):
        profile = self.get_object()
        otp = str(random.randint(100000, 999999))
        profile.otp = otp
        profile.otp_created_at = timezone.now()
        profile.save()
        print(f"OTP for {request.user.username}: {otp}")
        return Response({'message': 'OTP sent.'})
    
    @action(detail=False, methods=['put', 'patch'], url_path='update')
    def update_profile(self, request):
        profile = self.get_object()
        serializer = UpdateProfileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        new_phone = serializer.validated_data.get('phone_number')
        if new_phone and new_phone != profile.phone_number:
            otp = serializer.validated_data.get('otp')
            if not otp or otp != profile.otp:
                 return Response({'otp': 'Invalid OTP.'}, status=status.HTTP_400_BAD_REQUEST)
            profile.phone_number = new_phone
            profile.otp = None
        
        user = request.user
        if 'first_name' in serializer.validated_data:
            user.first_name = serializer.validated_data['first_name']
        if 'last_name' in serializer.validated_data:
            user.last_name = serializer.validated_data['last_name']
        user.save()
        
        if 'bio' in serializer.validated_data:
            profile.bio = serializer.validated_data['bio']
            
        if 'avatar' in serializer.validated_data and serializer.validated_data['avatar']:
            av = serializer.validated_data['avatar']
            profile.avatar_style = av.get('style', profile.avatar_style)
            profile.avatar_color = av.get('color', profile.avatar_color)
            profile.avatar_icon = av.get('icon', profile.avatar_icon)
            
        profile.save()
        return Response(ProfileSerializer(profile).data)

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer
