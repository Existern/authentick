import 'package:json_annotation/json_annotation.dart';
import 'connection_user.dart';

part 'discover_user.g.dart';

@JsonSerializable(explicitToJson: true)
class DiscoverUser {
  @JsonKey(name: 'mutual_count')
  final int mutualCount;
  final ConnectionUser user;
  @JsonKey(name: 'has_pending_request')
  final bool? hasPendingRequest;
  @JsonKey(name: 'has_incoming_request')
  final bool? hasIncomingRequest;
  @JsonKey(name: 'connection_request_id')
  final String? connectionRequestId;

  DiscoverUser({
    required this.mutualCount,
    required this.user,
    this.hasPendingRequest,
    this.hasIncomingRequest,
    this.connectionRequestId,
  });

  factory DiscoverUser.fromJson(Map<String, dynamic> json) =>
      _$DiscoverUserFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoverUserToJson(this);
}
