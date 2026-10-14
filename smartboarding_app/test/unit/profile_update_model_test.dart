import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/profile/models/profile_update_model.dart';

void main() {
  Map<String, dynamic> payload({Map<String, dynamic>? before}) => {
    'id': 'req-1',
    'userId': 'aluno-1',
    'studentName': 'Fernanda Lima',
    'phone': '37988887777',
    'zipCode': '35570-000',
    'street': 'Av. Dr. Arnaldo de Senna',
    'neighborhood': 'Água Vermelha',
    'streetNumber': '328',
    'status': 'PENDING',
    'before': before,
  };

  group('ProfileBefore.fromJson', () {
    test('nulo vira tudo vazio', () {
      final before = ProfileBefore.fromJson(null);

      expect(before.fullName, isNull);
      expect(before.address, isNull);
    });

    test('endereco so aparece quando algum campo veio', () {
      final before = ProfileBefore.fromJson({
        'phone': '37911112222',
        'street': 'Rua Antiga',
        'neighborhood': 'Centro',
      });

      expect(before.phone, '37911112222');
      expect(before.address?.street, 'Rua Antiga');
    });
  });

  group('ProfileUpdate.diffs', () {
    test('so entra o que foi pedido, cada um com antes e depois', () {
      final update = ProfileUpdate.fromJson(
        payload(before: {'phone': '37911112222'}),
      );

      final diffs = update.diffs;

      expect(diffs.map((d) => d.label), containsAll(['Telefone', 'Endereço']));
      expect(
        diffs,
        isNot(
          contains(
            isA<ProfileFieldDiff>().having((d) => d.label, 'label', 'Curso'),
          ),
        ),
      );
      final telefone = diffs.firstWhere((d) => d.label == 'Telefone');
      expect(telefone.before, '37911112222');
      expect(telefone.after, '37988887777');
    });

    test('sem valor anterior mostra travessao em vez de quebrar', () {
      final update = ProfileUpdate.fromJson(payload());

      final telefone = update.diffs.firstWhere((d) => d.label == 'Telefone');

      expect(telefone.before, '—');
      expect(telefone.after, '37988887777');
    });

    test('endereco compara o resumo antes e depois', () {
      final update = ProfileUpdate.fromJson(
        payload(
          before: {
            'street': 'Rua Antiga',
            'streetNumber': '10',
            'neighborhood': 'Centro',
          },
        ),
      );

      final endereco = update.diffs.firstWhere((d) => d.label == 'Endereço');

      expect(endereco.before, 'Rua Antiga, 10, Centro');
      expect(endereco.after, 'Av. Dr. Arnaldo de Senna, 328, Água Vermelha');
    });
  });
}
