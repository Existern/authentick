import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/onboarding_state.dart';

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

  void submitUsername() {
    final currentState = state;
    if (currentState.username.isEmpty) {
      state = currentState.copyWith(error: 'Please enter a username');
      return;
    }

    state = currentState.copyWith(currentStep: OnboardingStep.googleAuth);
  }

  void completeOnboarding() {
    final currentState = state;
    state = currentState.copyWith(currentStep: OnboardingStep.completed);
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
      case OnboardingStep.googleAuth:
        state = currentState.copyWith(currentStep: OnboardingStep.username);
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
