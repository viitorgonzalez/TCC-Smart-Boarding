class InstitutionModel {
  final String id;
  final String name;
  final String? address;

  const InstitutionModel({required this.id, required this.name, this.address});

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
    );
  }
}
