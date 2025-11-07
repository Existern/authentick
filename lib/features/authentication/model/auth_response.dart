// Authentication response model for /auth/authenticate endpoint
class AuthResponse {
  final bool success;
  final AuthData data;
  final ResponseMeta meta;

  AuthResponse({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      data: AuthData.fromJson(json['data'] as Map<String, dynamic>),
      meta: ResponseMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class AuthData {
  final String token;
  final User user;

  AuthData({
    required this.token,
    required this.user,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class User {
  final String id;
  final String username;
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

  User({
    required this.id,
    required this.username,
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'email_verified': emailVerified,
      'phone_number': phoneNumber,
      'phone_verified': phoneVerified,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'bio': bio,
      'location': location,
      'profile_image': profileImage,
      'cover_image': coverImage,
      'is_active': isActive,
      'is_verified': isVerified,
      'role': role,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'last_login_at': lastLoginAt,
    };
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
