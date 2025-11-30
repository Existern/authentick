class BulkLookupRequest {
  final List<String> emails;

  const BulkLookupRequest({required this.emails});

  Map<String, dynamic> toJson() => {'emails': emails};
}
