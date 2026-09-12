import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/users/widgets/student_profile_card.dart';

/// Abre o perfil breve do aluno. Existe no core porque três telas diferentes
/// precisam do mesmo gesto: a lista de usuários, a lista de alunos da rota e os
/// inscritos do dia.
///
/// Devolve `true` quando a folha mudou o status ou o papel da conta. A folha só
/// atualiza o estado dela, então sem esse aviso a lista de trás continuaria
/// mostrando o aluno recém-promovido no grupo antigo até um pull-to-refresh.
Future<bool> showStudentProfile(BuildContext context, String userId) async {
  // Fechar arrastando ou tocando fora não passa valor nenhum pro pop, então a
  // mudança é registrada por callback em vez do resultado da rota.
  var changed = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) =>
        StudentProfileSheet(userId: userId, onChanged: () => changed = true),
  );
  return changed;
}
