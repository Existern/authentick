import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/skip_onboarding_request.dart';
import '../model/skip_onboarding_response.dart';

part 'onboarding_service.g.dart';

@riverpod
OnboardingService onboardingService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingService(apiClient);
}

class OnboardingService {
  final ApiClient _apiClient;

  OnboardingService(this._apiClient);

  /// Skip an onboarding step
  /// POST /users/onboarding/skip
  Future<SkipOnboardingResponse> skipOnboardingStep(
    SkipOnboardingRequest request,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/users/onboarding/skip',
        data: request.toJson(),
      );
      return SkipOnboardingResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
