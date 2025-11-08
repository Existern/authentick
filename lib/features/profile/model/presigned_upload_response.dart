// Presigned upload response model for POST /users/presigned-upload-url
class PresignedUploadResponse {
  final bool success;
  final PresignedUploadData data;
  final ResponseMeta meta;

  PresignedUploadResponse({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory PresignedUploadResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUploadResponse(
      success: json['success'] as bool? ?? false,
      data: PresignedUploadData.fromJson(json['data'] as Map<String, dynamic>),
      meta: ResponseMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class PresignedUploadData {
  final String imageType;
  final String imageUrl;
  final String message;
  final String? presignedUrl; // Nullable - only present in presigned-upload-url response

  PresignedUploadData({
    required this.imageType,
    required this.imageUrl,
    required this.message,
    this.presignedUrl, // Optional
  });

  factory PresignedUploadData.fromJson(Map<String, dynamic> json) {
    return PresignedUploadData(
      imageType: json['image_type'] as String,
      imageUrl: json['image_url'] as String,
      message: json['message'] as String,
      presignedUrl: json['presigned_url'] as String?, // Nullable cast
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
