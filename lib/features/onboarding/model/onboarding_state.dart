enum OnboardingStep {
  intro,
  inviteCode,
  birthday,
  username,
  completed,
}

enum AccountType {
  personal,
  business,
  creator,
}

class OnboardingState {
  final OnboardingStep currentStep;
  final int introPageIndex;
  final String inviteCode;
  final String birthday;
  final String username;
  final AccountType? selectedAccountType;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.currentStep = OnboardingStep.intro,
    this.introPageIndex = 0,
    this.inviteCode = '',
    this.birthday = '',
    this.username = '',
    this.selectedAccountType,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    int? introPageIndex,
    String? inviteCode,
    String? birthday,
    String? username,
    AccountType? selectedAccountType,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      introPageIndex: introPageIndex ?? this.introPageIndex,
      inviteCode: inviteCode ?? this.inviteCode,
      birthday: birthday ?? this.birthday,
      username: username ?? this.username,
      selectedAccountType: selectedAccountType ?? this.selectedAccountType,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
