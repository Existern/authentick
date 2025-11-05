import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_request.freezed.dart';
part 'auth_request.g.dart';

@freezed
abstract class AuthRequest with _$AuthRequest {
  const factory AuthRequest({
    @JsonKey(name: 'google_token') String? googleToken,
    String? username,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'date_of_birth') String? dateOfBirth,
    String? gender,
    String? location,
    String? bio,
    @JsonKey(name: 'invite_code') String? inviteCode,
  }) = _AuthRequest;

  factory AuthRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthRequestFromJson(json);
}
