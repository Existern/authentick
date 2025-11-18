import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/remote/api_client.dart';
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

  /// Get connections with optional filters
  /// GET /connections
  /// Parameters:
  /// - type: Filter by connection type (friend, follower, close_friend) - can provide multiple values
  /// - status: Filter by status (pending, accepted, rejected, blocked) - can provide multiple values
  /// - page: Page number - defaults to 1
  /// - limit: Items per page - defaults to 20
  Future<PendingConnectionsResponse> getConnections({
    List<String>? types,
    List<String>? statuses,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (types != null && types.isNotEmpty) {
        queryParams['type'] = types.join(',');
      }

      if (statuses != null && statuses.isNotEmpty) {
        queryParams['status'] = statuses.join(',');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/connections',
        queryParameters: queryParams,
      );
      return PendingConnectionsResponse.fromJson(response);
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
