// Profile update request model for PUT /users/profile endpoint
class ProfileUpdateRequest {
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? bio;
  final String? location;
  final String? phoneNumber;
  final String? profileImage;
  final String? coverImage;
  final String? invitedByCode;

  ProfileUpdateRequest({
    this.username,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.location,
    this.phoneNumber,
    this.profileImage,
    this.coverImage,
    this.invitedByCode,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // Only include fields that are provided
    if (username != null) data['username'] = username;
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;
    if (gender != null) data['gender'] = gender;
    if (bio != null) data['bio'] = bio;
    if (location != null) data['location'] = location;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (profileImage != null) data['profile_image'] = profileImage;
    if (coverImage != null) data['cover_image'] = coverImage;
    if (invitedByCode != null) data['invited_by_code'] = invitedByCode;

    return data;
  }
}
