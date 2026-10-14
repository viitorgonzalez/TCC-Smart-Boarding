class MapStop {
  final String? id;
  final String name;
  final double latitude;
  final double longitude;
  final int sequence;

  const MapStop({
    required this.name,
    this.id,
    required this.latitude,
    required this.longitude,
    required this.sequence,
  });
}
