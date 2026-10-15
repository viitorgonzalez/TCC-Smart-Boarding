class MapStop {
  final String? id;
  final String name;
  final double latitude;
  final double longitude;
  final int sequence;

  /// Nulo fora do trajeto ao vivo: só lá existe "parada já alcançada".
  /// Mantê-lo nulo preserva o pino das telas de rota como era.
  final bool? reached;

  const MapStop({
    required this.name,
    this.id,
    required this.latitude,
    required this.longitude,
    required this.sequence,
    this.reached,
  });
}
