class ReportSummaryModel {
  final String id;
  final String dailyListId;
  final String listDate;
  final String routeName;
  final int totalEntries;
  final String generatedAt;

  const ReportSummaryModel({
    required this.id,
    required this.dailyListId,
    required this.listDate,
    required this.routeName,
    required this.totalEntries,
    required this.generatedAt,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReportSummaryModel(
      id: json['id'] as String,
      dailyListId: json['dailyListId'] as String,
      listDate: json['listDate'] as String,
      routeName: json['routeName'] as String,
      totalEntries: (json['totalEntries'] as num).toInt(),
      generatedAt: json['generatedAt'] as String,
    );
  }
}

class ReportDetailModel extends ReportSummaryModel {
  final String? snapshotData;

  const ReportDetailModel({
    required super.id,
    required super.dailyListId,
    required super.listDate,
    required super.routeName,
    required super.totalEntries,
    required super.generatedAt,
    this.snapshotData,
  });

  factory ReportDetailModel.fromJson(Map<String, dynamic> json) {
    return ReportDetailModel(
      id: json['id'] as String,
      dailyListId: json['dailyListId'] as String,
      listDate: json['listDate'] as String,
      routeName: json['routeName'] as String,
      totalEntries: (json['totalEntries'] as num).toInt(),
      generatedAt: json['generatedAt'] as String,
      snapshotData: json['snapshotData'] as String?,
    );
  }
}
