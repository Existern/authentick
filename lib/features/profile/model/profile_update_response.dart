// Profile update response model for PUT /users/profile endpoint
class ProfileUpdateResponse {
  final bool success;
  final UserProfile data;
  final ResponseMeta meta;

  ProfileUpdateResponse({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory ProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateResponse(
      success: json['success'] as bool? ?? false,
      data: UserProfile.fromJson(json['data'] as Map<String, dynamic>),
      meta: ResponseMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class UserProfile {
  final String id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final bool? emailVerified;
  final String? phoneNumber;
  final bool? phoneVerified;
  final String? dateOfBirth;
  final String? gender;
  final String? bio;
  final String? location;
  final String? profileImage;
  final String? coverImage;
  final bool? isActive;
  final bool? isVerified;
  final String? role;
  final String createdAt;
  final String? updatedAt;
  final String? lastLoginAt;

  UserProfile({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.emailVerified,
    this.phoneNumber,
    this.phoneVerified,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.location,
    this.profileImage,
    this.coverImage,
    this.isActive,
    this.isVerified,
    this.role,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      emailVerified: json['email_verified'] as bool?,
      phoneNumber: json['phone_number'] as String?,
      phoneVerified: json['phone_verified'] as bool?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      profileImage: json['profile_image'] as String?,
      coverImage: json['cover_image'] as String?,
      isActive: json['is_active'] as bool?,
      isVerified: json['is_verified'] as bool?,
      role: json['role'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
      lastLoginAt: json['last_login_at'] as String?,
    );
  }
}

class ResponseMeta {
  final String? requestId;
  final String? timestamp;
  final Pagination? pagination;

  ResponseMeta({
    this.requestId,
    this.timestamp,
    this.pagination,
  });

  factory ResponseMeta.fromJson(Map<String, dynamic> json) {
    return ResponseMeta(
      requestId: json['request_id'] as String?,
      timestamp: json['timestamp'] as String?,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}
