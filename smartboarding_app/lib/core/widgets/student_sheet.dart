import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/users/widgets/student_profile_card.dart';

/// Abre o perfil breve do aluno. Existe no core porque duas telas diferentes
/// precisam do mesmo gesto: a lista de alunos da rota e os inscritos do dia.
Future<void> showStudentProfile(BuildContext context, String userId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => StudentProfileSheet(userId: userId),
  );
}
