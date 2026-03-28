class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.kind,
    this.taskId,
    this.isUnread = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final AppNotificationKind kind;
  final int? taskId;
  final bool isUnread;
}

enum AppNotificationKind { reminder, warning, reward, info }
