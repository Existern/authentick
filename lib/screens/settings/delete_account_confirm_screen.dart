import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/ui/view_model/authentication_view_model.dart';
import '../../features/user/repository/user_profile_repository.dart';
import '../../routing/routes.dart';

/// Screen 2: Confirm account deletion - with TTL countdown
class DeleteAccountConfirmScreen extends ConsumerStatefulWidget {
  final String? reason;

  const DeleteAccountConfirmScreen({
    super.key,
    this.reason,
  });

  @override
  ConsumerState<DeleteAccountConfirmScreen> createState() => _DeleteAccountConfirmScreenState();
}

class _DeleteAccountConfirmScreenState extends ConsumerState<DeleteAccountConfirmScreen> {
  bool _isDeleting = false;
  String? _errorMessage;

  // TTL in days for account deletion
  static const int deletionTTLDays = 30;

  Future<void> _onDeleteAccount() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      // Call the delete account API
      final response = await ref
          .read(userProfileRepositoryProvider.notifier)
          .deleteAccount();
      
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.data.message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Sign out and navigate to login
      await ref.read(authenticationViewModelProvider.notifier).signOut();
      
      if (!mounted) return;
      context.go(Routes.register);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isDeleting = false;
        _errorMessage = 'Failed to delete account. Please try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onCancel() {
    // Pop back to settings (pop twice to go back to settings from reason screen)
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confirm account deletion',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'If you continue to delete your account, your profile, account details and all associated data will be deleted.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // TTL countdown info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your account will be permanently deleted in $deletionTTLDays days. You can restore it anytime before then.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.orange.shade800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Delete account button (dark purple/indigo)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isDeleting ? null : _onDeleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3620B3), // Dark purple/indigo
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color.fromRGBO(54, 32, 179, 0.6), // 0xFF3620B3 with 60% opacity
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Delete account',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Cancel button (outlined)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isDeleting ? null : _onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(
                          color: _isDeleting ? Colors.grey.shade300 : Colors.black,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _isDeleting ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
