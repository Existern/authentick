// Authentication response model for /auth/authenticate endpoint
class AuthResponse {
  final bool success;
  final AuthData data;
  final ResponseMeta? meta;

  AuthResponse({required this.success, required this.data, this.meta});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      if (json['data'] == null) {
        throw Exception('AuthResponse: missing "data" field. Response: $json');
      }
      if (json['data'] is! Map<String, dynamic>) {
        throw Exception(
          'AuthResponse: "data" field is not an object. Got: ${json['data'].runtimeType}, Value: ${json['data']}',
        );
      }
      return AuthResponse(
        success: json['success'] as bool? ?? false,
        data: AuthData.fromJson(json['data'] as Map<String, dynamic>),
        meta: json['meta'] != null
            ? ResponseMeta.fromJson(json['meta'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      throw Exception('AuthResponse.fromJson failed: $e. Raw JSON: $json');
    }
  }
}

class AuthData {
  final Tokens tokens;
  final User user;
  final Onboarding? onboarding;

  AuthData({required this.tokens, required this.user, this.onboarding});

  factory AuthData.fromJson(Map<String, dynamic> json) {
    try {
      if (json['tokens'] == null) {
        throw Exception('AuthData: missing "tokens" field. Data: $json');
      }
      if (json['user'] == null) {
        throw Exception('AuthData: missing "user" field. Data: $json');
      }
      if (json['user'] is! Map<String, dynamic>) {
        throw Exception(
          'AuthData: "user" field is not an object. Got: ${json['user'].runtimeType}, Value: ${json['user']}',
        );
      }
      return AuthData(
        tokens: Tokens.fromJson(json['tokens']),
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        onboarding: json['onboarding'] != null
            ? Onboarding.fromJson(json['onboarding'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      throw Exception('AuthData.fromJson failed: $e. Raw JSON: $json');
    }
  }
}

class Tokens {
  final String accessToken;
  final String refreshToken;
  final int? expiresIn;

  Tokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
  });

  factory Tokens.fromJson(dynamic json) {
    // Handle invalid or missing tokens data
    if (json == null) {
      throw Exception('Tokens: data is null');
    }

    if (json is! Map<String, dynamic>) {
      throw Exception(
        'Tokens: data is not a valid object. Got: ${json.runtimeType}, Value: $json',
      );
    }

    try {
      if (json['access_token'] == null) {
        throw Exception('Tokens: missing "access_token" field. Data: $json');
      }
      if (json['refresh_token'] == null) {
        throw Exception('Tokens: missing "refresh_token" field. Data: $json');
      }
      return Tokens(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresIn: json['expires_in'] as int?,
      );
    } catch (e) {
      throw Exception('Tokens.fromJson failed: $e. Raw JSON: $json');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      if (expiresIn != null) 'expires_in': expiresIn,
    };
  }
}

class Onboarding {
  final bool completed;
  final String? completedAt;
  final String userId;
  final List<OnboardingStep> steps;

  Onboarding({
    required this.completed,
    this.completedAt,
    required this.userId,
    required this.steps,
  });

  factory Onboarding.fromJson(Map<String, dynamic> json) {
    return Onboarding(
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] as String?,
      userId: json['user_id'] as String,
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map(
                (step) => OnboardingStep.fromJson(step as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      if (completedAt != null) 'completed_at': completedAt,
      'user_id': userId,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }
}

class OnboardingStep {
  final String step;
  final String displayName;
  final String status;
  final bool skippable;
  final String? completedAt;

  OnboardingStep({
    required this.step,
    required this.displayName,
    required this.status,
    required this.skippable,
    this.completedAt,
  });

  factory OnboardingStep.fromJson(Map<String, dynamic> json) {
    return OnboardingStep(
      step: json['step'] as String,
      displayName: json['display_name'] as String,
      status: json['status'] as String,
      skippable: json['skippable'] as bool? ?? false,
      completedAt: json['completed_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'display_name': displayName,
      'status': status,
      'skippable': skippable,
      if (completedAt != null) 'completed_at': completedAt,
    };
  }
}

class User {
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
  final String? profileImageThumbnail;
  final String? coverImage;
  final bool? isActive;
  final bool? isVerified;
  final String? role;
  final String createdAt;
  final String? updatedAt;
  final String? lastLoginAt;

  User({
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
    this.profileImageThumbnail,
    this.coverImage,
    this.isActive,
    this.isVerified,
    this.role,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      if (json['id'] == null) {
        throw Exception('User: missing "id" field. Data: $json');
      }
      if (json['created_at'] == null) {
        throw Exception('User: missing "created_at" field. Data: $json');
      }
      return User(
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
        profileImageThumbnail: json['profile_image_thumbnail'] as String?,
        coverImage: json['cover_image'] as String?,
        isActive: json['is_active'] as bool?,
        isVerified: json['is_verified'] as bool?,
        role: json['role'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String?,
        lastLoginAt: json['last_login_at'] as String?,
      );
    } catch (e) {
      throw Exception('User.fromJson failed: $e. Raw JSON: $json');
    }
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
      'profile_image_thumbnail': profileImageThumbnail,
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

  ResponseMeta({this.requestId, this.timestamp, this.pagination});

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
