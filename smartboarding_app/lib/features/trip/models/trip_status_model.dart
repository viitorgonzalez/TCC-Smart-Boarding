/// Estado do trajeto do dia. `startedAt` nulo = não começou; `finishedAt`
/// preenchido = encerrado.
class TripStatus {
  final String listId;
  final String routeName;
  final String? startedAt;

  /// Quando a ida acabou. Nulo = ainda na ida.
  final String? outboundFinishedAt;
  final String? finishedAt;

  /// OUTBOUND ou RETURN. A API já manda as paradas na ordem certa de cada
  /// perna — o app não reordena, só rotula.
  final String leg;
  final List<TripStop> stops;

  /// Onde ESTE aluno desce, e quanto falta. Nulo pro admin, que conduz o
  /// ônibus em vez de viajar nele.
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

/// A parada do aluno e o tempo até ela.
///
/// Dois alunos no mesmo ônibus veem números diferentes — por isso [stopName]
/// vem junto: sem nomear o destino, quem vê o número do colega conclui que o
/// app está errado.
class MyStop {
  final String stopId;
  final String stopName;

  /// A instituição do aluno não tem parada declarada, e isto é a última do
  /// trajeto. A tela precisa dizer isso: um tempo até um lugar que não é o
  /// dele, sem aviso, é pior que tempo nenhum.
  final bool fallback;
  final bool alreadyReached;

  /// Nulo é "não sei", e a tela omite. Um zero viraria "o ônibus chegou".
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
