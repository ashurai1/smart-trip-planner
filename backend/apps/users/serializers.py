from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Profile

User = get_user_model()

class LoginSerializer(serializers.Serializer):
    """
    Login serializer accepting identifier (username/email) and password.
    """
    identifier = serializers.CharField(required=True)
    password = serializers.CharField(required=True)

class ProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    avatar = serializers.SerializerMethodField()
    
    class Meta:
        model = Profile
        fields = ['user_id', 'username', 'email', 'first_name', 'last_name', 'bio', 'phone_number', 'avatar']
        read_only_fields = ['user_id', 'username', 'email', 'first_name', 'last_name']

    def get_avatar(self, obj):
        return {
            'style': obj.avatar_style,
            'color': obj.avatar_color,
            'icon': obj.avatar_icon
        }

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'first_name', 'last_name']

    def validate_username(self, value):
        username = value.lower()
        if User.objects.filter(username__iexact=username).exists():
             raise serializers.ValidationError("Username already taken.")
        return username

    def create(self, validated_data):
        username = validated_data['username'].lower()
        user = User.objects.create_user(
            username=username,
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        return user

class OTPRequestSerializer(serializers.Serializer):
    pass 

class UpdateProfileSerializer(serializers.Serializer):
    first_name = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    last_name = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    bio = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    phone_number = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    otp = serializers.CharField(required=False, min_length=6, max_length=6, allow_blank=True, allow_null=True)
    avatar = serializers.DictField(required=False, allow_null=True)

class UserSerializer(serializers.ModelSerializer):
    avatar = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'avatar']
        read_only_fields = ['id', 'username', 'first_name', 'last_name']

    def get_avatar(self, obj):
        try:
            return {
                'style': obj.profile.avatar_style,
                'color': obj.profile.avatar_color,
                'icon': obj.profile.avatar_icon
            }
        except Profile.DoesNotExist:
             return {
                'style': 'circle',
                'color': 'blue',
                'icon': 'person'
             }
