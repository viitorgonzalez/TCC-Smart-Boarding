/// Aviso enviado pelo admin. Persistido, então sobrevive ao push — quem estava
/// offline ou trocou de aparelho continua vendo na caixa de entrada.
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? routeId;
  final String? expiresAt;
  final String createdAt;
  final bool expired;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.routeId,
    this.expiresAt,
    this.expired = false,
  });

  bool get isForEveryone => routeId == null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        routeId: json['routeId'] as String?,
        expiresAt: json['expiresAt'] as String?,
        createdAt: json['createdAt'] as String,
        expired: json['expired'] as bool? ?? false,
      );
}
