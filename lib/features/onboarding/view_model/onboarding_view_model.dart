import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/constants.dart';
import '../../authentication/repository/authentication_repository.dart';
import '../../authentication/model/auth_response.dart' as auth;
import '../../profile/repository/profile_repository.dart';
import '../model/onboarding_state.dart';
import '../model/onboarding_step_request.dart';
import '../service/contacts_permission_service.dart';
import '../service/contacts_service.dart';
import '../service/onboarding_service.dart';

import 'package:intl/intl.dart';
import '../../post/service/post_service.dart';

part 'onboarding_view_model.g.dart';

@riverpod
class OnboardingViewModel extends _$OnboardingViewModel {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  /// Initialize onboarding from auth response
  /// Filters out completed steps and starts from the first incomplete step
  Future<void> initializeFromAuthResponse(
    auth.AuthResponse authResponse,
  ) async {
    final onboarding = authResponse.data.onboarding;

    if (onboarding == null) {
      // No onboarding data, start from beginning
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] No onboarding data, starting from intro',
      );
      state = const OnboardingState();
      await _saveCurrentStep(OnboardingStep.intro);
      return;
    }

    debugPrint(
      '${Constants.tag} [OnboardingViewModel] ========================================',
    );
    debugPrint(
      '${Constants.tag} [OnboardingViewModel] Onboarding API completed flag: ${onboarding.completed}',
    );
    debugPrint(
      '${Constants.tag} [OnboardingViewModel] Total steps in API: ${onboarding.steps.length}',
    );

    // Log all steps with their status
    for (final step in onboarding.steps) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel]   - ${step.step}: ${step.status} (skippable: ${step.skippable})',
      );
    }

    // CRITICAL: If API says onboarding is completed, trust it regardless of individual step status
    if (onboarding.completed) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] ⚠️ API marked onboarding as COMPLETED, but checking steps...',
      );
    }

    // Extract completed step names from API response
    final completedSteps = onboarding.steps
        .where((step) => step.status == 'completed')
        .map((step) => step.step)
        .toSet();

    debugPrint(
      '${Constants.tag} [OnboardingViewModel] Completed steps: $completedSteps',
    );
    debugPrint(
      '${Constants.tag} [OnboardingViewModel] Completed count: ${completedSteps.length}/${onboarding.steps.length}',
    );

    // Check if there's a saved current step (from last session)
    final authRepo = ref.read(authenticationRepositoryProvider);
    final savedStepName = await authRepo.getCurrentOnboardingStep();
    debugPrint(
      '${Constants.tag} [OnboardingViewModel] Saved step from storage: $savedStepName',
    );

    OnboardingStep? targetStep;

    if (savedStepName != null) {
      // Try to map saved step to enum
      targetStep = _mapApiStepToLocal(savedStepName);
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] Mapped saved step: $savedStepName -> $targetStep',
      );

      if (targetStep == null) {
        debugPrint(
          '${Constants.tag} [OnboardingViewModel] ⚠️ WARNING: Saved step "$savedStepName" could not be mapped to local enum!',
        );
      }
    }

    // If no saved step or invalid, find the first incomplete step from API
    if (targetStep == null) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] No valid saved step, finding first incomplete step from API...',
      );
      targetStep = _findFirstIncompleteStep(onboarding.steps);
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] First incomplete step from API: $targetStep',
      );
    }

    if (targetStep != null) {
      // There are incomplete steps, show them
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] ✅ Setting current step to: $targetStep',
      );

      // Restore share moment state if needed
      if (targetStep == OnboardingStep.shareFirstMoment) {
        await _restoreShareMomentState();
      }

      state = state.copyWith(
        currentStep: targetStep,
        completedSteps: completedSteps,
      );
      await _saveCurrentStep(targetStep);
    } else {
      // All steps are completed, mark onboarding as complete
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] ❌ No target step found - marking onboarding as COMPLETED',
      );
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] This will trigger navigation to main app',
      );
      state = state.copyWith(
        currentStep: OnboardingStep.completed,
        completedSteps: completedSteps,
      );
      await authRepo.clearCurrentOnboardingStep();
    }
    debugPrint(
      '${Constants.tag} [OnboardingViewModel] ========================================',
    );
  }

  Future<void> _restoreShareMomentState() async {
    try {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] Restoring share moment state...',
      );
      final authRepo = ref.read(authenticationRepositoryProvider);
      final user = await authRepo.getUserData();

      if (user == null) {
        debugPrint(
          '${Constants.tag} [OnboardingViewModel] ❌ No user data found',
        );
        return;
      }

      final postService = ref.read(postServiceProvider);
      final response = await postService.getUserPosts(
        userId: user.id,
        limit: 1,
      );

      if (response.success && response.data.posts.isNotEmpty) {
        final post = response.data.posts.first;
        final mediaUrl = post.media?.firstOrNull?.mediaUrl;

        if (mediaUrl != null) {
          debugPrint(
            '${Constants.tag} [OnboardingViewModel] ✅ Restored post data',
          );

          String? formattedTime;
          try {
            final createdAtUtc = DateTime.parse(post.createdAt);
            final createdAtLocal = createdAtUtc.toLocal();
            formattedTime = DateFormat('h:mm a').format(createdAtLocal);
          } catch (e) {
            formattedTime = null;
          }

          state = state.copyWith(
            firstPostMediaUrl: mediaUrl,
            firstPostLocation: post.metadata?.location,
            firstPostTime: formattedTime,
          );
        }
      }
    } catch (e) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] ❌ Error restoring share moment state: $e',
      );
    }
  }

  /// Find the first step that is not completed
  /// Steps with 'skipped', 'pending', or any other status should be shown
  OnboardingStep? _findFirstIncompleteStep(List<auth.OnboardingStep> apiSteps) {
    for (final apiStep in apiSteps) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] Step: ${apiStep.step}, Status: ${apiStep.status}',
      );

      // Only skip completed steps - show everything else (skipped, pending, etc.)
      if (apiStep.status == 'completed') {
        continue;
      }

      // Map API step name to local OnboardingStep enum
      final localStep = _mapApiStepToLocal(apiStep.step);
      if (localStep != null) {
        return localStep;
      }
    }

    return null;
  }

  /// Map API step names to local OnboardingStep enum
  OnboardingStep? _mapApiStepToLocal(String apiStepName) {
    switch (apiStepName) {
      case 'invite_code_verified':
        return OnboardingStep.inviteCode;
      case 'date_of_birth_added':
        return OnboardingStep.birthday;
      case 'username_set':
        return OnboardingStep.username;
      case 'profile_picture':
        return OnboardingStep.profilePicture;
      case 'find_friends':
        return OnboardingStep.connectFriends;
      case 'capture_first_moment':
        return OnboardingStep.welcomeFirstMoment;
      case 'share_first_moment':
        return OnboardingStep.shareFirstMoment;
      default:
        debugPrint(
          '${Constants.tag} [OnboardingViewModel] Unknown API step: $apiStepName',
        );
        return null;
    }
  }

  /// Map local OnboardingStep enum to API step names
  String? _mapLocalStepToApi(OnboardingStep localStep) {
    switch (localStep) {
      case OnboardingStep.intro:
        return 'intro'; // Local step for intro pages
      case OnboardingStep.inviteCode:
        return 'invite_code_verified';
      case OnboardingStep.birthday:
        return 'date_of_birth_added';
      case OnboardingStep.username:
        return 'username_set';
      case OnboardingStep.profilePicture:
        return 'profile_picture';
      case OnboardingStep.connectFriends:
      case OnboardingStep.contactsPermission:
      case OnboardingStep.friendsList:
        return 'find_friends'; // All friend-related steps map to find_friends
      case OnboardingStep.welcomeFirstMoment:
        return 'capture_first_moment';
      case OnboardingStep.shareFirstMoment:
        return 'share_first_moment';
      default:
        return null;
    }
  }

  /// Save the current onboarding step to persistent storage
  Future<void> _saveCurrentStep(OnboardingStep step) async {
    final apiStepName = _mapLocalStepToApi(step);
    if (apiStepName != null) {
      final authRepo = ref.read(authenticationRepositoryProvider);
      await authRepo.saveCurrentOnboardingStep(apiStepName);
    }
  }

  /// Get the next step after the target step, skipping completed steps
  OnboardingStep _getNextStep(OnboardingStep targetStep) {
    // Define the normal flow order
    const stepOrder = [
      OnboardingStep.intro,
      OnboardingStep.inviteCode,
      OnboardingStep.birthday,
      OnboardingStep.username,
      OnboardingStep.profilePicture,
      OnboardingStep.connectFriends,
      OnboardingStep.contactsPermission,
      OnboardingStep.friendsList,
      OnboardingStep.welcomeFirstMoment,
      OnboardingStep.shareFirstMoment,
      OnboardingStep.completed,
    ];

    final currentIndex = stepOrder.indexOf(targetStep);
    if (currentIndex == -1 || currentIndex >= stepOrder.length - 1) {
      return OnboardingStep.completed;
    }

    // Find the next step that is not completed
    for (var i = currentIndex + 1; i < stepOrder.length; i++) {
      final nextStep = stepOrder[i];
      final apiStepName = _mapLocalStepToApi(nextStep);

      // If this step has no API mapping or is not completed, use it
      if (apiStepName == null || !state.completedSteps.contains(apiStepName)) {
        debugPrint(
          '${Constants.tag} [OnboardingViewModel] Next step after $targetStep: $nextStep',
        );
        return nextStep;
      } else {
        debugPrint(
          '${Constants.tag} [OnboardingViewModel] Skipping completed step: $nextStep ($apiStepName)',
        );
      }
    }

    return OnboardingStep.completed;
  }

  Future<void> nextIntroPage() async {
    final currentState = state;
    if (currentState.introPageIndex < 1) {
      state = currentState.copyWith(
        introPageIndex: currentState.introPageIndex + 1,
      );
    } else {
      state = currentState.copyWith(currentStep: OnboardingStep.inviteCode);
      await _saveCurrentStep(OnboardingStep.inviteCode);
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

  Future<void> skipIntro() async {
    state = state.copyWith(currentStep: OnboardingStep.inviteCode);
    await _saveCurrentStep(OnboardingStep.inviteCode);
  }

  void updateInviteCode(String code) {
    state = state.copyWith(inviteCode: code, error: null);
  }

  Future<void> submitInviteCode() async {
    final currentState = state;
    if (currentState.inviteCode.isEmpty) {
      state = currentState.copyWith(error: 'Please enter an invite code');
      return;
    }

    state = currentState.copyWith(currentStep: OnboardingStep.birthday);
    await _saveCurrentStep(OnboardingStep.birthday);
  }

  Future<void> skipInviteCode() async {
    state = state.copyWith(currentStep: OnboardingStep.birthday);
    await _saveCurrentStep(OnboardingStep.birthday);
  }

  void updateBirthday(String birthday) {
    state = state.copyWith(birthday: birthday, error: null);
  }

  Future<void> submitBirthday() async {
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
    await _saveCurrentStep(OnboardingStep.username);
  }

  void updateUsername(String username) {
    state = state.copyWith(username: username, error: null);
  }

  void updateFirstName(String firstName) {
    state = state.copyWith(firstName: firstName);
  }

  Future<void> submitUsername() async {
    final currentState = state;
    if (currentState.username.isEmpty) {
      state = currentState.copyWith(error: 'Please enter a username');
      return;
    }

    // Set loading state
    state = currentState.copyWith(isLoading: true, error: null);

    try {
      // Call the profile update API with username and dateOfBirth
      final profileRepository = ref.read(profileRepositoryProvider);

      debugPrint('${Constants.tag} ========================================');
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] 🚀 Updating profile...',
      );
      debugPrint('${Constants.tag} Username: ${currentState.username}');
      debugPrint(
        '${Constants.tag} First Name: ${currentState.firstName ?? "NOT PROVIDED"}',
      );
      debugPrint(
        '${Constants.tag} Birthday: ${currentState.birthday.isEmpty ? "NOT PROVIDED" : currentState.birthday}',
      );
      debugPrint('${Constants.tag} ========================================');

      final response = await profileRepository.updateProfile(
        username: currentState.username,
        firstName: currentState.firstName,
        dateOfBirth: currentState.birthday.isEmpty
            ? null
            : currentState.birthday,
      );

      if (response.success) {
        debugPrint('${Constants.tag} ========================================');
        debugPrint(
          '${Constants.tag} [OnboardingViewModel] ✅ Profile updated successfully!',
        );
        debugPrint('${Constants.tag} Username: ${response.data.username}');
        debugPrint('${Constants.tag} ========================================');

        // Navigate to profile picture step
        state = currentState.copyWith(
          currentStep: OnboardingStep.profilePicture,
          isLoading: false,
        );
        await _saveCurrentStep(OnboardingStep.profilePicture);
      } else {
        debugPrint(
          '${Constants.tag} [OnboardingViewModel] ❌ Profile update failed: API returned success=false',
        );
        state = currentState.copyWith(
          isLoading: false,
          error: 'Failed to update profile. Please try again.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} ========================================');
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] ❌ Profile update FAILED!',
      );
      debugPrint('${Constants.tag} Error Type: ${error.runtimeType}');
      debugPrint('${Constants.tag} Error Message: $error');
      debugPrint('${Constants.tag} Stack Trace:');
      debugPrint('$stackTrace');
      debugPrint('${Constants.tag} ========================================');

      // Show error message
      state = currentState.copyWith(
        isLoading: false,
        error: 'Failed to update profile. Please try again.',
      );
    }
  }

  Future<void> completeOnboarding() async {
    final currentState = state;
    state = currentState.copyWith(currentStep: OnboardingStep.completed);
    final authRepo = ref.read(authenticationRepositoryProvider);
    await authRepo.clearCurrentOnboardingStep();
  }

  Future<void> snapProfilePicture() async {
    // Mark as completed locally
    final updatedCompletedSteps = Set<String>.from(state.completedSteps)
      ..add('profile_picture');

    // Update state with completedSteps FIRST
    state = state.copyWith(completedSteps: updatedCompletedSteps);

    // Now _getNextStep will use the updated completedSteps
    final nextStep = _getNextStep(OnboardingStep.profilePicture);
    state = state.copyWith(currentStep: nextStep);
    await _saveCurrentStep(nextStep);
  }

  Future<void> skipProfilePicture() async {
    try {
      final service = ref.read(onboardingServiceProvider);
      await service.updateOnboardingStep(
        OnboardingStepRequest(step: 'profile_picture'),
      );
    } catch (e) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] Error skipping profile picture: $e',
      );
      // Continue anyway - don't block user flow
    }

    // Mark as completed locally so future navigation skips it
    final updatedCompletedSteps = Set<String>.from(state.completedSteps)
      ..add('profile_picture');

    // Update state with completedSteps FIRST
    state = state.copyWith(completedSteps: updatedCompletedSteps);

    // Now _getNextStep will use the updated completedSteps
    final nextStep = _getNextStep(OnboardingStep.profilePicture);
    state = state.copyWith(currentStep: nextStep);
    await _saveCurrentStep(nextStep);
  }

  Future<void> captureFirstMoment() async {
    // Mark that user captured their first moment
    // Navigate to share screen (normal flow, not skip-completed logic)
    state = state.copyWith(
      hasCapturedFirstMoment: true,
      currentStep: OnboardingStep.shareFirstMoment,
    );
    await _saveCurrentStep(OnboardingStep.shareFirstMoment);
  }

  Future<void> skipFirstMoment() async {
    final service = ref.read(onboardingServiceProvider);

    // Skip capture_first_moment
    try {
      await service.updateOnboardingStep(
        OnboardingStepRequest(step: 'capture_first_moment'),
      );
    } catch (e) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] Error skipping capture first moment: $e',
      );
      // Continue anyway - don't block user flow
    }

    // Also skip share_first_moment since user can't share without capturing
    try {
      await service.updateOnboardingStep(
        OnboardingStepRequest(step: 'share_first_moment'),
      );
    } catch (e) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] Error skipping share first moment: $e',
      );
      // Continue anyway - don't block user flow
    }

    // Mark both as completed locally so future navigation skips them
    final updatedCompletedSteps = Set<String>.from(state.completedSteps)
      ..add('capture_first_moment')
      ..add('share_first_moment');

    // Update state with completedSteps FIRST
    state = state.copyWith(
      completedSteps: updatedCompletedSteps,
      hasCapturedFirstMoment: false,
    );

    // Now _getNextStep will use the updated completedSteps
    final nextStep = _getNextStep(OnboardingStep.shareFirstMoment);
    state = state.copyWith(currentStep: nextStep);
    await _saveCurrentStep(nextStep);
  }

  Future<void> completeShareMoment() async {
    try {
      final service = ref.read(onboardingServiceProvider);
      await service.updateOnboardingStep(
        OnboardingStepRequest(step: 'share_first_moment', action: 'complete'),
      );
    } catch (e) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] Error completing share moment: $e',
      );
      // Continue anyway - don't block user flow
    }

    // Mark as completed locally
    final updatedCompletedSteps = Set<String>.from(state.completedSteps)
      ..add('share_first_moment');

    // Update state with completedSteps FIRST
    state = state.copyWith(completedSteps: updatedCompletedSteps);

    // Now _getNextStep will use the updated completedSteps
    final nextStep = _getNextStep(OnboardingStep.shareFirstMoment);
    state = state.copyWith(currentStep: nextStep);
    await _saveCurrentStep(nextStep);
  }

  Future<void> skipShareMoment() async {
    try {
      final service = ref.read(onboardingServiceProvider);
      await service.updateOnboardingStep(
        OnboardingStepRequest(step: 'share_first_moment'),
      );
    } catch (e) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] Error skipping share moment: $e',
      );
      // Continue anyway - don't block user flow
    }

    // Mark as completed locally so future navigation skips it
    final updatedCompletedSteps = Set<String>.from(state.completedSteps)
      ..add('share_first_moment');

    // Update state with completedSteps FIRST
    state = state.copyWith(completedSteps: updatedCompletedSteps);

    // Now _getNextStep will use the updated completedSteps
    final nextStep = _getNextStep(OnboardingStep.shareFirstMoment);
    state = state.copyWith(currentStep: nextStep);
    await _saveCurrentStep(nextStep);
  }

  Future<void> findFriends() async {
    // Navigate to contacts permission screen first (sub-flow entry, not completion)
    state = state.copyWith(currentStep: OnboardingStep.contactsPermission);
    await _saveCurrentStep(OnboardingStep.contactsPermission);
  }

  Future<void> allowContactsPermission() async {
    debugPrint(
      '${Constants.tag} [OnboardingViewModel] 🚀 allowContactsPermission() called',
    );

    // Debug permission states
    await ContactsPermissionService.debugPermissionStates();

    // Set loading state
    state = state.copyWith(isLoading: true);

    try {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] 📋 Requesting contacts permission from system...',
      );

      // Request contacts permission from the system
      final granted =
          await ContactsPermissionService.requestContactsPermission();

      debugPrint(
        '${Constants.tag} [OnboardingViewModel] 🔐 Permission result: $granted',
      );

      if (granted) {
        debugPrint(
          '${Constants.tag} [OnboardingViewModel] ✅ Contacts permission granted, fetching contacts...',
        );

        // Fetch all contacts with emails
        final contactsWithEmails =
            await ContactsService.getAllContactsWithEmails();

        debugPrint(
          '${Constants.tag} [OnboardingViewModel] 📱 Fetched ${contactsWithEmails.length} contacts',
        );

        // Print contacts for debugging
        ContactsService.printAllContactsWithEmails(contactsWithEmails);

        // Permission granted, show friends list (sub-flow continuation, not completion)
        state = state.copyWith(
          currentStep: OnboardingStep.friendsList,
          hasContactsPermission: true,
          isLoading: false,
        );
        await _saveCurrentStep(OnboardingStep.friendsList);

        debugPrint(
          '${Constants.tag} [OnboardingViewModel] 🎯 Navigated to friends list screen',
        );
      } else {
        debugPrint(
          '${Constants.tag} [OnboardingViewModel] ❌ Contacts permission denied',
        );
        // Permission denied, skip entire find_friends flow to next incomplete step
        final nextStep = _getNextStep(OnboardingStep.friendsList);
        state = state.copyWith(
          currentStep: nextStep,
          hasContactsPermission: false,
          isLoading: false,
        );
        await _saveCurrentStep(nextStep);

        debugPrint(
          '${Constants.tag} [OnboardingViewModel] ⏭️ Skipped to next step: $nextStep',
        );
      }
    } catch (error) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] ❗ Error requesting contacts permission: $error',
      );
      // On error, skip entire find_friends flow to next incomplete step
      final nextStep = _getNextStep(OnboardingStep.friendsList);
      state = state.copyWith(
        currentStep: nextStep,
        hasContactsPermission: false,
        isLoading: false,
        error: 'Failed to request permission',
      );
      await _saveCurrentStep(nextStep);
    }
  }

  Future<void> skipContactsPermission() async {
    // User declined contacts permission, skip entire find_friends flow
    final updatedCompletedSteps = Set<String>.from(state.completedSteps)
      ..add('find_friends');

    // Update state with completedSteps FIRST
    state = state.copyWith(
      completedSteps: updatedCompletedSteps,
      hasContactsPermission: false,
    );

    // Now _getNextStep will use the updated completedSteps
    final nextStep = _getNextStep(OnboardingStep.friendsList);
    state = state.copyWith(currentStep: nextStep);
    await _saveCurrentStep(nextStep);
  }

  Future<void> completeFriendsFlow() async {
    // Complete the friends flow and get next step
    final updatedCompletedSteps = Set<String>.from(state.completedSteps)
      ..add('find_friends');

    // Update state with completedSteps FIRST
    state = state.copyWith(completedSteps: updatedCompletedSteps);

    // Now _getNextStep will use the updated completedSteps
    final nextStep = _getNextStep(OnboardingStep.friendsList);
    state = state.copyWith(currentStep: nextStep);
    await _saveCurrentStep(nextStep);
  }

  Future<void> skipConnectFriends() async {
    try {
      final service = ref.read(onboardingServiceProvider);
      await service.updateOnboardingStep(
        OnboardingStepRequest(step: 'find_friends'),
      );
    } catch (e) {
      debugPrint(
        '${Constants.tag} [OnboardingViewModel] Error skipping find friends: $e',
      );
      // Continue anyway - don't block user flow
    }

    // Mark as completed locally so _getNextStep skips all friend-related screens
    // (contactsPermission and friendsList also map to 'find_friends')
    final updatedCompletedSteps = Set<String>.from(state.completedSteps)
      ..add('find_friends');

    debugPrint(
      '${Constants.tag} [OnboardingViewModel] Skipped find_friends, updated completedSteps: $updatedCompletedSteps',
    );

    // IMPORTANT: Update state with completedSteps FIRST
    state = state.copyWith(completedSteps: updatedCompletedSteps);

    // Now _getNextStep will use the updated completedSteps
    final nextStep = _getNextStep(OnboardingStep.connectFriends);
    state = state.copyWith(currentStep: nextStep);
    await _saveCurrentStep(nextStep);
  }

  void updateProfilePicture(String? path) {
    state = state.copyWith(profilePicturePath: path);
  }

  void updateFirstPostData({String? mediaUrl, String? location, String? time}) {
    state = state.copyWith(
      firstPostMediaUrl: mediaUrl,
      firstPostLocation: location,
      firstPostTime: time,
    );
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
        state = currentState.copyWith(
          currentStep: OnboardingStep.profilePicture,
        );
        break;
      case OnboardingStep.contactsPermission:
        state = currentState.copyWith(
          currentStep: OnboardingStep.connectFriends,
        );
        break;
      case OnboardingStep.friendsList:
        state = currentState.copyWith(
          currentStep: OnboardingStep.contactsPermission,
        );
        break;
      case OnboardingStep.welcomeFirstMoment:
        state = currentState.copyWith(currentStep: OnboardingStep.friendsList);
        break;
      case OnboardingStep.shareFirstMoment:
        state = currentState.copyWith(
          currentStep: OnboardingStep.welcomeFirstMoment,
        );
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
