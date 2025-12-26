import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/toast_utils.dart';
import '../../models/models.dart';
import '../../widgets/avatar_widget.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({Key? key}) : super(key: key);

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _invitations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    setState(() => _loading = true);
    try {
      final data = await _apiService.getInvitations();
      setState(() {
        _invitations = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(String token, String status) async {
    // Optimistic Update: Remove immediately
    final previousList = List<dynamic>.from(_invitations);
    setState(() {
      _invitations.removeWhere((i) => i['token'] == token);
    });

    try {
      if (status == 'ACCEPTED') {
          await _apiService.acceptInvite(token);
          if(mounted) ToastUtils.showSuccess(context, 'You joined the trip!');
      } else {
          await _apiService.declineInvite(token);
          if(mounted) ToastUtils.showSuccess(context, 'Invitation declined');
      }
    } catch (e) {
      // Revert on failure
      if(mounted) {
          setState(() {
            _invitations = previousList;
          });
          ToastUtils.showError(context, 'Action failed. Please try again.');
      } 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Trip Invitations',
          style: GoogleFonts.poppins(color: const Color(0xFF102A43), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF102A43)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invitations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                           shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.mail_outline_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending invitations',
                        style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _invitations.length,
                  itemBuilder: (context, index) {
                    final invite = _invitations[index];
                    if (invite == null) return const SizedBox.shrink();

                    // Safe Access Logic
                    final Map<String, dynamic>? invitedBy = invite['invited_by'];
                    final String senderName = invitedBy?['username'] ?? 'Unknown User';
                    final Map<String, dynamic>? avatarJson = invitedBy?['avatar'];
                    final String? token = invite['token'];
                    
                    final tripTitle = invite['trip_title'] ?? 'Trip';
                    final status = invite['status'];

                    if (status != 'PENDING' || token == null) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AvatarWidget(
                                  avatar: avatarJson != null ? AvatarData.fromJson(avatarJson) : AvatarData(),
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14),
                                      children: [
                                        TextSpan(text: senderName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                        const TextSpan(text: ' invited you to join:'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tripTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _respond(token, 'REJECTED'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      foregroundColor: Colors.grey,
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    child: const Text('Decline'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _respond(token, 'ACCEPTED'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      elevation: 0,
                                    ),
                                    child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
