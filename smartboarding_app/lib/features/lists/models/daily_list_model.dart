import '../../../core/utils/date_format.dart';

class DailyList {
  final String id;
  final String routeId;
  final String routeName;
  final String date;
  final String status;
  final int totalEntries;

  /// Inscrição do usuário logado nesta lista (preenchido pela API em /lists).
  final bool enrolled;
  final String? tripType;

  /// Horário de fechamento da rota ("16:00:00"). Varia por rota (RN18).
  final String? closeTime;

  /// Divisão dos inscritos por instituição — uma rota atende várias (RN15).
  final List<InstitutionCount> entriesByInstitution;

  /// Transporte que atende a rota. Capacidade é informação, não teto.
  final List<VehicleSummary> vehicles;

  /// Veículo escolhido no fechamento pelo total de confirmados (RN16).
  final List<VehicleSummary> proposedVehicles;

  /// Inscritos sem lugar na frota. 0 = a frota cobre todo mundo.
  final int capacityShortfall;

  /// Paradas da rota, na ordem — vêm junto pra o card desenhar o trajeto.
  final List<StopPoint> stops;

  /// Trajeto em andamento. Decide se o card oferece "Acompanhar trajeto".
  final bool tripInProgress;

  /// Quanto a viagem leva até a instituição DESTE aluno. Nulo pro admin e
  /// quando o tempo ainda não foi calculado.
  final MyTripTime? myTripTime;

  const DailyList({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.date,
    required this.status,
    required this.totalEntries,
    this.tripInProgress = false,
    this.myTripTime,
    this.enrolled = false,
    this.tripType,
    this.closeTime,
    this.entriesByInstitution = const [],
    this.vehicles = const [],
    this.proposedVehicles = const [],
    this.capacityShortfall = 0,
    this.stops = const [],
  });

  factory DailyList.fromJson(Map<String, dynamic> json) {
    return DailyList(
      id: json['id'] as String,
      routeId: json['routeId'] as String,
      routeName: json['routeName'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      totalEntries: json['totalEntries'] as int,
      enrolled: json['enrolled'] as bool? ?? false,
      tripType: json['tripType'] as String?,
      closeTime: json['closeTime'] as String?,
      entriesByInstitution: (json['entriesByInstitution'] as List? ?? const [])
          .map((e) => InstitutionCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      vehicles: (json['vehicles'] as List? ?? const [])
          .map((e) => VehicleSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      proposedVehicles: (json['proposedVehicles'] as List? ?? const [])
          .map((e) => VehicleSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      capacityShortfall: json['capacityShortfall'] as int? ?? 0,
      stops: (json['stops'] as List? ?? const [])
          .map((e) => StopPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      tripInProgress: json['tripInProgress'] as bool? ?? false,
      myTripTime: json['myTripTime'] == null
          ? null
          : MyTripTime.fromJson(json['myTripTime'] as Map<String, dynamic>),
    );
  }

  bool get isOpen => status == 'OPEN';

  /// Ainda dá pra entrar ou sair. A lista só vira CLOSED na próxima varredura
  /// (até 5 min depois do horário), então olhar só o status deixaria o botão
  /// vivo nessa janela e o toque morreria em 400 LIST_CLOSED.
  ///
  /// Horário desconhecido não é horário vencido: sem closeTime, vale o status.
  bool get acceptsChanges {
    if (!isOpen) return false;
    if (parseTimeOfDay(closeTime) == null) return true;
    return timeUntilListClose(closeTime) != null;
  }
}

class InstitutionCount {
  final String name;
  final int count;

  const InstitutionCount({required this.name, required this.count});

  factory InstitutionCount.fromJson(Map<String, dynamic> json) =>
      InstitutionCount(
        name: json['name'] as String,
        count: json['count'] as int,
      );
}

class VehicleSummary {
  final String label;
  final int capacity;

  const VehicleSummary({required this.label, required this.capacity});

  factory VehicleSummary.fromJson(Map<String, dynamic> json) => VehicleSummary(
    label: json['label'] as String,
    capacity: json['capacity'] as int,
  );
}

class StopPoint {
  final String name;
  final double? latitude;
  final double? longitude;
  final int sequence;

  const StopPoint({
    required this.name,
    required this.sequence,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory StopPoint.fromJson(Map<String, dynamic> json) => StopPoint(
    name: json['name'] as String,
    sequence: json['sequence'] as int,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}

/// O tempo médio da viagem até a parada do aluno.
///
/// O nome do destino vem junto porque dois alunos da mesma rota veem números
/// diferentes: sem dizer até onde, quem compara com o colega conclui que o app
/// está errado.
class MyTripTime {
  final String stopName;
  final int avgMinutes;

  /// A instituição do aluno não tem parada declarada e este é o último ponto
  /// do trajeto — a tela precisa avisar.
  final bool fallback;

  const MyTripTime({
    required this.stopName,
    required this.avgMinutes,
    this.fallback = false,
  });

  factory MyTripTime.fromJson(Map<String, dynamic> json) => MyTripTime(
    stopName: json['stopName'] as String,
    avgMinutes: json['avgMinutes'] as int,
    fallback: json['fallback'] as bool? ?? false,
  );
}
