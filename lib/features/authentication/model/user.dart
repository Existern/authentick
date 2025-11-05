import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    String? id,
    String? email,
    @JsonKey(name: 'email_verified') bool? emailVerified,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    String? username,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'phone_verified') bool? phoneVerified,
    @JsonKey(name: 'date_of_birth') String? dateOfBirth,
    String? gender,
    String? location,
    String? bio,
    @JsonKey(name: 'profile_image') String? profileImage,
    @JsonKey(name: 'cover_image') String? coverImage,
    String? role,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'is_verified') bool? isVerified,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'last_login_at') String? lastLoginAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
