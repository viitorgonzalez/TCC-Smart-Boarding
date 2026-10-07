import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/lists/models/list_entry_model.dart';

void main() {
  Map<String, dynamic> payload({bool comEmail = true}) => {
    'id': 'entry-1',
    'userId': 'aluno-1',
    'fullName': 'Fernanda Lima',
    if (comEmail) 'email': 'fernanda@edu.unifor.br',
    'tripType': 'ROUND_TRIP',
    'createdAt': '2026-09-09T06:10:00',
    'institutionName': 'Unifor',
  };

  test('admin recebe o e-mail do inscrito', () {
    final entry = ListEntry.fromJson(payload());

    expect(entry.email, 'fernanda@edu.unifor.br');
    expect(entry.fullName, 'Fernanda Lima');
  });

  test('aluno recebe a lista sem e-mail e o parsing nao quebra', () {
    final entry = ListEntry.fromJson(payload(comEmail: false));

    expect(entry.email, isNull);
    expect(entry.fullName, 'Fernanda Lima');
    expect(entry.institutionName, 'Unifor');
  });

  test('e-mail explicitamente nulo tambem passa', () {
    final entry = ListEntry.fromJson({...payload(), 'email': null});

    expect(entry.email, isNull);
  });

  test('marca quando foi o admin quem incluiu', () {
    final entry = ListEntry.fromJson({...payload(), 'addedByAdmin': true});

    expect(entry.addedByAdmin, isTrue);
  });

  test('sem o campo, assume que nao foi o admin', () {
    final entry = ListEntry.fromJson(payload());

    expect(entry.addedByAdmin, isFalse);
  });
}
