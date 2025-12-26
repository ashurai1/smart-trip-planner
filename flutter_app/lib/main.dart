import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/trips/trip_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/trips/trip_list_screen.dart';
import 'screens/trips/trip_detail_screen.dart';
import 'services/api_service.dart';
import 'blocs/notifications/notification_bloc.dart';
import 'theme/wander_flow_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc(apiService)..add(CheckAuthStatus())),
        BlocProvider(create: (context) => TripBloc(apiService)),
        BlocProvider(create: (context) => NotificationBloc(apiService)..add(LoadNotifications())),
      ],
      child: MaterialApp(
        title: 'Smart Trip Planner',
        theme: WanderFlowTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/trips': (context) => const TripListScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/trip-detail') {
            final tripId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => TripDetailScreen(tripId: tripId),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const TripListScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
