import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/onboarding_step_request.dart';
import '../model/onboarding_step_response.dart';

part 'onboarding_service.g.dart';

@riverpod
OnboardingService onboardingService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingService(apiClient);
}

class OnboardingService {
  final ApiClient _apiClient;

  OnboardingService(this._apiClient);

  /// Update an onboarding step (skip or complete)
  /// POST /users/onboarding/step
  Future<OnboardingStepResponse> updateOnboardingStep(
    OnboardingStepRequest request,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/users/onboarding/step',
        data: request.toJson(),
      );
      return OnboardingStepResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get onboarding progress for the current authenticated user
  /// GET /users/onboarding
  Future<OnboardingStepResponse> getOnboardingProgress() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/users/onboarding',
      );
      return OnboardingStepResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
