import 'package:json_annotation/json_annotation.dart';

part 'connection_user.g.dart';

@JsonSerializable(explicitToJson: true)
class ConnectionUser {
  final String id;
  final String? username;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? email;
  @JsonKey(name: 'email_verified')
  final bool? emailVerified;
  @JsonKey(name: 'profile_image_thumbnail')
  final String? profileImage;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  final String? bio;
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;
  final String? gender;
  final String? location;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'phone_verified')
  final bool? phoneVerified;
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
  @JsonKey(name: 'is_friend')
  final bool? isFriend;
  @JsonKey(name: 'is_close_friend')
  final bool? isCloseFriend;
  @JsonKey(name: 'is_following')
  final bool? isFollowing;
  @JsonKey(name: 'friend_request_id')
  final String? friendRequestId;
  @JsonKey(name: 'connection_request_id')
  final String? connectionRequestId;
  @JsonKey(name: 'has_pending_request')
  final bool? hasPendingRequest;
  @JsonKey(name: 'has_incoming_request')
  final bool? hasIncomingRequest;

  ConnectionUser({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.emailVerified,
    this.profileImage,
    this.coverImage,
    this.bio,
    this.dateOfBirth,
    this.gender,
    this.location,
    this.phoneNumber,
    this.phoneVerified,
    this.isVerified,
    this.isActive,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isFriend,
    this.isCloseFriend,
    this.isFollowing,
    this.friendRequestId,
    this.connectionRequestId,
    this.hasPendingRequest,
    this.hasIncomingRequest,
  });

  factory ConnectionUser.fromJson(Map<String, dynamic> json) =>
      _$ConnectionUserFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionUserToJson(this);

  // Helper method to get full name
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    if (first.isEmpty && last.isEmpty) return username ?? 'User';
    return '$first $last'.trim();
  }
}
