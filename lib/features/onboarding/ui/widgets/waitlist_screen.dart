import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/constants.dart';
import '../../../../routing/routes.dart';
import '../../../authentication/repository/authentication_repository.dart';
import '../../view_model/onboarding_view_model.dart';
import '../../../waitlist/model/waitlist_request.dart';
import '../../../waitlist/service/waitlist_service.dart';

class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key});

  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  bool _isLoading = true;
  bool _isSubmitted = false;
  bool _alreadyExists = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Save waitlist state when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authRepo = ref.read(authenticationRepositoryProvider);
      await authRepo.saveCurrentOnboardingStep('waitlist');
      _submitToWaitlist();
    });
  }

  Future<void> _submitToWaitlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get email from saved auth response
      final authRepo = ref.read(authenticationRepositoryProvider);
      final authResponse = await authRepo.getAuthResponse();

      String? email = authResponse?.data.user.email;

      debugPrint(
        '${Constants.tag} [WaitlistScreen] Retrieved email from auth response: $email',
      );

      if (email == null || email.isEmpty) {
        debugPrint(
          '${Constants.tag} [WaitlistScreen] No email found in auth response',
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to retrieve your email. Please try again.';
        });
        return;
      }

      debugPrint(
        '${Constants.tag} [WaitlistScreen] Submitting email to waitlist: $email',
      );

      final service = ref.read(waitlistServiceProvider);
      final response = await service.joinWaitlist(
        WaitlistRequest(email: email),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSubmitted = true;
        _alreadyExists = response.data.alreadyExists;
      });

      debugPrint(
        '${Constants.tag} [WaitlistScreen] Already exists: $_alreadyExists',
      );
    } catch (e) {
      debugPrint(
        '${Constants.tag} [WaitlistScreen] Error joining waitlist: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to join waitlist. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // User pressed back - save that they're returning to invite code screen
          debugPrint(
            '${Constants.tag} [WaitlistScreen] User pressed back, saving invite_code_verified step',
          );
          final authRepo = ref.read(authenticationRepositoryProvider);
          await authRepo.saveCurrentOnboardingStep('invite_code_verified');
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Full background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/waitlist.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // White gradient overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.35,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.98),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    // Header: Centered logo
                    SizedBox(
                      height: 40,
                      child: Align(
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/images/authentick_logo.svg',
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Bottom content
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF3620B3)),
          SizedBox(height: 16),
          Text(
            'Joining waitlist...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
        ],
      );
    }

    if (_isSubmitted) {
      return Column(
        children: [
          // Title - different based on whether user already exists
          Text(
            _alreadyExists
                ? "You're already on\nthe waitlist!"
                : "We've placed you\non the waitlist!",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Subtitle - different based on whether user already exists
          Text(
            _alreadyExists
                ? 'You will be notified soon via\nteam@authentick.com for an invite.'
                : 'Watch out for a mail from\nteam@authentick.com for an invite.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          // Button to navigate back to invite code screen
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3620B3),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _navigateToInviteCodeScreen(),
              child: const Text(
                'I have an invite code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _navigateToInviteCodeScreen() async {
    // Save the onboarding step to invite_code_verified
    final authRepo = ref.read(authenticationRepositoryProvider);
    await authRepo.saveCurrentOnboardingStep('invite_code_verified');

    // Set the onboarding view model step directly to inviteCode
    await ref.read(onboardingViewModelProvider.notifier).goToInviteCode();

    // Navigate to onboarding flow - it will show invite code screen directly
    if (mounted) {
      context.go(Routes.onboardingFlow);
    }
  }
}
