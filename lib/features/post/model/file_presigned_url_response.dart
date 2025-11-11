// Response model for POST /files/presigned-url
class FilePresignedUrlResponse {
  final bool success;
  final FilePresignedUrlData data;
  final ResponseMeta meta;

  FilePresignedUrlResponse({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory FilePresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return FilePresignedUrlResponse(
      success: json['success'] as bool? ?? false,
      data: FilePresignedUrlData.fromJson(json['data'] as Map<String, dynamic>),
      meta: ResponseMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class FilePresignedUrlData {
  final String uploadUrl;
  final int expiresIn;

  FilePresignedUrlData({
    required this.uploadUrl,
    required this.expiresIn,
  });

  factory FilePresignedUrlData.fromJson(Map<String, dynamic> json) {
    return FilePresignedUrlData(
      uploadUrl: json['upload_url'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }
}

class ResponseMeta {
  final String? requestId;
  final String? timestamp;
  final Pagination? pagination;

  ResponseMeta({
    this.requestId,
    this.timestamp,
    this.pagination,
  });

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
