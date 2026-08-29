import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';

/// Janela da lista. O aviso de que alterar notifica a rota fica junto do
/// horário de propósito: é a consequência da ação que está ali do lado.
class DailyListScheduleCard extends StatelessWidget {
  final String? openTime;
  final String? closeTime;
  final VoidCallback onEdit;

  const DailyListScheduleCard({
    super.key,
    required this.openTime,
    required this.closeTime,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.deepTeal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abre ${formatCloseTime(openTime)} · '
                  'fecha ${formatCloseTime(closeTime)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Mudar o horário avisa a rota',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Alterar')),
        ],
      ),
    );
  }
}
