/// Estado do trajeto do dia. `startedAt` nulo = não começou; `finishedAt`
/// preenchido = encerrado.
class TripStatus {
  final String listId;
  final String routeName;
  final String? startedAt;
  final String? finishedAt;
  final List<TripStop> stops;

  const TripStatus({
    required this.listId,
    required this.routeName,
    required this.stops,
    this.startedAt,
    this.finishedAt,
  });

  bool get inProgress => startedAt != null && finishedAt == null;
  bool get notStarted => startedAt == null;
  bool get finished => finishedAt != null;

  /// Primeiro ponto ainda não alcançado — é o único que ganha botão, como no
  /// desenho: um "Marcar" por vez.
  TripStop? get current {
    if (!inProgress) return null;
    for (final s in stops) {
      if (!s.reached) return s;
    }
    return null;
  }

  factory TripStatus.fromJson(Map<String, dynamic> json) => TripStatus(
    listId: json['listId'] as String,
    routeName: json['routeName'] as String,
    startedAt: json['startedAt'] as String?,
    finishedAt: json['finishedAt'] as String?,
    stops: (json['stops'] as List? ?? const [])
        .map((e) => TripStop.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class TripStop {
  final String stopId;
  final String name;
  final int sequence;
  final String? reachedAt;

  const TripStop({
    required this.stopId,
    required this.name,
    required this.sequence,
    this.reachedAt,
  });

  bool get reached => reachedAt != null;

  factory TripStop.fromJson(Map<String, dynamic> json) => TripStop(
    stopId: json['stopId'] as String,
    name: json['name'] as String,
    sequence: json['sequence'] as int,
    reachedAt: json['reachedAt'] as String?,
  );
}
