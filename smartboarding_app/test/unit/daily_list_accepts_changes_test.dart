import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/lists/models/daily_list_model.dart';

DailyList lista({required String status, String? closeTime}) =>
    DailyList.fromJson({
      'id': 'lista-1',
      'routeId': 'rota-1',
      'routeName': 'Rota Universitária',
      'date': '2026-09-12',
      'status': status,
      'closeTime': closeTime,
      'totalEntries': 0,
    });

void main() {
  test('lista fechada não aceita mudança', () {
    expect(
      lista(status: 'CLOSED', closeTime: '23:59:00').acceptsChanges,
      isFalse,
    );
    expect(lista(status: 'CLOSED').acceptsChanges, isFalse);
  });

  test('lista aberta dentro do horário aceita', () {
    expect(lista(status: 'OPEN', closeTime: '23:59:00').acceptsChanges, isTrue);
  });

  // Sem closeTime nao da pra afirmar que venceu; o status e a unica informacao
  // disponivel, e derrubar o botao por falta de dado seria pior.
  test('sem horário de fechamento vale o status', () {
    expect(lista(status: 'OPEN').acceptsChanges, isTrue);
    expect(lista(status: 'OPEN', closeTime: '').acceptsChanges, isTrue);
  });

  // O agendador so marca CLOSED na varredura seguinte (ate 5 min depois). Nessa
  // janela o status ainda diz OPEN, mas entrar ja morre em 400 LIST_CLOSED.
  test('horário vencido não aceita, mesmo com status OPEN', () {
    expect(
      lista(status: 'OPEN', closeTime: '00:00:00').acceptsChanges,
      isFalse,
    );
  });

  test('horário inválido não derruba o parsing', () {
    expect(
      lista(status: 'OPEN', closeTime: 'nao-e-hora').acceptsChanges,
      isTrue,
    );
  });
}
