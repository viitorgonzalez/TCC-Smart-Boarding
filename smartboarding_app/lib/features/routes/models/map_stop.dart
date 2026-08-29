/// Desacopla o mapa dos modelos de parada de cada feature.
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

/// Pensado também pra mouse: sem pinça, o zoom depende da roda ou dos botões,
