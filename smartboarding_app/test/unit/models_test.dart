import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/trip/models/trip_status_model.dart';
import 'package:smartboarding_app/features/users/models/student_profile_model.dart';

TripStatus _trip({
  String? startedAt,
  String? finishedAt,
  List<Map<String, dynamic>> stops = const [],
}) => TripStatus.fromJson({
  'listId': 'lista-1',
  'routeName': 'Rota Universitária',
  'startedAt': startedAt,
  'finishedAt': finishedAt,
  'stops': stops,
});

Map<String, dynamic> _stop(String name, int seq, {String? reachedAt}) => {
  'stopId': 'parada-$seq',
  'name': name,
  'sequence': seq,
  'reachedAt': reachedAt,
};

void main() {
  group('TripStatus: estado do trajeto', () {
    test('sem startedAt está por começar', () {
      final t = _trip();
      expect(t.notStarted, isTrue);
      expect(t.inProgress, isFalse);
      expect(t.finished, isFalse);
    });

    test('com startedAt e sem finishedAt está em andamento', () {
      final t = _trip(startedAt: '2026-09-09T06:00:00');
      expect(t.inProgress, isTrue);
      expect(t.notStarted, isFalse);
      expect(t.finished, isFalse);
    });

    test('com finishedAt está encerrado e não em andamento', () {
      final t = _trip(
        startedAt: '2026-09-09T06:00:00',
        finishedAt: '2026-09-09T07:30:00',
      );
      expect(t.finished, isTrue);
      expect(t.inProgress, isFalse);
    });
  });

  group('TripStatus.current: qual parada ganha o botão', () {
    // Um "Marcar" por vez: se todas as pendentes ganhassem botão, dava pra
    // marcar a última antes da primeira e furar a ordem do trajeto.
    test('é a primeira ainda não alcançada', () {
      final t = _trip(
        startedAt: '2026-09-09T06:00:00',
        stops: [
          _stop('Rodoviária', 1, reachedAt: '2026-09-09T06:10:00'),
          _stop('Centro', 2),
          _stop('Unifor', 3),
        ],
      );
      expect(t.current?.name, 'Centro');
    });

    test('todas alcançadas devolve null', () {
      final t = _trip(
        startedAt: '2026-09-09T06:00:00',
        stops: [
          _stop('Rodoviária', 1, reachedAt: '2026-09-09T06:10:00'),
          _stop('Unifor', 2, reachedAt: '2026-09-09T06:50:00'),
        ],
      );
      expect(t.current, isNull);
    });

    test('trajeto não iniciado não tem parada atual', () {
      final t = _trip(stops: [_stop('Rodoviária', 1)]);
      expect(t.current, isNull);
    });

    test('trajeto encerrado não tem parada atual', () {
      final t = _trip(
        startedAt: '2026-09-09T06:00:00',
        finishedAt: '2026-09-09T07:30:00',
        stops: [_stop('Rodoviária', 1)],
      );
      expect(t.current, isNull);
    });
  });

  group('TripStop', () {
    test('reachedAt preenchido marca como alcançada', () {
      final s = TripStop.fromJson(
        _stop('Rodoviária', 1, reachedAt: '2026-09-09T06:10:00'),
      );
      expect(s.reached, isTrue);
      expect(s.sequence, 1);
    });

    test('sem reachedAt não está alcançada', () {
      expect(TripStop.fromJson(_stop('Centro', 2)).reached, isFalse);
    });
  });

  test('TripStatus sem a chave stops não quebra', () {
    final t = TripStatus.fromJson({'listId': 'l', 'routeName': 'R'});
    expect(t.stops, isEmpty);
    expect(t.current, isNull);
  });

  group('StudentProfile', () {
    test('parseia o perfil completo', () {
      final p = StudentProfile.fromJson({
        'id': 'aluno-1',
        'fullName': 'Fernanda Lima',
        'course': 'Engenharia',
        'institution': 'Unifor',
        'isActive': false,
        'recentAttendance': ['2026-09-08', '2026-09-09'],
        'statusHistory': [
          {
            'action': 'DEACTIVATED',
            'adminName': 'Naiara',
            'at': '2026-09-09T10:30:00',
          },
        ],
      });

      expect(p.fullName, 'Fernanda Lima');
      expect(p.isActive, isFalse);
      expect(p.recentAttendance, hasLength(2));
      expect(p.statusHistory.first.adminName, 'Naiara');
      expect(p.statusHistory.first.activated, isFalse);
    });

    // A API só manda o que o card precisa. Campos opcionais ausentes não podem
    // derrubar o parsing.
    test('campos opcionais ausentes não quebram', () {
      final p = StudentProfile.fromJson({
        'id': 'aluno-1',
        'fullName': 'Fernanda Lima',
      });

      expect(p.course, isNull);
      expect(p.institution, isNull);
      expect(p.recentAttendance, isEmpty);
      expect(p.statusHistory, isEmpty);
    });

    test('isActive ausente assume ativo', () {
      final p = StudentProfile.fromJson({'id': 'a', 'fullName': 'F'});
      expect(p.isActive, isTrue);
    });

    test('ACTIVATED marca activated', () {
      final c = StatusChange.fromJson({
        'action': 'ACTIVATED',
        'at': '2026-09-09T10:30:00',
      });
      expect(c.activated, isTrue);
      expect(c.adminName, isNull);
    });
  });
}
