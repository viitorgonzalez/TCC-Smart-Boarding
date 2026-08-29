class WarningModel {
  final String id;
  final String userId;
  final String studentName;
  final String reason;

  /// Data da lista que originou a advertência; nula se a lista foi apagada.
  final String? listDate;
  final String? issuedBy;
  final String createdAt;

  const WarningModel({
    required this.id,
    required this.userId,
    required this.studentName,
    required this.reason,
    required this.createdAt,
    this.listDate,
    this.issuedBy,
  });

  factory WarningModel.fromJson(Map<String, dynamic> json) => WarningModel(
    id: json['id'] as String,
    userId: json['userId'] as String,
    studentName: json['studentName'] as String,
    reason: json['reason'] as String,
    listDate: json['listDate'] as String?,
    issuedBy: json['issuedBy'] as String?,
    createdAt: json['createdAt'] as String,
  );
}
