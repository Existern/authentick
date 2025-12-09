enum OnboardingStep {
  intro,
  inviteCode,
  birthday,
  username,
  profilePicture,
  connectFriends,
  contactsPermission,
  friendsList,
  welcomeFirstMoment,
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
  final bool hasCapturedFirstMoment;
  final String? firstPostMediaUrl;
  final String? firstPostLocation;
  final String? firstPostTime;
  final Set<String> completedSteps; // API step names that are completed

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
    this.hasCapturedFirstMoment = false,
    this.firstPostMediaUrl,
    this.firstPostLocation,
    this.firstPostTime,
    this.completedSteps = const {},
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
    bool? hasCapturedFirstMoment,
    Object? firstPostMediaUrl = _undefined,
    Object? firstPostLocation = _undefined,
    Object? firstPostTime = _undefined,
    Set<String>? completedSteps,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      introPageIndex: introPageIndex ?? this.introPageIndex,
      inviteCode: inviteCode ?? this.inviteCode,
      birthday: birthday ?? this.birthday,
      username: username ?? this.username,
      firstName: firstName == _undefined
          ? this.firstName
          : firstName as String?,
      profilePicturePath: profilePicturePath == _undefined
          ? this.profilePicturePath
          : profilePicturePath as String?,
      selectedAccountType: selectedAccountType ?? this.selectedAccountType,
      isLoading: isLoading ?? this.isLoading,
      error: error == _undefined ? this.error : error as String?,
      hasContactsPermission:
          hasContactsPermission ?? this.hasContactsPermission,
      hasCapturedFirstMoment:
          hasCapturedFirstMoment ?? this.hasCapturedFirstMoment,
      firstPostMediaUrl: firstPostMediaUrl == _undefined
          ? this.firstPostMediaUrl
          : firstPostMediaUrl as String?,
      firstPostLocation: firstPostLocation == _undefined
          ? this.firstPostLocation
          : firstPostLocation as String?,
      firstPostTime: firstPostTime == _undefined
          ? this.firstPostTime
          : firstPostTime as String?,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }
}

// Sentinel value to distinguish between "not provided" and "explicitly set to null"
const Object _undefined = Object();
