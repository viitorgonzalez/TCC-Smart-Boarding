class DailyListModel {
  final String id;
  final String routeId;
  final String routeName;
  final String date;
  final String status;
  final int totalEntries;

  const DailyListModel({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.date,
    required this.status,
    required this.totalEntries,
  });

  factory DailyListModel.fromJson(Map<String, dynamic> json) {
    return DailyListModel(
      id: json['id'] as String,
      routeId: json['routeId'] as String,
      routeName: json['routeName'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      totalEntries: (json['totalEntries'] as num).toInt(),
    );
  }

  bool get isOpen => status == 'OPEN';
}
