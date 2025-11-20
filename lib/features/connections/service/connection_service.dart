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
  /// - type: Predefined relationship filter (close_friends, friends, following, followers) - only one value allowed
  /// - page: Page number - defaults to 1
  /// - limit: Items per page - defaults to 20
  Future<PendingConnectionsResponse> getConnections({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (type != null) {
        queryParams['type'] = type;
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
