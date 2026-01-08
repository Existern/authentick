import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../constants/constants.dart';
import '../../../features/authentication/repository/authentication_repository.dart';
import '../../../routing/routes.dart';

import '../../../theme/app_theme.dart';
import 'view_model/authentication_view_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
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
    final authState = ref.watch(authenticationViewModelProvider);

    // Listen to authentication state for navigation
    ref.listen(authenticationViewModelProvider, (previous, next) async {
      debugPrint('${Constants.tag} [RegisterScreen] Auth state changed: $next');

      if (next is AsyncData) {
        final value = next.value;
        debugPrint(
          '${Constants.tag} [RegisterScreen] isSignInSuccessfully: ${value?.isSignInSuccessfully}',
        );

        if (value?.isSignInSuccessfully == true) {
          // User signed in successfully, get the auth response from storage
          debugPrint(
            '${Constants.tag} [RegisterScreen] Getting auth response from storage',
          );
          final authRepo = ref.read(authenticationRepositoryProvider);
          final authResponse = await authRepo.getAuthResponse();

          if (!context.mounted) return;

          if (authResponse != null) {
            debugPrint(
              '${Constants.tag} [RegisterScreen] Auth response loaded, checking onboarding status',
            );

            final onboarding = authResponse.data.onboarding;
            if (onboarding != null) {
              // Check if there are any incomplete steps
              final hasIncompleteSteps = onboarding.steps.any(
                (step) => step.status != 'completed',
              );

              debugPrint(
                '${Constants.tag} [RegisterScreen] Onboarding completed flag: ${onboarding.completed}',
              );
              debugPrint(
                '${Constants.tag} [RegisterScreen] Has incomplete steps: $hasIncompleteSteps',
              );

              if (hasIncompleteSteps) {
                // There are incomplete steps, navigate to onboarding flow
                debugPrint(
                  '${Constants.tag} [RegisterScreen] Found incomplete steps, navigating to onboarding flow',
                );
                context.pushReplacement(Routes.onboardingFlow);
              } else {
                // All steps completed, go to main
                debugPrint(
                  '${Constants.tag} [RegisterScreen] All steps completed, navigating to main',
                );
                await authRepo.setHasCompletedOnboarding(true);
                if (!context.mounted) return;
                context.pushReplacement(Routes.main);
              }
            } else {
              // No onboarding data, navigate to onboarding flow
              debugPrint(
                '${Constants.tag} [RegisterScreen] No onboarding data, navigating to onboarding flow',
              );
              context.pushReplacement(Routes.onboardingFlow);
            }
          } else {
            debugPrint(
              '${Constants.tag} [RegisterScreen] No auth response found, navigating to onboarding flow',
            );
            context.pushReplacement(Routes.onboardingFlow);
          }
        }
      } else if (next is AsyncError) {
        debugPrint(
          '${Constants.tag} [RegisterScreen] Auth error: ${next.error}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final isLoading = authState.isLoading;

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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Logo with animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: SvgPicture.asset(
                            'assets/images/authentick_logo.svg',
                            width: 220,
                            height: 70,
                            fit: BoxFit.contain,
                            placeholderBuilder: (context) => const SizedBox(
                              width: 220,
                              height: 70,
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
                  ),

                  const SizedBox(height: 24),

                  // Tagline
                  Text(
                    'A social network where every moment is\nreal, every location is verified and every\nthought is authentic',
                    textAlign: TextAlign.center,
                    style: AppTheme.body16.copyWith(
                      color: const Color(0xFF1A1A1A),
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Login/Signup with Google Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF4300FF,
                        ), // Vibrant Purple
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              ref
                                  .read(
                                    authenticationViewModelProvider.notifier,
                                  )
                                  .signInWithGoogle();
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  Assets.googleLogo,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Login/Signup with Google',
                                  style: AppTheme.title16.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        side: const BorderSide(
                          color: Color(0xFF1A1A1A),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              ref
                                  .read(
                                    authenticationViewModelProvider.notifier,
                                  )
                                  .signInWithApple();
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  Assets.appleLogo,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Sign in with Apple',
                                  style: AppTheme.title16.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
