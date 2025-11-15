// Authentication request model for /auth/authenticate endpoint
class AuthRequest {
  final String? googleToken;

  AuthRequest({
    this.googleToken,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // Only include google_token
    if (googleToken != null) data['google_token'] = googleToken;

    return data;
  }
}
