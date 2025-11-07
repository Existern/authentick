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
  final String username;

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
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'date_of_birth': dateOfBirth ?? '01011990',
      'invite_code': inviteCode ?? 'DEFAULT_CODE',
      'first_name': firstName ?? 'User', // Dummy default value
      'last_name': lastName ?? 'Account', // Dummy default value
      'bio': bio ?? 'New user', // Dummy default value
      'gender': gender ?? 'prefer_not_to_say', // Dummy default value
      'location': location ?? 'Unknown', // Dummy default value
      'phone_number': phoneNumber ?? '+1234567890', // Dummy default value
      'google_token': googleToken ?? '',
    };
  }
}
