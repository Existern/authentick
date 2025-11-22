import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/constants.dart';
import '../../../routing/routes.dart';
import '../../authentication/repository/authentication_repository.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3F0FF), // Light purple
              Color(0xFFFFFFFF), // White
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: const Center(child: _AuthentickLogo()),
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

      if (savedStep == 'waitlist') {
        debugPrint(
          '${Constants.tag} [SplashScreen] User was on waitlist, redirecting back to waitlist',
        );
        if (!mounted) return;
        context.pushReplacement(Routes.waitlist);
        return;
      }

      // CRITICAL: Check API response's onboarding data - this is the source of truth
      final authResponse = await authRepo.getAuthResponse();

      if (authResponse == null) {
        debugPrint(
          '${Constants.tag} [SplashScreen] ⚠️ No auth response found despite successful login',
        );
        if (!mounted) return;
        context.pushReplacement(Routes.register);
        return;
      }

      final onboardingData = authResponse.data.onboarding;
      debugPrint(
        '${Constants.tag} [SplashScreen] Onboarding data from API: ${onboardingData != null ? "exists" : "null"}',
      );

      // Check if onboarding is truly complete
      bool isOnboardingComplete = false;

      if (onboardingData != null) {
        debugPrint(
          '${Constants.tag} [SplashScreen] API onboarding.completed flag: ${onboardingData.completed}',
        );
        debugPrint(
          '${Constants.tag} [SplashScreen] Total steps: ${onboardingData.steps.length}',
        );

        // Count completed steps
        final completedSteps = onboardingData.steps
            .where((step) => step.status == 'completed')
            .length;
        debugPrint(
          '${Constants.tag} [SplashScreen] Completed steps: $completedSteps/${onboardingData.steps.length}',
        );

        // Onboarding is complete ONLY if:
        // 1. API says completed = true, OR
        // 2. ALL steps have status = "completed"
        isOnboardingComplete = onboardingData.completed ||
                              (completedSteps == onboardingData.steps.length && onboardingData.steps.isNotEmpty);

        debugPrint(
          '${Constants.tag} [SplashScreen] Final isOnboardingComplete decision: $isOnboardingComplete',
        );
      } else {
        // No onboarding data means user needs to do onboarding
        debugPrint(
          '${Constants.tag} [SplashScreen] No onboarding data in API response - treating as incomplete',
        );
        isOnboardingComplete = false;
      }

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
        context.pushReplacement(Routes.onboardingFlow);
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
