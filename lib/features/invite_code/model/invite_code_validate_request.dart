// Invite code validation request model for /invite-codes/validate endpoint
class InviteCodeValidateRequest {
  final String code;

  InviteCodeValidateRequest({
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
    };
  }
}
