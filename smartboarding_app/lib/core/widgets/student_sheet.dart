import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/users/widgets/student_profile_card.dart';

Future<bool> showStudentProfile(BuildContext context, String userId) async {
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
