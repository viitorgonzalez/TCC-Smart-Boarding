import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/utils/date_format.dart';

void main() {
  group('formatDate', () {
    test('ISO vira dd/MM/yyyy', () {
      expect(formatDate('2026-07-11'), '11/07/2026');
      expect(formatDate('2026-07-11T16:00:00'), '11/07/2026');
    });

    test('dia e mês de um dígito ganham zero à esquerda', () {
      expect(formatDate('2026-01-05'), '05/01/2026');
    });

    test('nulo e vazio viram travessão', () {
      expect(formatDate(null), '—');
      expect(formatDate(''), '—');
    });

    // Devolver a entrada crua é melhor que quebrar a tela: o usuário vê algo
    // errado em vez de um app que não abre.
    test('string que não parseia volta como veio', () {
      expect(formatDate('nao-e-data'), 'nao-e-data');
    });
  });

  group('formatDateTime', () {
    test('inclui hora e minuto', () {
      expect(formatDateTime('2026-07-11T16:05:00'), '11/07/2026 às 16:05');
    });

    test('meia-noite não vira vazio', () {
      expect(formatDateTime('2026-07-11T00:00:00'), '11/07/2026 às 00:00');
    });

    test('nulo vira travessão', () => expect(formatDateTime(null), '—'));
  });

  group('formatTime', () {
    test('extrai só a hora', () {
      expect(formatTime('2026-07-11T06:30:00'), '06:30');
    });

    test('vazio vira travessão', () => expect(formatTime(''), '—'));
  });

  group('parseTimeOfDay', () {
    test('HH:mm:ss vira hora e minuto', () {
      final r = parseTimeOfDay('16:00:00');
      expect(r?.hour, 16);
      expect(r?.minute, 0);
    });

    test('HH:mm sem segundos também vale', () {
      expect(parseTimeOfDay('06:45')?.minute, 45);
    });

    test('formato inválido devolve null em vez de estourar', () {
      expect(parseTimeOfDay('16'), isNull);
      expect(parseTimeOfDay('ab:cd'), isNull);
      expect(parseTimeOfDay(null), isNull);
      expect(parseTimeOfDay(''), isNull);
    });
  });

  group('timeUntilListClose', () {
    // RN18: o horário vem da rota, não é fixo em 16:00.
    test('antes do fechamento devolve o tempo restante', () {
      final agora = DateTime(2026, 9, 9, 14, 30);
      expect(
        timeUntilListClose('16:00:00', agora),
        const Duration(hours: 1, minutes: 30),
      );
    });

    test('exatamente no horário já conta como fechado', () {
      final agora = DateTime(2026, 9, 9, 16, 0);
      expect(timeUntilListClose('16:00:00', agora), isNull);
    });

    test('depois do fechamento devolve null', () {
      final agora = DateTime(2026, 9, 9, 17, 0);
      expect(timeUntilListClose('16:00:00', agora), isNull);
    });

    test('rota com horário diferente é respeitada', () {
      final agora = DateTime(2026, 9, 9, 16, 30);
      expect(
        timeUntilListClose('18:00:00', agora),
        const Duration(minutes: 90),
      );
    });

    test('horário inválido devolve null', () {
      expect(
        timeUntilListClose('nao-e-hora', DateTime(2026, 9, 9, 10)),
        isNull,
      );
      expect(timeUntilListClose(null, DateTime(2026, 9, 9, 10)), isNull);
    });
  });

  group('formatCloseTime', () {
    test(
      'descarta os segundos',
      () => expect(formatCloseTime('16:00:00'), '16:00'),
    );
    test('inválido vira travessão', () => expect(formatCloseTime('xx'), '—'));
  });

  group('humanizeDuration', () {
    test('menos de uma hora mostra só minutos', () {
      expect(humanizeDuration(const Duration(minutes: 24)), '24min');
    });

    test('mais de uma hora mostra horas e minutos', () {
      expect(
        humanizeDuration(const Duration(hours: 3, minutes: 24)),
        '3h 24min',
      );
    });

    test('minuto de um dígito ganha zero à esquerda', () {
      expect(
        humanizeDuration(const Duration(hours: 1, minutes: 5)),
        '1h 05min',
      );
    });

    test('duração zerada não quebra', () {
      expect(humanizeDuration(Duration.zero), '0min');
    });
  });
}
