import 'package:json_annotation/json_annotation.dart';
import 'connection_user.dart';

part 'friendship.g.dart';

@JsonSerializable(explicitToJson: true)
class Friendship {
  final String id;
  final ConnectionUser? friend;
  final FriendshipStatus status;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'updated_by')
  final String? updatedBy;
  @JsonKey(name: 'established_at')
  final String? establishedAt;
  @JsonKey(name: 'blocked_at')
  final String? blockedAt;
  @JsonKey(name: 'blocked_by')
  final String? blockedBy;
  @JsonKey(name: 'deleted_at')
  final String? deletedAt;
  @JsonKey(name: 'deleted_by')
  final String? deletedBy;

  Friendship({
    required this.id,
    this.friend,
    required this.status,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.establishedAt,
    this.blockedAt,
    this.blockedBy,
    this.deletedAt,
    this.deletedBy,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) =>
      _$FriendshipFromJson(json);

  Map<String, dynamic> toJson() => _$FriendshipToJson(this);
}

enum FriendshipStatus {
  @JsonValue('active')
  active,
  @JsonValue('blocked')
  blocked,
  @JsonValue('removed')
  removed,
}

