import random
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Profile
from django.contrib.auth import get_user_model
from .serializers import ProfileSerializer, OTPRequestSerializer, UpdateProfileSerializer

User = get_user_model()

class ProfileViewSet(viewsets.GenericViewSet):
    """
    ViewSet for User Profile management.
    """
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        profile, created = Profile.objects.get_or_create(user=self.request.user)
        return profile
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        """
        Get current user profile.
        """
        profile = self.get_object()
        serializer = ProfileSerializer(profile)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'], url_path='generate-otp')
    def generate_otp(self, request):
        """
        Generate and send (mock) OTP for profile update.
        """
        profile = self.get_object()
        
        # Generate 6-digit OTP
        otp = str(random.randint(100000, 999999))
        profile.otp = otp
        profile.otp_created_at = timezone.now()
        profile.save()
        
        # Mock sending (Print to console)
        print(f"==========================================")
        print(f" OTP for {request.user.username}: {otp}")
        print(f"==========================================")
        
        return Response({'message': 'OTP sent to your registered contact.'})
    
    @action(detail=False, methods=['put', 'patch'], url_path='update')
    def update_profile(self, request):
        """
        Update profile. OTP required ONLY for phone number updates.
        """
        profile = self.get_object()
        serializer = UpdateProfileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Check if phone number is being updated
        new_phone = serializer.validated_data.get('phone_number')
        phone_update_requested = new_phone and new_phone != profile.phone_number

        if phone_update_requested:
            # OTP Validation Required
            otp = serializer.validated_data.get('otp')
            if not otp:
                 return Response({'otp': 'OTP required to update phone number.'}, status=status.HTTP_400_BAD_REQUEST)
            if profile.otp != otp:
                 return Response({'otp': 'Invalid OTP.'}, status=status.HTTP_400_BAD_REQUEST)
            # Check expiration (5 mins)
            if (timezone.now() - profile.otp_created_at).total_seconds() > 300:
                 return Response({'otp': 'OTP expired.'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Clear OTP after successful use
            profile.otp = None
            profile.phone_number = new_phone
        
        # Update User Fields (No OTP needed)
        user = request.user
        if 'first_name' in serializer.validated_data:
            user.first_name = serializer.validated_data['first_name']
        if 'last_name' in serializer.validated_data:
            user.last_name = serializer.validated_data['last_name']
        user.save()
        
        # Update Other Profile Fields (No OTP needed)
        if 'bio' in serializer.validated_data:
            profile.bio = serializer.validated_data['bio']
            
        if 'avatar' in serializer.validated_data:
            avatar_data = serializer.validated_data['avatar']
            if 'style' in avatar_data:
                profile.avatar_style = avatar_data['style']
            if 'color' in avatar_data:
                profile.avatar_color = avatar_data['color']
            if 'icon' in avatar_data:
                profile.avatar_icon = avatar_data['icon']
            
            
        profile.save()
        
        return Response(ProfileSerializer(profile).data)

from rest_framework import generics
from rest_framework.permissions import AllowAny
from .serializers import RegisterSerializer

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer

from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework.exceptions import AuthenticationFailed

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        username = attrs.get('username')
        
        # Check if user exists first
        if username and not User.objects.filter(username__iexact=username).exists():
            raise AuthenticationFailed('Username not found', code='user_not_found')
            
        try:
            return super().validate(attrs)
        except AuthenticationFailed:
            # If super() fails but user exists, it must be password
            raise AuthenticationFailed('Incorrect password', code='bad_password')

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer
