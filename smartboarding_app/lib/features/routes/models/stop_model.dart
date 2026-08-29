/// Parada de uma rota, na ordem de passagem (`sequence`).
class StopModel {
  final String id;
  final String name;
  final int sequence;
  final double? latitude;
  final double? longitude;

  const StopModel({
    required this.id,
    required this.name,
    required this.sequence,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sequence: json['sequence'] as int,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
