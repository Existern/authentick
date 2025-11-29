import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../features/authentication/ui/otp_screen.dart';
import '../features/authentication/ui/sign_in_screen.dart';
import '../features/authentication/ui/register_screen.dart';

// import '../features/main/ui/main_screen.dart';
import '../screens/bottomnav/bottomnav.dart';
import '../features/onboarding/ui/onboarding_screen.dart';
import '../features/onboarding/ui/onboarding_flow_screen.dart';
import '../features/onboarding/ui/splash_screen.dart';
import '../features/onboarding/ui/widgets/waitlist_screen.dart';
import '../features/premium/ui/premium_screen.dart';
import '../features/profile/model/profile.dart';
import '../features/profile/ui/account_info_screen.dart';
import '../features/profile/ui/appearances_screen.dart';
import '../features/profile/ui/languages_screen.dart';
import 'routes.dart';

enum SlideDirection { right, left, up, down }

extension GoRouterStateExtension on GoRouterState {
  SlideRouteTransition slidePage(
    Widget child, {
    SlideDirection direction = SlideDirection.left,
  }) {
    return SlideRouteTransition(
      key: pageKey,
      child: child,
      direction: direction,
    );
  }
}

class SlideRouteTransition extends CustomTransitionPage<void> {
  SlideRouteTransition({
    required super.key,
    required super.child,
    SlideDirection direction = SlideDirection.left,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curve = CurvedAnimation(
             parent: animation,
             curve: Curves.easeInOut,
           );

           Offset begin;
           switch (direction) {
             case SlideDirection.right:
               begin = const Offset(-1.0, 0.0);
               break;
             case SlideDirection.left:
               begin = const Offset(1.0, 0.0);
               break;
             case SlideDirection.up:
               begin = const Offset(0.0, 1.0);
               break;
             case SlideDirection.down:
               begin = const Offset(0.0, -1.0);
               break;
           }
           final tween = Tween(begin: begin, end: Offset.zero);
           final offsetAnimation = tween.animate(curve);

           return SlideTransition(position: offsetAnimation, child: child);
         },
       );
}

final GoRouter router = GoRouter(
  initialLocation: Routes.splash,
  redirect: (context, state) async {
    // Skip redirect for splash screen (initial loading)
    if (state.matchedLocation == Routes.splash) {
      return null;
    }

    // Check if user is already logged in
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(Constants.isLoginKey) ?? false;

    if (isLoggedIn) {
      // Check if user has completed onboarding
      final hasCompletedOnboarding =
          prefs.getBool(Constants.hasCompletedOnboardingKey) ?? false;

      if (!hasCompletedOnboarding) {
        // Allow access to waitlist screen
        if (state.matchedLocation == Routes.waitlist) {
          return null;
        }

        // Check if user was on waitlist
        final currentStep = prefs.getString('current_onboarding_step');
        if (currentStep == 'waitlist' &&
            state.matchedLocation != Routes.waitlist) {
          return Routes.waitlist;
        }

        if (state.matchedLocation != Routes.onboardingFlow) {
          return Routes.onboardingFlow;
        }
        return null;
      }

      // Redirect to main if trying to access auth screens while logged in
      if (state.matchedLocation == Routes.register ||
          state.matchedLocation == Routes.login) {
        return Routes.main;
      }
    } else {
      // Not logged in, redirect to register unless already on auth screens
      if (state.matchedLocation != Routes.register &&
          state.matchedLocation != Routes.login &&
          state.matchedLocation != Routes.otp) {
        return Routes.register;
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: Routes.register,
      pageBuilder: (context, state) => state.slidePage(const RegisterScreen()),
    ),
    GoRoute(
      path: Routes.splash,
      pageBuilder: (context, state) => state.slidePage(const SplashScreen()),
    ),
    GoRoute(
      path: Routes.login,
      pageBuilder: (context, state) => state.slidePage(const SignInScreen()),
    ),
    GoRoute(
      path: Routes.otp,
      pageBuilder: (context, state) {
        final map = state.extra as Map?;
        return state.slidePage(
          OtpScreen(email: map?['email'], isRegister: map?['isRegister']),
        );
      },
    ),
    GoRoute(
      path: Routes.onboarding,
      pageBuilder: (context, state) =>
          state.slidePage(const OnboardingScreen()),
    ),
    GoRoute(
      path: Routes.onboardingFlow,
      pageBuilder: (context, state) =>
          state.slidePage(const OnboardingFlowScreen()),
    ),
    GoRoute(
      path: Routes.main,
      pageBuilder: (context, state) => state.slidePage(const BottomNavScreen()),
    ),
    GoRoute(
      path: Routes.accountInformation,
      pageBuilder: (context, state) {
        final profile = state.extra as Profile;
        return state.slidePage(AccountInfoScreen(originalProfile: profile));
      },
    ),
    GoRoute(
      path: Routes.appearances,
      pageBuilder: (context, state) =>
          state.slidePage(const AppearancesScreen()),
    ),
    GoRoute(
      path: Routes.languages,
      pageBuilder: (context, state) => state.slidePage(const LanguagesScreen()),
    ),
    GoRoute(
      path: Routes.premium,
      pageBuilder: (context, state) =>
          state.slidePage(const PremiumScreen(), direction: SlideDirection.up),
    ),
    GoRoute(
      path: Routes.waitlist,
      pageBuilder: (context, state) => state.slidePage(const WaitlistScreen()),
    ),
  ],
);
