class VehicleModel {
  final String id;
  final String label;
  final int capacity;

  const VehicleModel({
    required this.id,
    required this.label,
    required this.capacity,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    id: json['id'] as String,
    label: json['label'] as String,
    capacity: json['capacity'] as int,
  );
}
