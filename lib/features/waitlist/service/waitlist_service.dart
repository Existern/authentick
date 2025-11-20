import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/waitlist_request.dart';
import '../model/waitlist_response.dart';

part 'waitlist_service.g.dart';

@riverpod
WaitlistService waitlistService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WaitlistService(apiClient);
}

class WaitlistService {
  final ApiClient _apiClient;

  WaitlistService(this._apiClient);

  /// Join waitlist
  /// POST /waitlist
  Future<WaitlistResponse> joinWaitlist(WaitlistRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/waitlist',
        data: request.toJson(),
      );
      return WaitlistResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
