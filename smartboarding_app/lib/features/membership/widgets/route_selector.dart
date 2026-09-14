import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/membership_provider.dart';
import '../screens/join_route_screen.dart';

/// Seletor de rota. Só aparece com mais de uma: com uma só, um seletor de um
/// item é ruído — ocupa espaço e não oferece escolha nenhuma.
class RouteSelector extends StatelessWidget {
  const RouteSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MembershipProvider>(
      builder: (context, provider, _) {
        final routes = provider.routes;
        if (routes.length < 2) return const SizedBox.shrink();

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: routes.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == routes.length) {
                return ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Outra rota'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JoinRouteScreen()),
                  ),
                );
              }
              final route = routes[i];
              return ChoiceChip(
                label: Text(route.name),
                selected: provider.selected?.id == route.id,
                onSelected: (_) => provider.select(route.id),
                selectedColor: AppColors.deepTeal.withValues(alpha: 0.18),
              );
            },
          ),
        );
      },
    );
  }
}
