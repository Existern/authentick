import 'package:json_annotation/json_annotation.dart';
import 'connection.dart';

part 'pending_connections_response.g.dart';

@JsonSerializable(explicitToJson: true)
class PendingConnectionsData {
  final List<Connection> connections;
  @JsonKey(name: 'total_count')
  final int totalCount;

  PendingConnectionsData({
    required this.connections,
    required this.totalCount,
  });

  factory PendingConnectionsData.fromJson(Map<String, dynamic> json) =>
      _$PendingConnectionsDataFromJson(json);

  Map<String, dynamic> toJson() => _$PendingConnectionsDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ConnectionMeta {
  @JsonKey(name: 'request_id')
  final String requestId;
  final String timestamp;
  final ConnectionPagination? pagination;

  ConnectionMeta({
    required this.requestId,
    required this.timestamp,
    this.pagination,
  });

  factory ConnectionMeta.fromJson(Map<String, dynamic> json) =>
      _$ConnectionMetaFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionMetaToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ConnectionPagination {
  final int page;
  final int limit;
  final int total;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  ConnectionPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ConnectionPagination.fromJson(Map<String, dynamic> json) =>
      _$ConnectionPaginationFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionPaginationToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PendingConnectionsResponse {
  final bool success;
  final PendingConnectionsData data;
  final ConnectionMeta meta;

  PendingConnectionsResponse({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory PendingConnectionsResponse.fromJson(Map<String, dynamic> json) =>
      _$PendingConnectionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PendingConnectionsResponseToJson(this);
}
