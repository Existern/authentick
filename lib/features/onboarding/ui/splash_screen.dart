import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/constants.dart';
import '../../../routing/routes.dart';
import '../../authentication/repository/authentication_repository.dart';
import '../model/onboarding_step_response.dart';
import '../service/onboarding_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with two ellipses
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF8F7FF),
              child: Stack(
                children: [
                  // Top-left ellipse
                  Positioned(
                    top: -100,
                    left: -100,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 213.8, sigmaY: 213.8),
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFE4CAFF).withValues(alpha: 1.0),
                              const Color(0xFFE4CAFF).withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom-right ellipse
                  Positioned(
                    bottom: 200,
                    right: -100,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 213.8, sigmaY: 213.8),
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFE4CAFF).withValues(alpha: 1.0),
                              const Color(0xFFE4CAFF).withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          const Center(child: _AuthentickLogo()),
        ],
      ),
    );
  }

  Future<void> _checkLoginStatus() async {
    final authRepo = ref.read(authenticationRepositoryProvider);

    debugPrint(
      '${Constants.tag} [SplashScreen._checkLoginStatus] ========================================',
    );
    debugPrint(
      '${Constants.tag} [SplashScreen._checkLoginStatus] Starting login check...',
    );

    // Try to auto-login using stored tokens
    final autoLoginSuccess = await authRepo.tryAutoLogin();
    debugPrint(
      '${Constants.tag} [SplashScreen] Auto-login result: $autoLoginSuccess',
    );

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    if (autoLoginSuccess) {
      // Check if user was on waitlist screen
      final savedStep = await authRepo.getCurrentOnboardingStep();
      debugPrint(
        '${Constants.tag} [SplashScreen] Saved onboarding step: $savedStep',
      );

      // Check if user was on waitlist screen
      if (savedStep == 'waitlist') {
        debugPrint(
          '${Constants.tag} [SplashScreen] User was on waitlist, redirecting back to waitlist',
        );
        if (!mounted) return;
        context.pushReplacement(Routes.waitlist);
        return;
      }

      // CRITICAL: Check onboarding progress from API - this is the source of truth
      // This replaces the profile API call and directly checks onboarding status
      try {
        final onboardingService = ref.read(onboardingServiceProvider);

        // Try to get onboarding progress
        // If token is expired (401), automatically refresh and retry
        final onboardingProgress = await _getOnboardingProgressWithRetry(
          authRepo,
          onboardingService,
        );

        debugPrint(
          '${Constants.tag} [SplashScreen] ========================================',
        );
        debugPrint(
          '${Constants.tag} [SplashScreen] Onboarding progress from API:',
        );
        debugPrint(
          '${Constants.tag} [SplashScreen] Completed: ${onboardingProgress.data.completed}',
        );
        debugPrint(
          '${Constants.tag} [SplashScreen] Total steps: ${onboardingProgress.data.steps.length}',
        );

        // Update the stored auth response with fresh onboarding data
        // This ensures the onboarding flow screen uses the latest data
        await authRepo.updateOnboardingInAuthResponse(onboardingProgress.data);

        debugPrint('${Constants.tag} [SplashScreen] Steps from API:');
        for (final step in onboardingProgress.data.steps) {
          debugPrint(
            '${Constants.tag} [SplashScreen]   - ${step.step}: ${step.status}',
          );
        }

        // Count pending steps
        final pendingSteps = onboardingProgress.data.steps
            .where((step) => step.status == 'pending')
            .toList();
        final completedSteps = onboardingProgress.data.steps
            .where(
              (step) => step.status == 'completed' || step.status == 'skipped',
            )
            .toList();

        debugPrint(
          '${Constants.tag} [SplashScreen] Pending steps: ${pendingSteps.length}',
        );
        debugPrint(
          '${Constants.tag} [SplashScreen] Completed/Skipped steps: ${completedSteps.length}',
        );

        // Onboarding is complete if:
        // 1. API says completed = true, OR
        // 2. ALL steps have terminal status (completed/skipped) - no pending steps left
        final isOnboardingComplete =
            onboardingProgress.data.completed ||
            (pendingSteps.isEmpty && onboardingProgress.data.steps.isNotEmpty);

        debugPrint(
          '${Constants.tag} [SplashScreen] Final isOnboardingComplete: $isOnboardingComplete',
        );
        debugPrint(
          '${Constants.tag} [SplashScreen] ========================================',
        );

        if (!mounted) return;

        if (isOnboardingComplete) {
          debugPrint(
            '${Constants.tag} [SplashScreen] ✅ Onboarding COMPLETE - navigating to main app',
          );
          // Clear any saved step since onboarding is done
          await authRepo.clearCurrentOnboardingStep();
          await authRepo.setHasCompletedOnboarding(true);
          context.pushReplacement(Routes.main);
        } else {
          debugPrint(
            '${Constants.tag} [SplashScreen] ❌ Onboarding INCOMPLETE - navigating to onboarding flow',
          );
          // Make sure the flag reflects reality
          await authRepo.setHasCompletedOnboarding(false);

          // If all steps are pending, ensure intro step is saved
          if (pendingSteps.length == onboardingProgress.data.steps.length) {
            debugPrint(
              '${Constants.tag} [SplashScreen] All steps pending - saving intro step',
            );
            await authRepo.saveCurrentOnboardingStep('intro');
          } else {
            // Some steps are completed, clear any old saved step to force using API data
            debugPrint(
              '${Constants.tag} [SplashScreen] Clearing saved step to use fresh API data',
            );
            await authRepo.clearCurrentOnboardingStep();
          }

          context.pushReplacement(Routes.onboardingFlow);
        }
      } catch (e) {
        debugPrint(
          '${Constants.tag} [SplashScreen] ⚠️ Error checking onboarding progress: $e',
        );

        // Note: 401 errors are already handled by _getOnboardingProgressWithRetry
        // which attempts token refresh. If we reach here with a 401, it means
        // the refresh also failed and SessionManager already triggered logout.

        // Check if error is due to authentication failures
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('401') ||
            errorString.contains('403') ||
            errorString.contains('unauthorized') ||
            errorString.contains('forbidden')) {
          debugPrint(
            '${Constants.tag} [SplashScreen] 🔒 Authentication failed after refresh attempt',
          );
          // SessionManager/refreshAccessToken already handled logout
          // Just redirect to register screen
          if (!mounted) return;
          context.pushReplacement(Routes.register);
          return;
        }

        // For other errors, check local state as fallback
        final hasCompletedOnboarding = await authRepo.hasCompletedOnboarding();
        if (!mounted) return;

        if (hasCompletedOnboarding) {
          debugPrint(
            '${Constants.tag} [SplashScreen] ✅ Local state says completed - navigating to main app',
          );
          context.pushReplacement(Routes.main);
        } else {
          debugPrint(
            '${Constants.tag} [SplashScreen] ❌ Local state says incomplete - navigating to onboarding flow',
          );
          await authRepo.setHasCompletedOnboarding(false);
          context.pushReplacement(Routes.onboardingFlow);
        }
      }
    } else {
      debugPrint(
        '${Constants.tag} [SplashScreen._checkLoginStatus] Auto-login failed or no stored tokens',
      );
      debugPrint(
        '${Constants.tag} [SplashScreen] Navigating to register (user not logged in)',
      );
      if (!mounted) return;
      context.pushReplacement(Routes.register);
    }
  }

  /// Get onboarding progress with automatic token refresh on 401
  ///
  /// Flow:
  /// 1. Try to call /users/onboarding API
  /// 2. If 401 (token expired):
  ///    a. Call /auth/refresh with refresh token from secure storage
  ///    b. Save new tokens and auth response
  ///    c. Retry /users/onboarding with new access token
  /// 3. If refresh fails (invalid refresh token):
  ///    - refreshAccessToken() clears tokens and triggers logout
  ///    - Error is propagated to caller
  Future<OnboardingStepResponse> _getOnboardingProgressWithRetry(
    AuthenticationRepository authRepo,
    OnboardingService onboardingService,
  ) async {
    try {
      // First attempt
      return await onboardingService.getOnboardingProgress();
    } catch (e) {
      // Check if error is 401 (token expired)
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('401') || errorString.contains('unauthorized')) {
        debugPrint(
          '${Constants.tag} [SplashScreen] 🔄 Got 401, attempting token refresh...',
        );

        try {
          // Refresh the access token using refresh token
          final refreshResponse = await authRepo.refreshAccessToken();

          debugPrint(
            '${Constants.tag} [SplashScreen] ✅ Token refreshed successfully',
          );

          // The refresh endpoint returns full auth response with user, tokens, and onboarding
          // Save this complete auth response
          await authRepo.saveAuthResponse(refreshResponse);

          debugPrint(
            '${Constants.tag} [SplashScreen] 📝 Saved auth response from refresh endpoint',
          );

          // Retry onboarding API call with new token
          debugPrint(
            '${Constants.tag} [SplashScreen] 🔄 Retrying onboarding API call with new token...',
          );
          return await onboardingService.getOnboardingProgress();
        } catch (refreshError) {
          debugPrint(
            '${Constants.tag} [SplashScreen] ❌ Token refresh failed: $refreshError',
          );
          // If refresh fails, the authentication repository will handle logout
          rethrow;
        }
      }

      // If not 401 or refresh failed, rethrow original error
      rethrow;
    }
  }
}

class _AuthentickLogo extends StatefulWidget {
  const _AuthentickLogo();

  @override
  State<_AuthentickLogo> createState() => _AuthentickLogoState();
}

class _AuthentickLogoState extends State<_AuthentickLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SvgPicture.asset(
              'assets/images/authentick_logo.svg',
              width: 200,
              height: 60,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const SizedBox(
                width: 200,
                height: 60,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6A4FFB),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
