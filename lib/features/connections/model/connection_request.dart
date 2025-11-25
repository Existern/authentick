class ConnectionRequest {
  final String connectedUserId;
  final String connectionType;

  const ConnectionRequest({
    required this.connectedUserId,
    this.connectionType = 'friend',
  });

  Map<String, dynamic> toJson() => {
    'connected_user_id': connectedUserId,
    'connection_type': connectionType,
  };
}
