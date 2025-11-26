import 'package:json_annotation/json_annotation.dart';
import 'connection_user.dart';

part 'connections_response.g.dart';

@JsonSerializable(explicitToJson: true)
class ConnectionsResponse {
  @JsonKey(name: 'close_friends')
  final List<ConnectionUser> closeFriends;
  final List<ConnectionUser> followers;
  final List<ConnectionUser> following;
  final List<ConnectionUser> friends;

  ConnectionsResponse({
    required this.closeFriends,
    required this.followers,
    required this.following,
    required this.friends,
  });

  factory ConnectionsResponse.fromJson(Map<String, dynamic> json) =>
      _$ConnectionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionsResponseToJson(this);
}
