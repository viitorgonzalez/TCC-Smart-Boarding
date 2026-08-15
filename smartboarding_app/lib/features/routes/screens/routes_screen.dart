import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/async_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entity_list_tile.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/route_model.dart';
import '../providers/route_provider.dart';
import 'route_form_screen.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, provider, _) => Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openForm(context, provider),
          tooltip: 'Nova rota',
          child: const Icon(Icons.add),
        ),
        body: AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (routes) => routes.isEmpty
              ? const EmptyState(
                  icon: Icons.route,
                  title: 'Nenhuma rota cadastrada',
                  subtitle: 'Toque + para criar a primeira rota',
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: routes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _RouteTile(
                      route: routes[i],
                      onEdit: () => _openForm(context, provider, routes[i]),
                      onDelete: () =>
                          _confirmDelete(context, provider, routes[i]),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    RouteProvider provider, [
    RouteModel? route,
  ]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: RouteFormScreen(route: route),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RouteProvider provider,
    RouteModel route,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir rota'),
        content: Text(
          'Excluir "${route.name}"?\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await provider.delete(route.id);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, e.toString());
    }
  }
}

// ─── Tile de rota ─────────────────────────────────────────────────────────────

class _RouteTile extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RouteTile({
    required this.route,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return EntityListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
      ),
      title: route.name,
      subtitle: route.description?.isNotEmpty == true
          ? Text(
              route.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
