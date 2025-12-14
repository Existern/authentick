import 'package:json_annotation/json_annotation.dart';
import 'connection_user.dart';
import '../../common/model/pagination.dart';

part 'search_users_response.g.dart';

@JsonSerializable(explicitToJson: true)
class SearchUsersResponse {
  final SearchUsersData data;
  final SearchUsersMeta meta;
  final bool success;

  SearchUsersResponse({
    required this.data,
    required this.meta,
    required this.success,
  });

  factory SearchUsersResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchUsersResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchUsersResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SearchUsersData {
  @JsonKey(name: 'total_count')
  final int totalCount;
  final List<ConnectionUser> users;

  SearchUsersData({required this.totalCount, required this.users});

  factory SearchUsersData.fromJson(Map<String, dynamic> json) =>
      _$SearchUsersDataFromJson(json);

  Map<String, dynamic> toJson() => _$SearchUsersDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SearchUsersMeta {
  final Pagination pagination;
  @JsonKey(name: 'request_id')
  final String requestId;
  final String timestamp;

  SearchUsersMeta({
    required this.pagination,
    required this.requestId,
    required this.timestamp,
  });

  factory SearchUsersMeta.fromJson(Map<String, dynamic> json) =>
      _$SearchUsersMetaFromJson(json);

  Map<String, dynamic> toJson() => _$SearchUsersMetaToJson(this);
}
