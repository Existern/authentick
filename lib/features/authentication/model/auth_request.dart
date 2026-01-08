// Authentication request model for /auth/authenticate endpoint
class AuthRequest {
  final String? googleToken;
  final String? appleToken;

  AuthRequest({this.googleToken, this.appleToken});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // Include google_token if provided
    if (googleToken != null) data['google_token'] = googleToken;

    // Include apple_token if provided
    if (appleToken != null) data['apple_token'] = appleToken;

    return data;
  }
}
