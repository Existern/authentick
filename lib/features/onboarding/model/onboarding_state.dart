enum OnboardingStep {
  intro,
  inviteCode,
  birthday,
  username,
  profilePicture,
  welcomeFirstMoment,
  connectFriends,
  contactsPermission,
  friendsList,
  completed,
}

enum AccountType { personal, business, creator }

class OnboardingState {
  final OnboardingStep currentStep;
  final int introPageIndex;
  final String inviteCode;
  final String birthday;
  final String username;
  final String? firstName;
  final String? profilePicturePath;
  final AccountType? selectedAccountType;
  final bool isLoading;
  final String? error;
  final bool hasContactsPermission;

  const OnboardingState({
    this.currentStep = OnboardingStep.intro,
    this.introPageIndex = 0,
    this.inviteCode = '',
    this.birthday = '',
    this.username = '',
    this.firstName,
    this.profilePicturePath,
    this.selectedAccountType,
    this.isLoading = false,
    this.error,
    this.hasContactsPermission = false,
  });

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    int? introPageIndex,
    String? inviteCode,
    String? birthday,
    String? username,
    Object? firstName = _undefined,
    Object? profilePicturePath = _undefined,
    AccountType? selectedAccountType,
    bool? isLoading,
    Object? error = _undefined,
    bool? hasContactsPermission,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      introPageIndex: introPageIndex ?? this.introPageIndex,
      inviteCode: inviteCode ?? this.inviteCode,
      birthday: birthday ?? this.birthday,
      username: username ?? this.username,
      firstName: firstName == _undefined ? this.firstName : firstName as String?,
      profilePicturePath: profilePicturePath == _undefined
          ? this.profilePicturePath
          : profilePicturePath as String?,
      selectedAccountType: selectedAccountType ?? this.selectedAccountType,
      isLoading: isLoading ?? this.isLoading,
      error: error == _undefined ? this.error : error as String?,
      hasContactsPermission:
          hasContactsPermission ?? this.hasContactsPermission,
    );
  }
}

// Sentinel value to distinguish between "not provided" and "explicitly set to null"
const Object _undefined = Object();
