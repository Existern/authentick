import 'package:json_annotation/json_annotation.dart';
import 'connection_user.dart';

part 'discover_user.g.dart';

@JsonSerializable(explicitToJson: true)
class DiscoverUser {
  @JsonKey(name: 'mutual_count')
  final int mutualCount;
  final ConnectionUser user;

  DiscoverUser({required this.mutualCount, required this.user});

  factory DiscoverUser.fromJson(Map<String, dynamic> json) =>
      _$DiscoverUserFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoverUserToJson(this);
}
