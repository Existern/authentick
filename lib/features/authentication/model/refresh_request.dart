// Refresh token request model for /auth/refresh endpoint
class RefreshRequest {
  final String refreshToken;

  RefreshRequest({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'refresh_token': refreshToken,
    };
  }
}
