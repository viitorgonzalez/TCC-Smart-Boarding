class InstitutionModel {
  final String id;
  final String name;
  final String? address;

  final String? routeId;

  const InstitutionModel({
    required this.id,
    required this.name,
    this.address,
    this.routeId,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      routeId: json['routeId'] as String?,
    );
  }
}
