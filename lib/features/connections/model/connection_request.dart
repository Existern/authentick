import 'package:json_annotation/json_annotation.dart';
import 'connection_user.dart';

part 'connection_request.g.dart';

@JsonSerializable(explicitToJson: true)
class ConnectionRequest {
  final String id;
  @JsonKey(name: 'requester_user')
  final ConnectionUser? requesterUser;
  @JsonKey(name: 'target_user')
  final ConnectionUser? targetUser;
  final ConnectionRequestStatus status;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'updated_by')
  final String? updatedBy;
  @JsonKey(name: 'responded_at')
  final String? respondedAt;
  @JsonKey(name: 'deleted_at')
  final String? deletedAt;
  @JsonKey(name: 'deleted_by')
  final String? deletedBy;

  ConnectionRequest({
    required this.id,
    this.requesterUser,
    this.targetUser,
    required this.status,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.respondedAt,
    this.deletedAt,
    this.deletedBy,
  });

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) =>
      _$ConnectionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionRequestToJson(this);
}

enum ConnectionRequestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('rejected')
  rejected,
  @JsonValue('cancelled')
  cancelled,
}
