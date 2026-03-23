class NotificationModel {
  final String id;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;
  final String? refId;

  NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.refId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
      refId: json['refId'],
    );
  }
}
