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
import 'widgets/welcome_first_moment_screen.dart';
import 'widgets/connect_friends_screen.dart';
import 'widgets/contacts_permission_screen.dart';
import 'widgets/friends_list_screen.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize onboarding state from auth response only once
    if (!_initialized) {
      _initialized = true;
      _initializeOnboarding();
    }
  }

  Future<void> _initializeOnboarding() async {
    debugPrint(
      '${Constants.tag} [OnboardingFlowScreen] Initializing onboarding from auth response',
    );

    final authRepo = ref.read(authenticationRepositoryProvider);
    final authResponse = await authRepo.getAuthResponse();

    if (authResponse != null) {
      debugPrint(
        '${Constants.tag} [OnboardingFlowScreen] Auth response found, initializing view model',
      );
      await ref
          .read(onboardingViewModelProvider.notifier)
          .initializeFromAuthResponse(authResponse);
    } else {
      debugPrint(
        '${Constants.tag} [OnboardingFlowScreen] No auth response found, starting from beginning',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
      case OnboardingStep.welcomeFirstMoment:
        return const WelcomeFirstMomentScreen();
      case OnboardingStep.connectFriends:
        return const ConnectFriendsScreen();
      case OnboardingStep.contactsPermission:
        return const ContactsPermissionScreen();
      case OnboardingStep.friendsList:
        return const FriendsListScreen();
      case OnboardingStep.completed:
        // Show loading indicator while navigating
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
