// Authentication request model for /auth/authenticate endpoint
class AuthRequest {
  final String? bio;
  final String? dateOfBirth;
  final String? firstName;
  final String? gender;
  final String? googleToken;
  final String? inviteCode;
  final String? lastName;
  final String? location;
  final String? phoneNumber;
  final String? username;

  AuthRequest({
    this.bio,
    this.dateOfBirth,
    this.firstName,
    this.gender,
    this.googleToken,
    this.inviteCode,
    this.lastName,
    this.location,
    this.phoneNumber,
    this.username,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // Only include fields that are provided
    if (username != null) data['username'] = username;
    if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;
    if (inviteCode != null) data['invite_code'] = inviteCode;
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (bio != null) data['bio'] = bio;
    if (gender != null) data['gender'] = gender;
    if (location != null) data['location'] = location;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (googleToken != null) data['google_token'] = googleToken;

    return data;
  }
}
