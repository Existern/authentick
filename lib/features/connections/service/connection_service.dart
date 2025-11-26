import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
import '../model/connections_response.dart';
import '../model/pending_connections_response.dart';

part 'connection_service.g.dart';

@riverpod
ConnectionService connectionService(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConnectionService(apiClient);
}

class ConnectionService {
  final ApiClient _apiClient;

  ConnectionService(this._apiClient);

  /// Get connections (friends, following, close friends)
  /// GET /connections/users
  Future<ConnectionsResponse> getConnections() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/connections/users',
      );
      return ConnectionsResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get pending connection requests
  /// GET /connections/pending
  Future<PendingConnectionsResponse> getPendingConnections({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/connections/pending',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      return PendingConnectionsResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Accept a connection request
  /// PATCH /connections/{connectionId}
  Future<Map<String, dynamic>> acceptConnection(String connectionId) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/connections/$connectionId',
        data: {
          'action': 'accept',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Deny/reject a connection request
  /// PATCH /connections/{connectionId}
  Future<Map<String, dynamic>> rejectConnection(String connectionId) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/connections/$connectionId',
        data: {
          'action': 'reject',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
