"""
PRODUCTION-READY FLUTTER API SERVICE
Copy-paste ready for Flutter + Dio + SimpleJWT
"""

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // PRODUCTION BACKEND URL
  static const String baseUrl = 'https://smart-trip-planner-dw13.onrender.com/api';
  
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
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
        // Attach JWT Token if available
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized
        if (error.response?.statusCode == 401) {
          print('ApiService: 🚨 401 Unauthorized - Clearing tokens');
          await logout();
        }
        print('ApiService: ❌ Error ${error.response?.statusCode}: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  /// Login - PRODUCTION READY
  /// 
  /// Handles all error cases:
  /// - 401: Invalid credentials
  /// - 400: Validation error
  /// - 500: Server error
  /// - Network errors
  /// 
  /// Never shows blank screen - always throws descriptive exception
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('ApiService: 🔑 Logging in as $username...');
      final response = await _dio.post('/auth/token/', data: {
        'username': username,
        'password': password,
      });

      print('ApiService: ✅ Login Success');
      await _storage.write(key: 'access_token', value: response.data['access']);
      await _storage.write(key: 'refresh_token', value: response.data['refresh']);
      
      return response.data;
    } on DioException catch (e) {
      print('ApiService: ❌ Login Error - Status: ${e.response?.statusCode}');
      print('ApiService: ❌ Response Data: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid username or password');
      } else if (e.response?.statusCode == 500) {
        // Server error - provide helpful message
        final errorMsg = e.response?.data?['error'] ?? 
                        e.response?.data?['detail'] ?? 
                        'Server error. Please try again later.';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 400) {
        // Bad request - validation error
        final errorMsg = e.response?.data?['error'] ?? 
                        e.response?.data?['detail'] ?? 
                        'Invalid request. Please check your input.';
        throw Exception(errorMsg);
      }
      
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      print('ApiService: ❌ Unexpected Error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> logout() async {
    print('ApiService: 👋 Logging out...');
    await _storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
}
