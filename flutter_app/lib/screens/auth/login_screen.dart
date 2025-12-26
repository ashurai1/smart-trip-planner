import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../theme/wander_flow_theme.dart';
import '../../widgets/wander_widgets.dart';
import 'signup_screen.dart';
import '../../utils/toast_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _shakeKey = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          _usernameController.text,
          _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // WanderFlow Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6A3D), // Sunset Orange
                  Color(0xFFFF3D77), // Warm Pink
                  Color(0xFF5B2EFF), // Deep Purple
                ],
              ),
            ),
          ),
          
          // Floating Orbs (Subtle)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 3000.ms, color: Colors.white.withOpacity(0.1)),
          ),
          
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 4000.ms, delay: 1000.ms, color: Colors.white.withOpacity(0.08)),
          ),
          
          // Content
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                setState(() => _shakeKey++);
                ToastUtils.showError(context, state.message);
              } else if (state is Authenticated) {
                ToastUtils.showSuccess(context, 'Welcome back!');
                Navigator.of(context).pushReplacementNamed('/trips');
              }
            },
            builder: (context, state) {
              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with Pulse Animation
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.flight_takeoff_rounded,
                            size: 72,
                            color: Color(0xFFFF6A3D),
                          ),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .scale(duration: 2000.ms, begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05))
                          .then()
                          .scale(duration: 2000.ms, begin: const Offset(1.05, 1.05), end: const Offset(1.0, 1.0)),
                        
                        const SizedBox(height: 40),
                        
                        // Title
                        Text(
                          'WanderFlow',
                          style: GoogleFonts.poppins(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Plan your next adventure together',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                        
                        const SizedBox(height: 56),

                        // Login Card
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.98),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                WanderTextField(
                                  hint: 'Enter your username',
                                  label: 'Username',
                                  icon: Icons.person_outline_rounded,
                                  controller: _usernameController,
                                  validator: (value) => value!.isEmpty ? 'Username required' : null,
                                ),
                                const SizedBox(height: 24),
                                WanderTextField(
                                  hint: 'Enter your password',
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  controller: _passwordController,
                                  validator: (value) => value!.isEmpty ? 'Password required' : null,
                                ),
                                const SizedBox(height: 32),
                                WanderButton(
                                  text: 'Login',
                                  onPressed: state is AuthLoading ? null : _login,
                                  isLoading: state is AuthLoading,
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate(key: ValueKey(_shakeKey), autoPlay: _shakeKey > 0)
                        .shake(duration: 400.ms, hz: 4, curve: Curves.easeInOutCubic)
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 32),
                        
                        // Signup Link
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                               PageRouteBuilder(
                                 pageBuilder: (context, animation, secondaryAnimation) => const SignupScreen(),
                                 transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                   return SharedAxisTransition(
                                     animation: animation,
                                     secondaryAnimation: secondaryAnimation,
                                     transitionType: SharedAxisTransitionType.horizontal,
                                     child: child,
                                   );
                                 },
                               ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'Don\'t have an account? ',
                              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.95), fontSize: 15),
                              children: [
                                TextSpan(
                                  text: 'Sign Up',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                        
                        // Demo Credentials
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            '🎭 Demo: usera / password123',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ).animate().fadeIn(delay: 800.ms),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
