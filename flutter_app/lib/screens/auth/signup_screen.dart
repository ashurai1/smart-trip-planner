import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../utils/toast_utils.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _shakeKey = 0;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _apiService.register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) {
          ToastUtils.showSuccess(context, 'Registration successful! Please login.');
          Navigator.pop(context); // Go back to login
        }
      } catch (e) {
        if (mounted) {
          setState(() => _shakeKey++);
          
          String message = 'Registration failed';
          if (e is DioException) {
             if (e.response != null && e.response!.data is Map) {
                // DRF errors for fields might be {"username": ["Taken"]} or just {"detail": "..."}
                final data = e.response!.data;
                if (data.containsKey('username')) {
                   message = (data['username'] as List).first.toString();
                } else if (data.containsKey('detail')) {
                   message = data['detail'];
                } else {
                   // Fallback: take first value if map
                   message = data.values.first.toString();
                }
             }
          }
          ToastUtils.showError(context, message);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Shake on client-side validation error too
      setState(() => _shakeKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00695C), // Dark Teal
                  Color(0xFF80CBC4), // Light Teal
                ],
              ),
            ),
          ),
           
          // 2. Decorative Circles
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // 3. Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   // Header
                   Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                      ),
                   ),
                   const SizedBox(height: 8),
                   Text(
                      'Join us and start your journey',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                   ),
                   const SizedBox(height: 48),

                   // Form Card
                   Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty || !v.contains('@') ? 'Invalid email' : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 56, // Taller button
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signup,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    elevation: 8,
                                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Register'),
                              ),
                            ),
                          ],
                        ),
                      ),
                   )
                   .animate(key: ValueKey(_shakeKey), autoPlay: _shakeKey > 0)
                   .shake(duration: 400.ms, hz: 4, curve: Curves.easeInOutCubic),

                   const SizedBox(height: 24),
                   TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                          children: [
                            TextSpan(
                              text: 'Log In',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
