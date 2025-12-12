// Invite code validation response model for /invite-codes/validate endpoint
class InviteCodeValidateResponse {
  final bool success;
  final InviteCodeData? data;
  final ResponseMeta meta;

  InviteCodeValidateResponse({
    required this.success,
    this.data,
    required this.meta,
  });

  factory InviteCodeValidateResponse.fromJson(Map<String, dynamic> json) {
    return InviteCodeValidateResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? InviteCodeData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      meta: ResponseMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class InviteCodeData {
  final String type;
  final bool valid;

  InviteCodeData({required this.type, required this.valid});

  factory InviteCodeData.fromJson(Map<String, dynamic> json) {
    return InviteCodeData(
      type: json['type'] as String? ?? '',
      valid: json['valid'] as bool? ?? false,
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
