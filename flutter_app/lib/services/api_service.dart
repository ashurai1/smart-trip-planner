import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

/// Centralized API Service
class ApiService {
  // CONFIGURATION
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://smart-trip-planner-dw13.onrender.com/api';
    }
    // LOCAL DEV URL
    // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS Simulator
    return 'http://127.0.0.1:8000/api'; 
  }
  
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
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

  // ========== AUTHENTICATION ==========

  /// Login using custom /auth/login/ endpoint
  /// Backend expects: {"identifier": "username_or_email", "password": "password"}
  /// Returns: {"access": "token", "refresh": "token", "user": {...}}
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      print('ApiService: 🔑 Logging in as $identifier...');
      
      // CRITICAL: Use /auth/login/ endpoint with identifier field
      final response = await _dio.post(
        '/auth/login/',
        data: {
          'identifier': identifier,  // Backend expects 'identifier', not 'username'
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 600, // Don't throw on any status
        ),
      );

      print('ApiService: 📡 Response Status: ${response.statusCode}');
      print('ApiService: 📦 Response Data: ${response.data}');

      // Handle success (200)
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Store tokens
        if (data.containsKey('access') && data.containsKey('refresh')) {
          await _storage.write(key: 'access_token', value: data['access']);
          await _storage.write(key: 'refresh_token', value: data['refresh']);
          print('ApiService: ✅ Login Success - Tokens stored');
          return data;
        } else {
          throw Exception('Invalid response format: missing tokens');
        }
      }
      
      // Handle errors (400, 401, 500, etc.)
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
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception(errorMsg);
      }
      
    } on DioException catch (e) {
      print('ApiService: ❌ DioException - Type: ${e.type}');
      print('ApiService: ❌ Status: ${e.response?.statusCode}');
      print('ApiService: ❌ Data: ${e.response?.data}');
      
      // Network errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your internet.');
      }
      
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server. Please try again.');
      }
      
      // Response errors
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
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception(errorMsg);
        }
      }
      
      throw Exception('Network error. Please try again.');
    } catch (e) {
      print('ApiService: ❌ Unexpected Error: $e');
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      print('ApiService: 📝 Registering $username...');
      await _dio.post('/users/register/', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      print('ApiService: ✅ Registration Success');
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    print('ApiService: 👋 Logging out...');
    await _storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  // ========== USERS / PROFILE ==========

  Future<UserProfile> getProfile() async {
    final response = await _dio.get('/users/profile/me/');
    return UserProfile.fromJson(response.data);
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    String? otp,
    String? phoneNumber,
    Map<String, dynamic>? avatar,
  }) async {
    final Map<String, dynamic> data = {};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (bio != null) data['bio'] = bio;
    if (otp != null) data['otp'] = otp;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (avatar != null) data['avatar'] = avatar;

    if (data.isNotEmpty) {
      await _dio.patch('/users/profile/update/', data: data);
    }
  }

  Future<void> requestUpdateOtp() async {
    await _dio.post('/users/profile/generate-otp/');
  }

  // ========== TRIPS ==========

  Future<List<dynamic>> getTrips() async {
    final response = await _dio.get('/trips/');
    if (response.data is Map && response.data.containsKey('results')) {
      return response.data['results'];
    }
    return response.data as List;
  }

  Future<Map<String, dynamic>> getTripDetail(String tripId) async {
    final response = await _dio.get('/trips/$tripId/');
    return response.data;
  }

  Future<void> createTrip(String title, String description) async {
    await _dio.post('/trips/', data: {
      'title': title,
      'description': description,
    });
  }

  Future<void> deleteTrip(String tripId) async {
    await _dio.delete('/trips/$tripId/');
  }

  Future<void> inviteUser(String tripId, String identifier) async {
    await _dio.post('/trips/$tripId/invite/', data: {
      'identifier': identifier,
    });
  }

  // ========== INVITATIONS ==========

  Future<List<dynamic>> getInvitations() async {
    final response = await _dio.get('/trips/invitations/');
    if (response.data is Map && response.data.containsKey('results')) {
      return response.data['results'];
    }
    return response.data as List;
  }

  Future<void> acceptInvite(String token) async {
    await _dio.post('/trips/invites/$token/accept/');
  }

  Future<void> declineInvite(String token) async {
    await _dio.post('/trips/invites/$token/decline/');
  }

  // ========== ITINERARY ==========

  Future<List<dynamic>> getItineraryItems(String tripId) async {
    final response = await _dio.get('/trips/$tripId/itinerary/');
    return response.data;
  }

  Future<void> addItineraryItem(String tripId, String title, String description) async {
    await _dio.post('/trips/$tripId/itinerary/', data: {
      'title': title,
      'description': description,
    });
  }

  Future<void> deleteItineraryItem(String tripId, int itemId) async {
    await _dio.delete('/trips/$tripId/itinerary/$itemId/');
  }

  Future<void> reorderItinerary(String tripId, List<int> itemIds) async {
    await _dio.post('/trips/$tripId/itinerary/reorder/', data: {
      'item_ids': itemIds,
    });
  }

  // ========== POLLS ==========

  Future<List<dynamic>> getPolls(String tripId) async {
    final response = await _dio.get('/polls/trips/$tripId/polls/');
    return response.data;
  }

  Future<void> createPoll(String tripId, String question, List<String> options) async {
    await _dio.post('/polls/trips/$tripId/polls/', data: {
      'question': question,
      'options': options.map((e) => {'text': e}).toList(),
    });
  }

  Future<void> deletePoll(String tripId, int pollId) async {
    await _dio.delete('/polls/trips/$tripId/polls/$pollId/');
  }

  Future<void> vote(int pollId, int optionId) async {
    await _dio.post('/polls/polls/$pollId/vote/', data: {
      'option_id': optionId,
    });
  }

  // ========== CHAT ==========

  Future<List<dynamic>> getChatMessages(String tripId) async {
    final response = await _dio.get('/chat/trips/$tripId/chat/');
    if (response.data is Map && response.data.containsKey('results')) {
      return response.data['results'];
    }
    return response.data as List;
  }

  Future<void> sendMessage(String tripId, String message) async {
    await _dio.post('/chat/trips/$tripId/chat/', data: {
      'message': message,
    });
  }

  Future<void> deleteMessage(String tripId, int messageId) async {
    await _dio.delete('/chat/trips/$tripId/chat/$messageId/');
  }

  // ========== NOTIFICATIONS ==========

  Future<Map<String, dynamic>> getNotifications() async {
    final response = await _dio.get('/trips/notifications/');
    return response.data;
  }

  Future<void> markNotificationAsRead(String tripId, String type) async {
    await _dio.post('/trips/notifications/mark-read/', data: {
      'trip_id': tripId,
      'type': type,
    });
  }
}
