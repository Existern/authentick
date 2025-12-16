import 'package:json_annotation/json_annotation.dart';
import 'discover_user.dart';
import '../../common/model/pagination.dart';

part 'discover_users_response.g.dart';

@JsonSerializable(explicitToJson: true)
class DiscoverUsersResponse {
  final List<DiscoverUser> data;
  final DiscoverUsersMeta meta;
  final bool success;

  DiscoverUsersResponse({
    required this.data,
    required this.meta,
    required this.success,
  });

  factory DiscoverUsersResponse.fromJson(Map<String, dynamic> json) =>
      _$DiscoverUsersResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoverUsersResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DiscoverUsersMeta {
  final Pagination pagination;
  @JsonKey(name: 'request_id')
  final String requestId;
  final String timestamp;

  DiscoverUsersMeta({
    required this.pagination,
    required this.requestId,
    required this.timestamp,
  });

  factory DiscoverUsersMeta.fromJson(Map<String, dynamic> json) =>
      _$DiscoverUsersMetaFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoverUsersMetaToJson(this);
}
