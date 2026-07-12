class DailyList {
  final String id;
  final String routeId;
  final String routeName;
  final String date;
  final String status;
  final int totalEntries;

  /// Inscrição do usuário logado nesta lista (preenchido pela API em /lists).
  final bool enrolled;
  final String? tripType;

  const DailyList({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.date,
    required this.status,
    required this.totalEntries,
    this.enrolled = false,
    this.tripType,
  });

  factory DailyList.fromJson(Map<String, dynamic> json) {
    return DailyList(
      id: json['id'] as String,
      routeId: json['routeId'] as String,
      routeName: json['routeName'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      totalEntries: json['totalEntries'] as int,
      enrolled: json['enrolled'] as bool? ?? false,
      tripType: json['tripType'] as String?,
    );
  }

  bool get isOpen => status == 'OPEN';
}
