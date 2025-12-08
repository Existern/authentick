// Response model for POST /posts/{id}/like and DELETE /posts/{id}/like
class LikeResponse {
  final bool success;
  final LikeData? data;
  final ResponseMeta meta;

  LikeResponse({required this.success, this.data, required this.meta});

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? LikeData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      meta: ResponseMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class LikeData {
  final String message;

  LikeData({required this.message});

  factory LikeData.fromJson(Map<String, dynamic> json) {
    return LikeData(
      message: json['message'] as String? ?? 'Operation completed successfully',
    );
  }
}

class ResponseMeta {
  final String? requestId;
  final String? timestamp;
  final Pagination? pagination;

  ResponseMeta({this.requestId, this.timestamp, this.pagination});

  factory ResponseMeta.fromJson(Map<String, dynamic> json) {
    return ResponseMeta(
      requestId: json['request_id'] as String?,
      timestamp: json['timestamp'] as String?,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}
