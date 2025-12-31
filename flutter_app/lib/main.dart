import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/trips/trip_bloc.dart';
import 'blocs/notifications/notification_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/trips/trip_list_screen.dart';
import 'screens/trips/trip_detail_screen.dart';
import 'services/api_service.dart';
import 'theme/wander_flow_theme.dart';

void main() {
  // Ensure binding initialized for async ops before runApp if needed
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Repository Provider could be used here, but simple variable is fine for MVP
    final apiService = ApiService();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(apiService)..add(CheckAuthStatus()),
        ),
        BlocProvider<TripBloc>(
          create: (context) => TripBloc(apiService),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(apiService)..add(LoadNotifications()),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Trip Planner',
        theme: WanderFlowTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        
        // Define Routes
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/trips': (context) => const TripListScreen(),
        },
        
        // Dynamic Route Generation
        onGenerateRoute: (settings) {
          if (settings.name == '/trip-detail') {
            final args = settings.arguments;
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) => TripDetailScreen(tripId: args),
              );
            }
            // Fallback error or list if arguments missing
            return MaterialPageRoute(builder: (context) => const TripListScreen());
          }
          return null;
        },
      ),
    );
  }
}

/// Authentication Wrapper
/// Redirects to Login or Home based on Auth State
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is Authenticated) {
          return const TripListScreen();
        } else if (state is Unauthenticated) {
          return const LoginScreen();
        }
        // Show loading indicator while checking auth status
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
