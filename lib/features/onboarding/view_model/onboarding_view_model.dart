import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/constants.dart';
// import '../../authentication/repository/authentication_repository.dart'; // Commented out for development
import '../model/onboarding_state.dart';
import '../service/contacts_permission_service.dart';

part 'onboarding_view_model.g.dart';

@riverpod
class OnboardingViewModel extends _$OnboardingViewModel {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  void nextIntroPage() {
    final currentState = state;
    if (currentState.introPageIndex < 1) {
      state = currentState.copyWith(
        introPageIndex: currentState.introPageIndex + 1,
      );
    } else {
      state = currentState.copyWith(currentStep: OnboardingStep.inviteCode);
    }
  }

  void previousIntroPage() {
    final currentState = state;
    if (currentState.introPageIndex > 0) {
      state = currentState.copyWith(
        introPageIndex: currentState.introPageIndex - 1,
      );
    }
  }

  void setIntroPage(int index) {
    state = state.copyWith(introPageIndex: index);
  }

  void skipIntro() {
    state = state.copyWith(currentStep: OnboardingStep.inviteCode);
  }

  void updateInviteCode(String code) {
    state = state.copyWith(inviteCode: code, error: null);
  }

  void submitInviteCode() {
    final currentState = state;
    if (currentState.inviteCode.isEmpty) {
      state = currentState.copyWith(error: 'Please enter an invite code');
      return;
    }

    state = currentState.copyWith(currentStep: OnboardingStep.birthday);
  }

  void skipInviteCode() {
    state = state.copyWith(currentStep: OnboardingStep.birthday);
  }

  void updateBirthday(String birthday) {
    state = state.copyWith(birthday: birthday, error: null);
  }

  void submitBirthday() {
    final currentState = state;
    if (currentState.birthday.isEmpty) {
      state = currentState.copyWith(error: 'Please enter your birthday');
      return;
    }

    // Basic validation for DD MM YYYY format (8 digits)
    if (currentState.birthday.length < 8) {
      state = currentState.copyWith(error: 'Please enter a valid date');
      return;
    }

    state = currentState.copyWith(currentStep: OnboardingStep.username);
  }

  void updateUsername(String username) {
    state = state.copyWith(username: username, error: null);
  }

  Future<void> submitUsername() async {
    final currentState = state;
    if (currentState.username.isEmpty) {
      state = currentState.copyWith(error: 'Please enter a username');
      return;
    }

    // Set loading state
    state = currentState.copyWith(isLoading: true, error: null);

    // TODO: Commented out for development - uncomment when backend is ready
    // try {
    //   // Call the authentication API
    //   final authRepository = ref.read(authenticationRepositoryProvider);

    //   debugPrint('${Constants.tag} ========================================');
    //   debugPrint('${Constants.tag} [OnboardingViewModel] 🚀 Starting Authentication...');
    //   debugPrint('${Constants.tag} Username: ${currentState.username}');
    //   debugPrint('${Constants.tag} Birthday: ${currentState.birthday.isEmpty ? "NOT PROVIDED" : currentState.birthday}');
    //   debugPrint('${Constants.tag} InviteCode: ${currentState.inviteCode.isEmpty ? "NOT PROVIDED" : currentState.inviteCode}');
    //   debugPrint('${Constants.tag} ========================================');

    //   final response = await authRepository.authenticate(
    //     username: currentState.username,
    //     dateOfBirth: currentState.birthday.isEmpty ? null : currentState.birthday,
    //     inviteCode: currentState.inviteCode.isEmpty ? null : currentState.inviteCode,
    //   );

    //   debugPrint('${Constants.tag} ========================================');
    //   debugPrint('${Constants.tag} [OnboardingViewModel] ✅ Authentication successful!');
    //   debugPrint('${Constants.tag} User ID: ${response.data.user.id}');
    //   debugPrint('${Constants.tag} Username: ${response.data.user.username}');
    //   debugPrint('${Constants.tag} Token received: ${response.data.token.substring(0, 20)}...');
    //   debugPrint('${Constants.tag} ========================================');

    //   // Navigate to profile picture step
    //   state = currentState.copyWith(
    //     currentStep: OnboardingStep.profilePicture,
    //     isLoading: false,
    //   );
    // } catch (error, stackTrace) {
    //   debugPrint('${Constants.tag} ========================================');
    //   debugPrint('${Constants.tag} [OnboardingViewModel] ❌ Authentication FAILED!');
    //   debugPrint('${Constants.tag} Error Type: ${error.runtimeType}');
    //   debugPrint('${Constants.tag} Error Message: $error');
    //   debugPrint('${Constants.tag} Stack Trace:');
    //   debugPrint('$stackTrace');
    //   debugPrint('${Constants.tag} ========================================');

    //   // Show error message
    //   state = currentState.copyWith(
    //     isLoading: false,
    //     error: 'Failed to authenticate. Please try again.',
    //   );
    // }

    // Temporary: Skip API call and go directly to profile picture
    debugPrint('${Constants.tag} [OnboardingViewModel] ⚠️ Skipping API call (development mode)');
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    state = currentState.copyWith(
      currentStep: OnboardingStep.profilePicture,
      isLoading: false,
    );
  }

  void completeOnboarding() {
    final currentState = state;
    state = currentState.copyWith(currentStep: OnboardingStep.completed);
  }

  void snapProfilePicture() {
    state = state.copyWith(currentStep: OnboardingStep.connectFriends);
  }

  void skipProfilePicture() {
    state = state.copyWith(currentStep: OnboardingStep.connectFriends);
  }

  void findFriends() {
    // Navigate to contacts permission screen first
    state = state.copyWith(currentStep: OnboardingStep.contactsPermission);
  }

  Future<void> allowContactsPermission() async {
    // Set loading state
    state = state.copyWith(isLoading: true);
    
    try {
      // Request contacts permission from the system
      final granted = await ContactsPermissionService.requestContactsPermission();
      
      if (granted) {
        // Permission granted, show friends list
        state = state.copyWith(
          currentStep: OnboardingStep.friendsList,
          hasContactsPermission: true,
          isLoading: false,
        );
      } else {
        // Permission denied, complete onboarding
        state = state.copyWith(
          currentStep: OnboardingStep.completed,
          hasContactsPermission: false,
          isLoading: false,
        );
      }
    } catch (error) {
      debugPrint('${Constants.tag} [OnboardingViewModel] Error requesting contacts permission: $error');
      // On error, complete onboarding
      state = state.copyWith(
        currentStep: OnboardingStep.completed,
        hasContactsPermission: false,
        isLoading: false,
        error: 'Failed to request permission',
      );
    }
  }

  void skipContactsPermission() {
    // User declined contacts permission, complete onboarding
    state = state.copyWith(
      currentStep: OnboardingStep.completed,
      hasContactsPermission: false,
    );
  }

  void completeFriendsFlow() {
    // Complete the friends flow and onboarding
    state = state.copyWith(currentStep: OnboardingStep.completed);
  }

  void skipConnectFriends() {
    state = state.copyWith(currentStep: OnboardingStep.completed);
  }

  void updateProfilePicture(String? path) {
    state = state.copyWith(profilePicturePath: path);
  }

  void goBack() {
    final currentState = state;
    switch (currentState.currentStep) {
      case OnboardingStep.inviteCode:
        state = currentState.copyWith(currentStep: OnboardingStep.intro);
        break;
      case OnboardingStep.birthday:
        state = currentState.copyWith(currentStep: OnboardingStep.inviteCode);
        break;
      case OnboardingStep.username:
        state = currentState.copyWith(currentStep: OnboardingStep.birthday);
        break;
      case OnboardingStep.profilePicture:
        state = currentState.copyWith(currentStep: OnboardingStep.username);
        break;
      case OnboardingStep.connectFriends:
        state = currentState.copyWith(currentStep: OnboardingStep.profilePicture);
        break;
      case OnboardingStep.contactsPermission:
        state = currentState.copyWith(currentStep: OnboardingStep.connectFriends);
        break;
      case OnboardingStep.friendsList:
        state = currentState.copyWith(currentStep: OnboardingStep.contactsPermission);
        break;
      default:
        break;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void selectAccountType(AccountType accountType) {
    state = state.copyWith(selectedAccountType: accountType);
  }
}
