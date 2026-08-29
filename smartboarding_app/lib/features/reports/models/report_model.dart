class ReportSummary {
  final String id;
  final String dailyListId;
  final String listDate;
  final String routeName;
  final int totalEntries;
  final String generatedAt;

  const ReportSummary({
    required this.id,
    required this.dailyListId,
    required this.listDate,
    required this.routeName,
    required this.totalEntries,
    required this.generatedAt,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      id: json['id'] as String,
      dailyListId: json['dailyListId'] as String,
      listDate: json['listDate'] as String,
      routeName: json['routeName'] as String,
      totalEntries: json['totalEntries'] as int,
      generatedAt: json['generatedAt'] as String,
    );
  }
}

class ReportDetail extends ReportSummary {
  final String? snapshotData;

  const ReportDetail({
    required super.id,
    required super.dailyListId,
    required super.listDate,
    required super.routeName,
    required super.totalEntries,
    required super.generatedAt,
    this.snapshotData,
  });

  factory ReportDetail.fromJson(Map<String, dynamic> json) {
    return ReportDetail(
      id: json['id'] as String,
      dailyListId: json['dailyListId'] as String,
      listDate: json['listDate'] as String,
      routeName: json['routeName'] as String,
      totalEntries: json['totalEntries'] as int,
      generatedAt: json['generatedAt'] as String,
      snapshotData: json['snapshotData'] as String?,
    );
  }
}
