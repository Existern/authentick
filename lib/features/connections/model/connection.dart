import 'package:json_annotation/json_annotation.dart';
import 'connection_user.dart';

part 'connection.g.dart';

@JsonSerializable(explicitToJson: true)
class Connection {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'connected_user_id')
  final String connectedUserId;
  @JsonKey(name: 'connection_type')
  final String connectionType;
  final String status;
  @JsonKey(name: 'initiated_by')
  final String initiatedBy;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final ConnectionUser? user;
  @JsonKey(name: 'connected_user')
  final ConnectionUser? connectedUser;

  Connection({
    required this.id,
    required this.userId,
    required this.connectedUserId,
    required this.connectionType,
    required this.status,
    required this.initiatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.connectedUser,
  });

  factory Connection.fromJson(Map<String, dynamic> json) =>
      _$ConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionToJson(this);
}
