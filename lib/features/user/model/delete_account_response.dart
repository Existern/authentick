import 'package:json_annotation/json_annotation.dart';

part 'delete_account_response.g.dart';

/// Response model for DELETE /users/account
/// Also used for POST /users/account/restore
/// 
/// API Response Structure:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "message": "Account deletion requested. Your account will be permanently deleted in 30 days."
///   },
///   "meta": {
///     "request_id": "...",
///     "timestamp": "..."
///   }
/// }
/// ```
@JsonSerializable(explicitToJson: true)
class DeleteAccountResponse {
  final bool success;
  final DeleteAccountData data;
  final DeleteAccountMeta? meta;

  DeleteAccountResponse({
    required this.success,
    required this.data,
    this.meta,
  });

  factory DeleteAccountResponse.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccountResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteAccountResponseToJson(this);
}

@JsonSerializable()
class DeleteAccountData {
  final String message;

  DeleteAccountData({required this.message});

  factory DeleteAccountData.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccountDataFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteAccountDataToJson(this);
}

@JsonSerializable()
class DeleteAccountMeta {
  @JsonKey(name: 'request_id')
  final String? requestId;
  final String? timestamp;

  DeleteAccountMeta({
    this.requestId,
    this.timestamp,
  });

  factory DeleteAccountMeta.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccountMetaFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteAccountMetaToJson(this);
}
