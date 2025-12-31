"""
URL configuration for Smart Trip Planner project.
"""
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularSwaggerView,
    SpectacularRedocView,
)
from rest_framework_simplejwt.views import (
    TokenRefreshView,
    TokenVerifyView,
    TokenObtainPairView,
)
from apps.users.views import LoginAPIView

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),
    
    # API Schema & Documentation
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
    
    # JWT Authentication - Standard Token Endpoint
    path('api/auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    
    # JWT Authentication - Custom Login (Alternative)
    path('api/auth/login/', LoginAPIView.as_view(), name='auth_login'), 
    
    # Standard SimpleJWT Views
    path('api/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    
    # Health Check (Root)
    path('', lambda request: JsonResponse({'status': 'healthy', 'message': 'Smart Trip Planner API is running'}), name='health_check'),

    # App URLs
    path('api/users/', include('apps.users.urls')),
    path('api/trips/', include('apps.trips.urls')),
    path('api/polls/', include('apps.polls.urls')),
    path('api/chat/', include('apps.chat.urls')),
]
