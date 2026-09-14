import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/student_sheet.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'role_meta.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  const UserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final meta = metaFor(user.role);
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        // Abrir a ficha e a unica forma de ver instituicao e contato: a linha da
        // lista so cabe nome e e-mail.
        //
        // Mudou papel ou status na ficha, a lista recarrega: o agrupamento e a
        // etiqueta saem do papel, e sem isso o aluno recem-promovido continuaria
        // em "Alunos" ate um pull-to-refresh.
        onTap: () async {
          final changed = await showStudentProfile(context, user.id);
          if (changed && context.mounted) {
            await context.read<UserProvider>().load();
          }
        },
        leading: CircleAvatar(
          backgroundColor: cs.surfaceContainerHighest,
          child: Icon(meta.icon, color: cs.onSurfaceVariant, size: 20),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            meta.singular,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
