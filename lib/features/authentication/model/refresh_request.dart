// Refresh token request model for /auth/refresh endpoint
class RefreshRequest {
  final String refreshToken;
  final String? accessToken; // Optional access token for Authorization header

  RefreshRequest({required this.refreshToken, this.accessToken});

  Map<String, dynamic> toJson() {
    return {'refresh_token': refreshToken};
  }
}
