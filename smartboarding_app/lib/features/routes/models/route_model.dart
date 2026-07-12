class RouteModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final String createdAt;

  const RouteModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: json['createdAt'] as String,
    );
  }
}
