import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/users/models/student_profile_model.dart';

Map<String, dynamic> perfil({Object? address}) => {
  'id': 'u1',
  'fullName': 'Vítor Silva Pastor Gonzalez',
  'email': 'vitor@student.com',
  'phone': '37988888888',
  'address': address,
  'birthDate': '2000-05-15',
  'course': 'Computer Science',
  'institution': 'UNIFOR-MG',
  'isActive': true,
  'role': 'STUDENT',
  'recentAttendance': ['2026-10-14'],
  'statusHistory': <Map<String, dynamic>>[],
};

void main() {
  group('endereço no perfil que o admin abre', () {
    test('endereço estruturado vira a linha completa', () {
      final p = StudentProfile.fromJson(
        perfil(
          address: {
            'zipCode': '35570-000',
            'street': 'Av. Dr. Arnaldo de Senna',
            'neighborhood': 'Água Vermelha',
            'city': 'Formiga',
            'state': 'MG',
            'streetNumber': '328',
            'complement': null,
            'complete': true,
            'shortForm': 'Av. Dr. Arnaldo de Senna, 328 — Água Vermelha',
            'fullForm':
                'Av. Dr. Arnaldo de Senna, 328 — Água Vermelha, Formiga/MG — 35570-000',
          },
        ),
      );

      expect(p.address, contains('Formiga/MG'));
      expect(p.address, contains('35570-000'));
    });

    test('endereço vazio não vira texto em branco na tela', () {
      final p = StudentProfile.fromJson(
        perfil(
          address: {
            'zipCode': null,
            'street': null,
            'complete': false,
            'shortForm': '',
            'fullForm': '',
          },
        ),
      );

      expect(p.address, isNull);
    });

    test('ausência de endereço continua sendo nulo', () {
      expect(StudentProfile.fromJson(perfil()).address, isNull);
    });

    test('texto livre antigo ainda é aceito', () {
      final p = StudentProfile.fromJson(
        perfil(address: 'Rua de antes do cadastro estruturado, 10'),
      );

      expect(p.address, 'Rua de antes do cadastro estruturado, 10');
    });

    test('o resto do perfil é lido junto', () {
      final p = StudentProfile.fromJson(perfil(address: {'fullForm': 'Rua A'}));

      expect(p.fullName, 'Vítor Silva Pastor Gonzalez');
      expect(p.institution, 'UNIFOR-MG');
      expect(p.recentAttendance, ['2026-10-14']);
    });
  });
}
