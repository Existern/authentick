import 'package:json_annotation/json_annotation.dart';

part 'user_profile_response.g.dart';

@JsonSerializable(explicitToJson: true)
class UserProfileResponse {
  final bool success;
  final UserProfileData data;
  final ProfileMeta meta;

  UserProfileResponse({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$UserProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UserProfileData {
  final String id;
  final String? username;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? email;
  @JsonKey(name: 'profile_image')
  final String? profileImage;
  @JsonKey(name: 'profile_image_thumbnail')
  final String? profileImageThumbnail;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  final String? bio;
  final String? location;
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;
  final String? gender;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'phone_verified')
  final bool? phoneVerified;
  @JsonKey(name: 'email_verified')
  final bool? emailVerified;
  @JsonKey(name: 'is_verified')
  final bool? isVerified;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  final String? role;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'last_login_at')
  final String? lastLoginAt;

  UserProfileData({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.profileImage,
    this.profileImageThumbnail,
    this.coverImage,
    this.bio,
    this.location,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.phoneVerified,
    this.emailVerified,
    this.isVerified,
    this.isActive,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileDataToJson(this);

  // Helper method to get full name
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    if (first.isEmpty && last.isEmpty) return username ?? 'User';
    return '$first $last'.trim();
  }
}

@JsonSerializable(explicitToJson: true)
class ProfileMeta {
  @JsonKey(name: 'request_id')
  final String requestId;
  final String timestamp;
  final ProfilePagination? pagination;

  ProfileMeta({
    required this.requestId,
    required this.timestamp,
    this.pagination,
  });

  factory ProfileMeta.fromJson(Map<String, dynamic> json) =>
      _$ProfileMetaFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileMetaToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProfilePagination {
  final int page;
  final int limit;
  final int total;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  ProfilePagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ProfilePagination.fromJson(Map<String, dynamic> json) =>
      _$ProfilePaginationFromJson(json);

  Map<String, dynamic> toJson() => _$ProfilePaginationToJson(this);
}
