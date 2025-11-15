import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/constants.dart';
import '../model/invite_code_validate_request.dart';
import '../model/invite_code_validate_response.dart';
import '../service/invite_code_service.dart';

part 'invite_code_repository.g.dart';

@riverpod
InviteCodeRepository inviteCodeRepository(Ref ref) {
  final inviteCodeService = ref.watch(inviteCodeServiceProvider);
  return InviteCodeRepository(inviteCodeService);
}

class InviteCodeRepository {
  final InviteCodeService _inviteCodeService;

  const InviteCodeRepository(this._inviteCodeService);

  /// Validate invite code
  /// Calls the /invite-codes/validate endpoint
  Future<InviteCodeValidateResponse> validateInviteCode(String code) async {
    try {
      debugPrint(
        '${Constants.tag} [InviteCodeRepository] 🔄 Validating invite code: $code',
      );

      final request = InviteCodeValidateRequest(code: code);
      final response = await _inviteCodeService.validateInviteCode(request);

      debugPrint(
        '${Constants.tag} [InviteCodeRepository] 📦 Response received',
      );
      debugPrint(
        '${Constants.tag} [InviteCodeRepository] Success: ${response.success}',
      );
      debugPrint(
        '${Constants.tag} [InviteCodeRepository] Valid: ${response.data?.valid}',
      );
      debugPrint(
        '${Constants.tag} [InviteCodeRepository] Type: ${response.data?.type}',
      );
      debugPrint(
        '${Constants.tag} [InviteCodeRepository] Request ID: ${response.meta.requestId}',
      );

      return response;
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [InviteCodeRepository] ❌ EXCEPTION CAUGHT ❌',
      );
      debugPrint(
        '${Constants.tag} [InviteCodeRepository] Error Type: ${error.runtimeType}',
      );
      debugPrint(
        '${Constants.tag} [InviteCodeRepository] Error Details: $error',
      );
      debugPrint('${Constants.tag} [InviteCodeRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}
