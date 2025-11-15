import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/invite_code_validate_request.dart';
import '../model/invite_code_validate_response.dart';

part 'invite_code_service.g.dart';

@riverpod
InviteCodeService inviteCodeService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InviteCodeService(apiClient);
}

class InviteCodeService {
  final ApiClient _apiClient;

  InviteCodeService(this._apiClient);

  /// Validate invite code
  /// POST /invite-codes/validate
  Future<InviteCodeValidateResponse> validateInviteCode(
    InviteCodeValidateRequest request,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/invite-codes/validate',
        data: request.toJson(),
      );
      return InviteCodeValidateResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
