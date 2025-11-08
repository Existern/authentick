import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/constants.dart';
import '../../../routing/routes.dart';
import '../../authentication/repository/authentication_repository.dart';
import '../../authentication/ui/view_model/authentication_view_model.dart';
import '../model/onboarding_state.dart';
import '../view_model/onboarding_view_model.dart';
import 'widgets/intro_pages_widget.dart';
import 'widgets/invite_code_screen.dart';
import 'widgets/birthday_screen.dart';
import 'widgets/username_screen.dart';
import 'widgets/profile_picture_screen.dart';
import 'widgets/connect_friends_screen.dart';
import 'widgets/contacts_permission_screen.dart';
import 'widgets/friends_list_screen.dart';

class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);

    // Listen to authentication state for Google sign-in
    ref.listen(authenticationViewModelProvider, (previous, next) {
      debugPrint(
        '${Constants.tag} [OnboardingFlowScreen] Auth state changed: $next',
      );

      if (next is AsyncData) {
        final value = next.value;
        debugPrint(
          '${Constants.tag} [OnboardingFlowScreen] isSignInSuccessfully: ${value?.isSignInSuccessfully}',
        );
        debugPrint(
          '${Constants.tag} [OnboardingFlowScreen] authResponse: ${value?.authResponse}',
        );

        if (value?.isSignInSuccessfully == true) {
          // User signed in with Google, mark onboarding complete and go to main app
          debugPrint(
            '${Constants.tag} [OnboardingFlowScreen] Navigating to main app',
          );
          ref
              .read(authenticationRepositoryProvider)
              .setHasCompletedOnboarding(true);
          context.pushReplacement(Routes.main);
        }
      } else if (next is AsyncError) {
        debugPrint(
          '${Constants.tag} [OnboardingFlowScreen] Auth error: ${next.error}',
        );
      }
    });

    // Handle completion (for users who skip Google sign-in)
    ref.listen<OnboardingState>(onboardingViewModelProvider, (previous, next) {
      if (next.currentStep == OnboardingStep.completed) {
        // Navigate to main screen immediately
        ref
            .read(authenticationRepositoryProvider)
            .setHasCompletedOnboarding(true);
        context.go(Routes.main);
      }
    });

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentScreen(state.currentStep),
      ),
    );
  }

  Widget _buildCurrentScreen(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.intro:
        return const IntroPagesWidget();
      case OnboardingStep.inviteCode:
        return const InviteCodeScreen();
      case OnboardingStep.birthday:
        return const BirthdayScreen();
      case OnboardingStep.username:
        return const UsernameScreen();
      case OnboardingStep.profilePicture:
        return const ProfilePictureScreen();
      case OnboardingStep.connectFriends:
        return const ConnectFriendsScreen();
      case OnboardingStep.contactsPermission:
        return const ContactsPermissionScreen();
      case OnboardingStep.friendsList:
        return const FriendsListScreen();
      case OnboardingStep.completed:
        // Show loading indicator while navigating
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
}
