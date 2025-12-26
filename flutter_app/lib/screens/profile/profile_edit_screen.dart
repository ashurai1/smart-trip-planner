import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/avatar_widget.dart';
import 'avatar_selector_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback onProfileUpdated;

  const ProfileEditScreen({
    Key? key,
    required this.userProfile,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final ApiService _apiService = ApiService();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _otpController;

  AvatarData _currentAvatar = AvatarData();
  bool _isLoading = false;
  bool _showOtpField = false;
  bool _otpSent = false;
  bool _isSavingPhone = false;

  @override
  void initState() {
    super.initState();
    _currentAvatar = widget.userProfile.avatar;
    _firstNameController = TextEditingController(text: widget.userProfile.firstName);
    _lastNameController = TextEditingController(text: widget.userProfile.lastName);
    _bioController = TextEditingController(text: widget.userProfile.bio);
    _phoneController = TextEditingController(text: widget.userProfile.phoneNumber);
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _saveBasicDetails() async {
    final newFirstName = _firstNameController.text.trim();
    final newLastName = _lastNameController.text.trim();
    final newBio = _bioController.text.trim();
    
    // Check for changes
    String? firstNameParam;
    if (newFirstName != widget.userProfile.firstName) firstNameParam = newFirstName;

    String? lastNameParam;
    if (newLastName != widget.userProfile.lastName) lastNameParam = newLastName;

    String? bioParam;
    if (newBio != widget.userProfile.bio) bioParam = newBio;

    Map<String, dynamic>? avatarParam;
    // Simple comparison for avatar
    if (_currentAvatar.style != widget.userProfile.avatar.style || 
        _currentAvatar.color != widget.userProfile.avatar.color || 
        _currentAvatar.icon != widget.userProfile.avatar.icon) {
        avatarParam = _currentAvatar.toJson();
    }
    
    // Check if phone changed (handled separately but checking here to avoid premature success msg)
    final phoneChanged = _phoneController.text.trim() != widget.userProfile.phoneNumber;

    if (firstNameParam == null && lastNameParam == null && bioParam == null && avatarParam == null && !phoneChanged) {
        if (mounted) {
           ToastUtils.showInfo(context, 'No changes detected.');
           return; 
        }
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Update Basic details + Avatar (if any)
      if (firstNameParam != null || lastNameParam != null || bioParam != null || avatarParam != null) {
          await _apiService.updateProfile(
            firstName: firstNameParam,
            lastName: lastNameParam,
            bio: bioParam,
            avatar: avatarParam,
          );
      }

      // 2. Check if phone changed
      if (phoneChanged) {
        // If phone changed, we need OTP flow
        ToastUtils.showInfo(context, 'Basic info saved. Verify phone separately.');
        setState(() {
           _isLoading = false;
           _showOtpField = true; 
        });
      } else {
        if (mounted) {
          ToastUtils.showSuccess(context, 'Profile updated successfully!');
          widget.onProfileUpdated();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Extract inner message if possible
        String errorMsg = e.toString();
        
        // Improved Error Parsing
        /* 
         If ApiService throws just the "detail" or "validation error on: ...", 
         it's already readable. But if DioException, let's catch standard 400s better.
         The ApiService wraps errors, so we likely get a string.
        */
        ToastUtils.showError(context, 'Failed to update: $errorMsg');
      }
    }
  }

  Future<void> _requestOtp() async {
    setState(() => _isSavingPhone = true);
    try {
      await _apiService.requestUpdateOtp();
      setState(() {
        _otpSent = true;
        _isSavingPhone = false;
      });
      ToastUtils.showInfo(context, 'OTP sent to console (Dev Mode)');
    } catch (e) {
      setState(() => _isSavingPhone = false);
      ToastUtils.showError(context, 'Failed to send OTP: $e');
    }
  }

  Future<void> _verifyPhone() async {
    if (_otpController.text.length != 6) {
      ToastUtils.showError(context, 'Enter valid 6-digit OTP');
      return;
    }
    setState(() => _isSavingPhone = true);
    try {
      await _apiService.updateProfile(
        otp: _otpController.text,
        phoneNumber: _phoneController.text.trim(),
      );
      if (mounted) {
        ToastUtils.showSuccess(context, 'Phone number updated!');
        widget.onProfileUpdated();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSavingPhone = false);
      ToastUtils.showError(context, 'Verification failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Glassmorphism Container Decoration
    final glassDecoration = BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
      ],
      border: Border.all(color: Colors.white.withOpacity(0.5)),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF102A43))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF102A43)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // --- AVATAR SECTION ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), width: 2),
                      ),
                      child: AvatarWidget(avatar: _currentAvatar, size: 100),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AvatarSelectorScreen(
                                currentAvatar: _currentAvatar,
                                onSave: (newAvatar) {
                                  setState(() => _currentAvatar = newAvatar);
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                               BoxShadow(color: Theme.of(context).colorScheme.secondary.withOpacity(0.4), blurRadius: 8),
                            ],
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(),

              const SizedBox(height: 32),

              // --- FORM ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: glassDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Details', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(child: _buildTextField('First Name', _firstNameController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Last Name', _lastNameController)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Bio', _bioController, maxLines: 3),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // --- CONTACT INFO & OTP ---
              Container(
                 padding: const EdgeInsets.all(24),
                 decoration: glassDecoration,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text('Contact Info', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 24),
                      _buildTextField('Phone Number', _phoneController, icon: Icons.phone_outlined, 
                          onChanged: (val) {
                             if (val != widget.userProfile.phoneNumber && !_showOtpField) {
                                setState(() => _showOtpField = true);
                             }
                          }
                      ),
                      
                      if (_showOtpField) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "To update phone number, verify OTP.",
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.orange[800]),
                              ),
                              const SizedBox(height: 12),
                              if (!_otpSent)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isSavingPhone ? null : _requestOtp,
                                    icon: const Icon(Icons.send_rounded, size: 16),
                                    label: _isSavingPhone 
                                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                                        : const Text("Request OTP"),
                                  ),
                                ),
                              
                              if (_otpSent) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _otpController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter 6-digit OTP',
                                    prefixIcon: Icon(Icons.lock_clock),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSavingPhone ? null : _verifyPhone,
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    child: _isSavingPhone 
                                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                        : const Text("Verify & Update Phone"),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ).animate().fadeIn(),
                      ]
                   ],
                 ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 48),

              // --- SAVE BUTTON ---
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBasicDetails,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ).animate().fadeIn(delay: 300.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, IconData? icon, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        alignLabelWithHint: true,
      ),
    );
  }
}
