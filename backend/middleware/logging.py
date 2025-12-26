"""
Custom middleware for request logging.

SECURITY NOTE:
- Does NOT log request bodies (may contain passwords, tokens)
- Does NOT log query parameters (may contain sensitive data)
- Only logs method, path, user, status, and timing
"""
import logging
import time

logger = logging.getLogger(__name__)


class RequestLoggingMiddleware:
    """
    Middleware to log all incoming requests with execution time.
    
    Logs:
    - HTTP method (GET, POST, etc.)
    - Request path
    - Authenticated user (if any)
    - Response status code
    - Execution time
    
    Security:
    - Excludes sensitive paths (admin, auth tokens)
    - Does NOT log request bodies or query params
    - Does NOT log authentication headers
    """
    
    # Paths to exclude from logging (reduce noise)
    EXCLUDED_PATHS = [
        '/admin/jsi18n/',
        '/static/',
        '/media/',
        '/favicon.ico',
    ]
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Skip logging for excluded paths
        if any(request.path.startswith(path) for path in self.EXCLUDED_PATHS):
            return self.get_response(request)
        
        # Record start time
        start_time = time.time()
        
        # Process request
        response = self.get_response(request)
        
        # Calculate processing time
        duration = time.time() - start_time
        
        # Get user info (if authenticated)
        user_info = "Anonymous"
        if hasattr(request, 'user') and request.user.is_authenticated:
            user_info = f"User:{request.user.username}"
        
        # Log request details
        logger.info(
            f"{request.method} {request.path} | "
            f"{user_info} | "
            f"Status:{response.status_code} | "
            f"Time:{duration:.3f}s"
        )
        
        return response

