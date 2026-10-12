import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../users/models/user_model.dart';
import '../../users/screens/route_students_screen.dart';
import '../../users/widgets/role_meta.dart';

/// Seção "Alunos" do detalhe da rota: prévia dos quatro primeiros e atalho
/// pra lista completa.
class RouteStudentsCard extends StatelessWidget {
  final List<UserModel> students;
  final String routeId;
  final String routeName;

  const RouteStudentsCard({
    super.key,
    required this.students,
    required this.routeId,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final preview = sortUsersByName(students).take(4).toList();

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          if (students.isEmpty)
            const ListTile(
              title: Text('Nenhum aluno nesta rota'),
              subtitle: Text(
                'O aluno chega por convite e escolhe a instituição no cadastro.',
              ),
            ),
          for (final student in preview)
            ListTile(
              leading: InitialsAvatar(
                text: student.fullName.isNotEmpty
                    ? student.fullName[0].toUpperCase()
                    : '?',
              ),
              title: Text(student.fullName),
              subtitle: Text(student.institution ?? student.email),
            ),
          if (students.isNotEmpty) const Divider(height: 1),
          if (students.isNotEmpty)
            ListTile(
              leading: const Icon(
                Icons.people_outline,
                color: AppColors.deepTeal,
              ),
              title: Text(
                students.length == 1
                    ? 'Ver o aluno da rota'
                    : 'Ver todos os ${students.length} alunos',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteStudentsScreen(
                    routeId: routeId,
                    routeName: routeName,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
