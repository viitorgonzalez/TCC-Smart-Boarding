import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../screens/join_route_screen.dart';

/// Estado de quem acabou de criar a conta: existe no sistema, mas ainda não
/// pertence a rota nenhuma. Sem isso a home ficaria vazia e sem explicação.
class NoRouteCard extends StatelessWidget {
  const NoRouteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alt_route_outlined,
                color: AppColors.deepTeal,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Você ainda não está em uma rota',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Peça o código ao administrador para ver a lista do dia.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('no_route_join_button'),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const JoinRouteScreen())),
            icon: const Icon(Icons.login),
            label: const Text('Entrar com código'),
          ),
        ],
      ),
    );
  }
}
