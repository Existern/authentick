import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

@freezed
abstract class Pagination with _$Pagination {
  const factory Pagination({
    int? page,
    int? limit,
    int? total,
    @JsonKey(name: 'total_pages') int? totalPages,
  }) = _Pagination;

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
}

@freezed
abstract class Meta with _$Meta {
  const factory Meta({
    @JsonKey(name: 'request_id') String? requestId,
    String? timestamp,
    Pagination? pagination,
  }) = _Meta;

  factory Meta.fromJson(Map<String, dynamic> json) => _$MetaFromJson(json);
}

@freezed
abstract class ApiError with _$ApiError {
  const factory ApiError({
    String? code,
    String? message,
    String? details,
    String? field,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}

@freezed
abstract class AuthData with _$AuthData {
  const factory AuthData({
    String? token,
    User? user,
  }) = _AuthData;

  factory AuthData.fromJson(Map<String, dynamic> json) =>
      _$AuthDataFromJson(json);
}

@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    bool? success,
    AuthData? data,
    ApiError? error,
    Meta? meta,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
