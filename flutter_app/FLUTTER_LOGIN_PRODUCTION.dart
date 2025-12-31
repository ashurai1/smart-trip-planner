// ============================================================================
// PRODUCTION-READY FLUTTER LOGIN - RENDER DEPLOYMENT
// ============================================================================
// File: flutter_app/lib/services/api_service.dart
// Backend: https://smart-trip-planner-dw13.onrender.com
// Endpoint: POST /api/auth/login/
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // PRODUCTION BACKEND URL - NEVER USE LOCALHOST
  static const String baseUrl = 'https://smart-trip-planner-dw13.onrender.com/api';
  
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('🌐 ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onError: (error, handler) async {
        print('❌ Error ${error.response?.statusCode}: ${error.message}');
        if (error.response?.statusCode == 401) {
          await logout();
        }
        return handler.next(error);
      },
    ));
  }

  /// LOGIN - PRODUCTION READY
  /// 
  /// Backend Contract:
  ///   POST /api/auth/login/
  ///   Body: {"identifier": "username_or_email", "password": "password"}
  ///   
  /// Success Response (200):
  ///   {"access": "jwt_token", "refresh": "jwt_token", "user": {...}}
  ///   
  /// Error Responses:
  ///   400: {"error": "validation error message"}
  ///   401: {"error": "Invalid credentials."}
  ///   500: {"error": "Server error message"}
  ///
  /// Usage:
  ///   final result = await apiService.login('usera', 'password123');
  ///   // Tokens automatically stored in secure storage
  ///   // Navigate to dashboard on success
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      print('🔑 Attempting login: $identifier');
      
      final response = await _dio.post(
        '/auth/login/',  // CRITICAL: Use /auth/login/ NOT /auth/token/
        data: {
          'identifier': identifier,  // CRITICAL: Use 'identifier' NOT 'username'
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 600,
        ),
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        if (data.containsKey('access') && data.containsKey('refresh')) {
          await _storage.write(key: 'access_token', value: data['access']);
          await _storage.write(key: 'refresh_token', value: data['refresh']);
          print('✅ Login success - Tokens stored');
          return data;
        }
        
        throw Exception('Invalid response: missing tokens');
      }
      
      // Error handling
      final errorData = response.data;
      String errorMsg = 'Login failed';
      
      if (errorData is Map<String, dynamic>) {
        errorMsg = errorData['error']?.toString() ?? 
                   errorData['detail']?.toString() ?? 
                   errorMsg;
      }
      
      if (response.statusCode == 401) {
        throw Exception('Invalid username or password');
      } else if (response.statusCode == 400) {
        throw Exception(errorMsg);
      } else if (response.statusCode == 500) {
        throw Exception('Server error. Please try again.');
      }
      
      throw Exception(errorMsg);
      
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      
      // Timeout errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Check your internet.');
      }
      
      // Connection errors
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server.');
      }
      
      // HTTP errors
      if (e.response != null) {
        final errorData = e.response!.data;
        String errorMsg = 'Login failed';
        
        if (errorData is Map<String, dynamic>) {
          errorMsg = errorData['error']?.toString() ?? 
                     errorData['detail']?.toString() ?? 
                     errorMsg;
        }
        
        if (e.response!.statusCode == 401) {
          throw Exception('Invalid username or password');
        } else if (e.response!.statusCode == 400) {
          throw Exception(errorMsg);
        } else if (e.response!.statusCode == 500) {
          throw Exception('Server error. Please try again.');
        }
        
        throw Exception(errorMsg);
      }
      
      throw Exception('Network error. Please try again.');
    } catch (e) {
      print('❌ Unexpected: $e');
      if (e is Exception) rethrow;
      throw Exception('Unexpected error occurred.');
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    print('👋 Logged out');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
}

// ============================================================================
// USAGE EXAMPLE
// ============================================================================
/*

// 1. In main.dart or dependency injection
final apiService = ApiService();

// 2. In AuthBloc or AuthProvider
try {
  final result = await apiService.login('usera', 'password123');
  // Success: result contains {"access": "...", "refresh": "...", "user": {...}}
  // Tokens are automatically stored
  // Navigate to dashboard
  Navigator.pushReplacementNamed(context, '/trips');
} catch (e) {
  // Error: e.toString() contains user-friendly message
  // Show error toast or snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
  );
}

*/

// ============================================================================
// DEPLOYMENT NOTES
// ============================================================================
/*

1. NEVER use localhost in baseUrl
2. ALWAYS use HTTPS in production
3. Backend URL: https://smart-trip-planner-dw13.onrender.com/api
4. Login endpoint: POST /auth/login/
5. Request body: {"identifier": "...", "password": "..."}
6. Response: {"access": "...", "refresh": "...", "user": {...}}

COMMON ISSUES:

Issue: Infinite loader
Fix: Ensure try-catch in AuthBloc emits error state

Issue: Blank screen
Fix: Check navigation logic after login success

Issue: 500 error
Fix: Verify backend environment variables (SECRET_KEY, DATABASE_URL)

Issue: CORS error
Fix: Backend must have CORS_ALLOW_ALL_ORIGINS=True

*/
