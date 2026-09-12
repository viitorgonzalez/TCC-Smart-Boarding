import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../models/student_profile_model.dart';

/// Bloco de contato da ficha. Campo vazio some em vez de mostrar rótulo com
/// travessão — linha em branco só ocupa espaço e não informa nada.
class ProfileInfoRows extends StatelessWidget {
  final StudentProfile profile;

  const ProfileInfoRows({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String)>[
      if (_has(profile.email)) (Icons.mail_outline, profile.email!),
      if (_has(profile.phone)) (Icons.phone_outlined, profile.phone!),
      if (_has(profile.address)) (Icons.place_outlined, profile.address!),
      if (_has(profile.birthDate))
        (Icons.cake_outlined, formatDate(profile.birthDate)),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icon, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;
}
