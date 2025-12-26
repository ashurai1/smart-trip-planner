"""
Custom exception handler for DRF.

SECURITY NOTE:
- Does NOT expose stack traces to clients
- Provides consistent error response format
- Logs detailed errors server-side only
"""
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from rest_framework.exceptions import (
    ValidationError,
    PermissionDenied,
    NotAuthenticated,
    AuthenticationFailed,
    NotFound,
    MethodNotAllowed,
    Throttled
)
from django.core.exceptions import ObjectDoesNotExist
from django.http import Http404
import logging

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    """
    Custom exception handler for DRF.
    
    Returns consistent error format:
    {
        "error": true,
        "message": "Human-readable error message",
        "details": {...}  // Optional, only for validation errors
    }
    
    Security:
    - Never exposes stack traces
    - Logs detailed errors server-side
    - Returns clean messages to client
    """
    
    # Call DRF's default exception handler first
    response = exception_handler(exc, context)
    
    # If DRF handled it, format the response
    if response is not None:
        error_data = {
            "error": True,
            "message": get_error_message(exc, response.data)
        }
        
        # Add validation details if present
        if isinstance(exc, ValidationError) and isinstance(response.data, dict):
            error_data["details"] = response.data
        
        response.data = error_data
        
        # Log the error server-side
        log_exception(exc, context, response.status_code)
        
        return response
    
    # Handle Django exceptions not caught by DRF
    if isinstance(exc, (ObjectDoesNotExist, Http404)):
        error_data = {
            "error": True,
            "message": "The requested resource was not found."
        }
        response = Response(error_data, status=status.HTTP_404_NOT_FOUND)
        log_exception(exc, context, 404)
        return response
    
    # Handle unexpected exceptions
    logger.error(
        f"Unhandled exception: {type(exc).__name__}: {str(exc)}",
        exc_info=True,
        extra={
            'request_path': context.get('request').path if context.get('request') else None,
            'request_method': context.get('request').method if context.get('request') else None,
        }
    )
    
    # Return generic error (don't expose internal details)
    error_data = {
        "error": True,
        "message": "An unexpected error occurred. Please try again later."
    }
    return Response(error_data, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def get_error_message(exc, data):
    """
    Extract a clean, human-readable error message.
    """
    # Handle specific exception types
    if isinstance(exc, NotAuthenticated):
        return "Authentication credentials were not provided."
    
    if isinstance(exc, AuthenticationFailed):
        return "Invalid authentication credentials."
    
    if isinstance(exc, PermissionDenied):
        return "You do not have permission to perform this action."
    
    if isinstance(exc, NotFound):
        return "The requested resource was not found."
    
    if isinstance(exc, MethodNotAllowed):
        return f"Method '{exc.default_detail}' is not allowed for this endpoint."
    
    if isinstance(exc, Throttled):
        wait_time = exc.wait if hasattr(exc, 'wait') else 'some time'
        return f"Request limit exceeded. Please wait {wait_time} seconds before trying again."
    
    if isinstance(exc, ValidationError):
        # For validation errors, return a summary
        if isinstance(data, dict):
            # Get first error message
            for field, errors in data.items():
                if isinstance(errors, list) and errors:
                    if field == 'non_field_errors':
                        return str(errors[0])
                    return f"{field}: {errors[0]}"
        elif isinstance(data, list) and data:
            return str(data[0])
    
    # Default: use exception's detail or string representation
    if hasattr(exc, 'detail'):
        return str(exc.detail)
    
    return str(exc)


def log_exception(exc, context, status_code):
    """
    Log exception details server-side.
    """
    request = context.get('request')
    
    log_data = {
        'exception_type': type(exc).__name__,
        'status_code': status_code,
    }
    
    if request:
        log_data.update({
            'path': request.path,
            'method': request.method,
            'user': request.user.username if hasattr(request, 'user') and request.user.is_authenticated else 'Anonymous'
        })
    
    # Log at appropriate level
    if status_code >= 500:
        logger.error(f"Server Error: {exc}", extra=log_data)
    elif status_code >= 400:
        logger.warning(f"Client Error: {exc}", extra=log_data)

