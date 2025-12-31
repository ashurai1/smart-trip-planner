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
      print('❌ Stack trace: $stackTrace');
      
      String message = 'Login failed';
      
      if (e is DioException) {
        print('📡 DioException details:');
        print('   Type: ${e.type}');
        print('   Status: ${e.response?.statusCode}');
        print('   Data: ${e.response?.data}');
        
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
