class TripStatus {
  final String listId;
  final String routeName;
  final String? startedAt;

  final String? outboundFinishedAt;
  final String? finishedAt;

  final String leg;
  final List<TripStop> stops;

  final MyStop? myStop;

  const TripStatus({
    required this.listId,
    required this.routeName,
    required this.stops,
    this.leg = 'OUTBOUND',
    this.startedAt,
    this.outboundFinishedAt,
    this.finishedAt,
    this.myStop,
  });

  bool get onReturn => leg == 'RETURN';

  bool get inProgress => startedAt != null && finishedAt == null;
  bool get notStarted => startedAt == null;
  bool get finished => finishedAt != null;

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
    outboundFinishedAt: json['outboundFinishedAt'] as String?,
    finishedAt: json['finishedAt'] as String?,
    leg: json['leg'] as String? ?? 'OUTBOUND',
    stops: (json['stops'] as List? ?? const [])
        .map((e) => TripStop.fromJson(e as Map<String, dynamic>))
        .toList(),
    myStop: json['myStop'] == null
        ? null
        : MyStop.fromJson(json['myStop'] as Map<String, dynamic>),
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

class MyStop {
  final String stopId;
  final String stopName;

  final bool fallback;
  final bool alreadyReached;

  final int? etaMinutes;

  const MyStop({
    required this.stopId,
    required this.stopName,
    this.fallback = false,
    this.alreadyReached = false,
    this.etaMinutes,
  });

  factory MyStop.fromJson(Map<String, dynamic> json) => MyStop(
    stopId: json['stopId'] as String,
    stopName: json['stopName'] as String,
    fallback: json['fallback'] as bool? ?? false,
    alreadyReached: json['alreadyReached'] as bool? ?? false,
    etaMinutes: json['etaMinutes'] as int?,
  );
}
