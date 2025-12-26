import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/avatar_widget.dart';
import 'profile_edit_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  UserProfile? _userProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load profile'),
              TextButton(onPressed: _loadProfile, child: const Text('Retry'))
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                  Colors.white,
                ],
                stops: const [0.0, 0.4, 0.4], // Hard stop for card effect
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // --- HEADER (Avatar + Name) ---
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                            boxShadow: [
                               BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                            ]
                          ),
                          child: AvatarWidget(avatar: _userProfile!.avatar, size: 100),
                        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          _userProfile!.fullName,
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ).animate().fadeIn().slideY(begin: 0.5),
                        
                        Text(
                          '@${_userProfile!.username}',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                        ).animate().fadeIn(delay: 200.ms),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // --- INFO CARD ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Personal Info', style: Theme.of(context).textTheme.titleLarge),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (_) => ProfileEditScreen(
                                      userProfile: _userProfile!,
                                      onProfileUpdated: _loadProfile,
                                    )
                                  )
                                );
                              }, 
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.secondary),
                              )
                            )
                          ],
                        ),
                        const Divider(height: 32),
                        
                        _buildInfoRow(Icons.email_outlined, 'Email', _userProfile!.email),
                        const SizedBox(height: 24),
                        _buildInfoRow(Icons.phone_outlined, 'Phone', _userProfile!.phoneNumber),
                        const SizedBox(height: 24),
                        _buildInfoRow(Icons.info_outline, 'Bio', _userProfile!.bio),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Not set' : value, 
                style: const TextStyle(fontSize: 15, color: Color(0xFF102A43), fontWeight: FontWeight.w500)
              ),
            ],
          ),
        ),
      ],
    );
  }
}
