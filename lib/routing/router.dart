import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../features/authentication/ui/otp_screen.dart';
import '../features/authentication/ui/sign_in_screen.dart';
import '../features/authentication/ui/register_screen.dart';
import '../features/common/service/session_manager.dart';
import '../services/sentry_service.dart';

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
import '../screens/post/post_detail_screen.dart';
import 'routes.dart';

/// Navigation observer for Sentry breadcrumb tracking
class SentryNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    _trackNavigation(route.settings.name, previousRoute?.settings.name, 'push');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _trackNavigation(previousRoute?.settings.name, route.settings.name, 'pop');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _trackNavigation(
      newRoute?.settings.name,
      oldRoute?.settings.name,
      'replace',
    );
  }

  void _trackNavigation(String? current, String? previous, String action) {
    final currentName = current ?? 'unknown';
    final previousName = previous ?? 'unknown';

    SentryService.instance.addBreadcrumb(
      message: 'Navigation $action: $currentName',
      category: 'navigation',
      data: {'action': action, 'from': previousName, 'to': currentName},
    );
  }
}

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
  navigatorKey: SessionManager.navigatorKey,
  observers: [SentryNavigationObserver()],
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
        // Get saved onboarding step
        final currentStep = prefs.getString('current_onboarding_step');

        // Check if user was on waitlist - redirect to waitlist
        if (currentStep == 'waitlist') {
          if (state.matchedLocation != Routes.waitlist) {
            return Routes.waitlist;
          }
          return null; // Allow access to waitlist screen
        }

        // If user is trying to access main or other protected routes, redirect to onboarding
        if (state.matchedLocation == Routes.main ||
            (state.matchedLocation != Routes.onboardingFlow &&
                state.matchedLocation != Routes.waitlist)) {
          // Check if there's a saved step - if so, go to onboarding flow
          // The onboarding flow will restore the saved step
          if (currentStep != null && currentStep != 'waitlist') {
            return Routes.onboardingFlow;
          }
          // No saved step, go to onboarding flow
          return Routes.onboardingFlow;
        }

        // Allow access to onboarding flow and waitlist
        if (state.matchedLocation == Routes.onboardingFlow ||
            state.matchedLocation == Routes.waitlist) {
          return null;
        }

        // Default: redirect to onboarding flow
        return Routes.onboardingFlow;
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
    GoRoute(
      path: Routes.postDetail,
      pageBuilder: (context, state) {
        final postId = state.pathParameters['postId']!;
        return state.slidePage(PostDetailScreen(postId: postId));
      },
    ),
  ],
);
