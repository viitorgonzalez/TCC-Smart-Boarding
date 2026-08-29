class RouteModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  /// Horários em que a lista do dia abre e fecha (RN18).
  final String? openTime;
  final String? closeTime;
  final String createdAt;

  const RouteModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.openTime,
    this.closeTime,
    required this.createdAt,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}
