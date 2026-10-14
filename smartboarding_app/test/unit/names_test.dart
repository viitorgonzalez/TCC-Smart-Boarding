import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/text/names.dart';

void main() {
  test('devolve o primeiro nome de um nome completo', () {
    expect(primeiroNome('Vítor Silva Pastor Gonzalez'), 'Vítor');
  });

  test('nome de uma palavra so fica como esta', () {
    expect(primeiroNome('Ana'), 'Ana');
  });

  test('ignora espaco sobrando nas pontas e no meio', () {
    expect(primeiroNome('  Ana  Maria '), 'Ana');
  });

  test('vazio devolve o rotulo de reserva', () {
    expect(primeiroNome('', fallback: 'Aluno'), 'Aluno');
    expect(primeiroNome('   ', fallback: 'Aluno'), 'Aluno');
  });

  test('nulo devolve o rotulo de reserva', () {
    expect(primeiroNome(null, fallback: 'Aluno'), 'Aluno');
  });
}
