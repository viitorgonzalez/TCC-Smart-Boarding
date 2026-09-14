import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

/// Rota sem lista hoje. O agendador cria no horário de abertura, mas o admin
/// precisa do caminho manual para data extra e correção.
class NoListTodayCard extends StatelessWidget {
  final VoidCallback onCreate;

  const NoListTodayCard({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ainda não há lista para hoje.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'O agendador cria no horário de abertura — ou crie agora.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Criar lista de hoje'),
          ),
        ],
      ),
    );
  }
}
