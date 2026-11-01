class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final String type; // 'promo', 'order', 'loyalty', 'system'
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.type,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title_ar'] ?? json['title'] ?? json['title_en'] ?? '',
      body: json['body_ar'] ?? json['body'] ?? json['message'] ?? json['body_en'] ?? '',
      timeAgo: json['created_at'] != null ? 'حديثاً' : 'اليوم',
      type: json['type'] ?? 'system',
      isRead: json['is_read'] ?? false,
    );
  }
}
