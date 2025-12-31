// ============================================================================
// FLUTTER LOGIN FLOW - COMPLETE WORKING IMPLEMENTATION
// ============================================================================
// This file documents the complete, tested login flow
// ============================================================================

// FILE: flutter_app/lib/blocs/auth/auth_bloc.dart
// ============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';

// ========== EVENTS ==========

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  LoginRequested(this.username, this.password);

  @override
  List<Object?> get props => [username, password];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

// ========== STATES ==========

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String token;

  Authenticated(this.token);

  @override
  List<Object?> get props => [token];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// ========== BLOC ==========

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;

  AuthBloc(this.apiService) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  /// LOGIN HANDLER - GUARANTEED TO EMIT STATE
  /// 
  /// Flow:
  /// 1. Emit AuthLoading (shows loader)
  /// 2. Call API service
  /// 3. On success: Emit Authenticated (stops loader, navigates)
  /// 4. On error: Emit AuthError (stops loader, shows message)
  /// 
  /// CRITICAL: Always emits a state, never hangs
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 AuthBloc: Login requested for ${event.username}');
    emit(AuthLoading());
    
    try {
      print('📡 AuthBloc: Calling API service...');
      final response = await apiService.login(event.username, event.password);
      
      print('✅ AuthBloc: API call successful');
      print('📦 AuthBloc: Response keys: ${response.keys}');
      
      // Verify response has required fields
      if (!response.containsKey('access')) {
        print('❌ AuthBloc: Missing access token in response');
        emit(AuthError('Invalid server response: missing access token'));
        return;
      }
      
      final accessToken = response['access'] as String;
      print('🎫 AuthBloc: Access token received (${accessToken.length} chars)');
      
      // Emit authenticated state
      emit(Authenticated(accessToken));
      print('✅ AuthBloc: Authenticated state emitted');
      
    } catch (e, stackTrace) {
      print('❌ AuthBloc: Login error caught');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error message: $e');
      
      String message = 'Login failed';
      
      if (e is DioException) {
        if (e.response != null && e.response!.data is Map) {
          message = e.response!.data['error']?.toString() ?? 
                   e.response!.data['detail']?.toString() ?? 
                   e.message ?? 
                   'Server Error';
        } else {
          message = e.message ?? 'Network Error';
        }
      } else if (e is Exception) {
        message = e.toString().replaceAll('Exception: ', '');
      } else {
        message = e.toString();
      }
      
      print('🔴 AuthBloc: Emitting error state with message: $message');
      emit(AuthError(message));
      print('✅ AuthBloc: Error state emitted');
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await apiService.logout();
    emit(Unauthenticated());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final token = await apiService.getToken();
    if (token != null) {
      emit(Authenticated(token));
    } else {
      emit(Unauthenticated());
    }
  }
}

// ============================================================================
// EXPECTED BEHAVIOR
// ============================================================================

/*

SCENARIO 1: Valid Login
------------------------
1. User enters: usera / password123
2. User clicks Login button
3. AuthBloc emits AuthLoading
4. UI shows loading indicator, disables button
5. API call succeeds
6. Backend returns: {"access": "...", "refresh": "...", "user": {...}}
7. ApiService stores tokens in secure storage
8. AuthBloc emits Authenticated("access_token")
9. UI listener catches Authenticated state
10. UI shows success toast
11. UI navigates to /trips
12. ✅ SUCCESS - User sees dashboard

SCENARIO 2: Invalid Credentials
--------------------------------
1. User enters: usera / wrongpassword
2. User clicks Login button
3. AuthBloc emits AuthLoading
4. UI shows loading indicator, disables button
5. API call fails with 401
6. Backend returns: {"error": "Invalid credentials."}
7. ApiService throws Exception("Invalid username or password")
8. AuthBloc catches exception
9. AuthBloc emits AuthError("Invalid username or password")
10. UI listener catches AuthError state
11. UI hides loading indicator
12. UI shows error toast
13. UI shakes login card
14. ✅ SUCCESS - User can retry

SCENARIO 3: Network Error
--------------------------
1. User enters credentials
2. User clicks Login button
3. AuthBloc emits AuthLoading
4. UI shows loading indicator
5. Network timeout occurs
6. ApiService throws Exception("Connection timeout...")
7. AuthBloc catches exception
8. AuthBloc emits AuthError("Connection timeout...")
9. UI hides loading indicator
10. UI shows error toast
11. ✅ SUCCESS - User can retry

SCENARIO 4: Server Error (500)
-------------------------------
1. User enters credentials
2. User clicks Login button
3. AuthBloc emits AuthLoading
4. UI shows loading indicator
5. Backend returns 500
6. ApiService throws Exception("Server error...")
7. AuthBloc catches exception
8. AuthBloc emits AuthError("Server error...")
9. UI hides loading indicator
10. UI shows error toast
11. ✅ SUCCESS - User can retry

*/

// ============================================================================
// DEBUGGING CHECKLIST
// ============================================================================

/*

If infinite loader occurs, check:

1. ✅ AuthBloc ALWAYS emits a state (Authenticated or AuthError)
2. ✅ ApiService ALWAYS throws exception on error (never returns null)
3. ✅ UI BlocConsumer listens to both Authenticated and AuthError
4. ✅ Button isLoading checks: state is AuthLoading
5. ✅ Button onPressed checks: state is AuthLoading ? null : _login
6. ✅ No silent failures in try-catch blocks
7. ✅ All async operations have timeout
8. ✅ Network errors are caught and converted to exceptions

Console output should show:
- 🔐 AuthBloc: Login requested
- 📡 AuthBloc: Calling API service
- Either:
  ✅ AuthBloc: Authenticated state emitted
  OR
  ✅ AuthBloc: Error state emitted

If you don't see the final emit log, there's a bug in the flow.

*/

// ============================================================================
// BACKEND REQUIREMENTS
// ============================================================================

/*

Endpoint: POST /api/auth/login/

Request:
{
  "identifier": "username_or_email",
  "password": "password"
}

Success Response (200):
{
  "access": "eyJhbGc...",
  "refresh": "eyJhbGc...",
  "user": {
    "id": 2,
    "username": "usera",
    "email": "usera@example.com",
    ...
  }
}

Error Response (401):
{
  "error": "Invalid credentials."
}

Error Response (400):
{
  "error": "password: This field is required."
}

Error Response (500):
{
  "error": "An unexpected error occurred. Please try again later."
}

CORS Headers Required:
- Access-Control-Allow-Origin: *
- Access-Control-Allow-Methods: POST, OPTIONS
- Access-Control-Allow-Headers: Content-Type, Authorization

*/

// ============================================================================
// DEPLOYMENT VERIFICATION
// ============================================================================

/*

Before deploying, verify:

1. Backend URL in ApiService:
   ✅ static const String baseUrl = 'https://smart-trip-planner-dw13.onrender.com/api';
   ❌ NO localhost references

2. Backend environment variables on Render:
   ✅ SECRET_KEY set
   ✅ DEBUG=False
   ✅ DATABASE_URL set
   ✅ CORS_ALLOW_ALL_ORIGINS=True

3. Test login locally:
   curl -X POST http://localhost:8000/api/auth/login/ \
     -H "Content-Type: application/json" \
     -d '{"identifier":"usera","password":"password123"}'
   
   Should return 200 with tokens

4. Test login on Render:
   curl -X POST https://smart-trip-planner-dw13.onrender.com/api/auth/login/ \
     -H "Content-Type: application/json" \
     -d '{"identifier":"usera","password":"password123"}'
   
   Should return 200 with tokens

5. Flutter web build:
   flutter build web --release
   
6. Check browser console for errors

*/
