class WaitlistResponse {
  final bool success;
  final WaitlistData data;

  WaitlistResponse({required this.success, required this.data});

  factory WaitlistResponse.fromJson(Map<String, dynamic> json) {
    return WaitlistResponse(
      success: json['success'] as bool? ?? false,
      data: WaitlistData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class WaitlistData {
  final String message;
  final bool alreadyExists;
  final WaitlistEntry? entry;

  WaitlistData({
    required this.message,
    required this.alreadyExists,
    this.entry,
  });

  factory WaitlistData.fromJson(Map<String, dynamic> json) {
    return WaitlistData(
      message: json['message'] as String,
      alreadyExists: json['already_exists'] as bool? ?? false,
      entry: json['entry'] != null
          ? WaitlistEntry.fromJson(json['entry'] as Map<String, dynamic>)
          : null,
    );
  }
}

class WaitlistEntry {
  final String id;
  final String email;
  final String status;
  final String createdAt;
  final String updatedAt;

  WaitlistEntry({
    required this.id,
    required this.email,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    return WaitlistEntry(
      id: json['id'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}
