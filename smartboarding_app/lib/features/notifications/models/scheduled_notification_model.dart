class ScheduledNotificationModel {
  final String id;
  final String routeId;
  final String title;
  final String body;

  final String frequency;
  final String sendAt;

  final int? dayOfWeek;
  final int? durationHours;
  final bool active;
  final String? lastSentAt;

  const ScheduledNotificationModel({
    required this.id,
    required this.routeId,
    required this.title,
    required this.body,
    required this.frequency,
    required this.sendAt,
    this.dayOfWeek,
    this.durationHours,
    this.active = true,
    this.lastSentAt,
  });

  factory ScheduledNotificationModel.fromJson(Map<String, dynamic> json) =>
      ScheduledNotificationModel(
        id: json['id'] as String,
        routeId: json['routeId'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        frequency: json['frequency'] as String,
        sendAt: json['sendAt'] as String,
        dayOfWeek: json['dayOfWeek'] as int?,
        durationHours: json['durationHours'] as int?,
        active: json['active'] as bool? ?? true,
        lastSentAt: json['lastSentAt'] as String?,
      );
}
