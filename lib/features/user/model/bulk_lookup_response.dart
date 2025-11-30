class BulkLookupResponse {
  final BulkLookupData data;
  final BulkLookupMeta meta;
  final bool success;

  const BulkLookupResponse({
    required this.data,
    required this.meta,
    required this.success,
  });

  factory BulkLookupResponse.fromJson(Map<String, dynamic> json) =>
      BulkLookupResponse(
        data: BulkLookupData.fromJson(json['data'] as Map<String, dynamic>),
        meta: BulkLookupMeta.fromJson(json['meta'] as Map<String, dynamic>),
        success: json['success'] as bool,
      );
}

class BulkLookupData {
  final int totalConnected;
  final int totalFound;
  final int totalRequested;
  final List<UserLookupInfo> users;

  const BulkLookupData({
    required this.totalConnected,
    required this.totalFound,
    required this.totalRequested,
    required this.users,
  });

  factory BulkLookupData.fromJson(Map<String, dynamic> json) => BulkLookupData(
    totalConnected: json['total_connected'] as int,
    totalFound: json['total_found'] as int,
    totalRequested: json['total_requested'] as int,
    users: (json['users'] as List<dynamic>)
        .map((user) => UserLookupInfo.fromJson(user as Map<String, dynamic>))
        .toList(),
  );
}

class UserLookupInfo {
  final String id;
  final String username;
  final String? profileImage;
  final bool isConnected;
  final String? connectionStatus;

  const UserLookupInfo({
    required this.id,
    required this.username,
    this.profileImage,
    required this.isConnected,
    this.connectionStatus,
  });

  factory UserLookupInfo.fromJson(Map<String, dynamic> json) => UserLookupInfo(
    id: json['id'] as String,
    username: json['username'] as String,
    profileImage: json['profile_image'] as String?,
    isConnected: json['is_connected'] as bool,
    connectionStatus: json['connection_status'] as String?,
  );
}

class BulkLookupMeta {
  final String requestId;
  final String timestamp;

  const BulkLookupMeta({required this.requestId, required this.timestamp});

  factory BulkLookupMeta.fromJson(Map<String, dynamic> json) => BulkLookupMeta(
    requestId: json['request_id'] as String,
    timestamp: json['timestamp'] as String,
  );
}
