import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/async_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entity_list_tile.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../../core/widgets/status_pill.dart';
import '../../lists/models/daily_list_model.dart';
import '../../lists/services/list_service.dart';
import '../models/route_model.dart';
import '../providers/route_provider.dart';
import 'route_detail_screen.dart';
import 'route_form_screen.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  /// Lista de hoje por rota. O admin precisa ver o estado da lista sem entrar
  /// em cada rota — é o resumo que a tela separada de listas dava antes.
  Map<String, DailyList> _todayLists = const {};

  @override
  void initState() {
    super.initState();
    _loadTodayLists();
  }

  Future<void> _loadTodayLists() async {
    try {
      final lists = await ListService().getListsByDate(DateTime.now());
      if (!mounted) return;
      setState(() => _todayLists = {for (final l in lists) l.routeId: l});
    } catch (_) {
      // O resumo é acessório: falhar aqui não pode esconder as rotas.
    }
  }

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
                  onRefresh: () async {
                    await Future.wait([provider.load(), _loadTodayLists()]);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: routes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _RouteTile(
                      route: routes[i],
                      todayList: _todayLists[routes[i].id],
                      onOpen: () => _openForm(context, provider, routes[i]),
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
          // Rota nova usa o formulário mínimo (só precisa de nome); editar abre
          // a tela completa, com paradas, frota e instituições.
          child: route == null
              ? const RouteFormScreen()
              : RouteDetailScreen(route: route),
        ),
      ),
    );
    if (mounted) await _loadTodayLists();
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
  final DailyList? todayList;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _RouteTile({
    required this.route,
    required this.todayList,
    required this.onOpen,
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
      subtitle: Text(
        todayList == null
            ? 'Sem lista hoje'
            : '${todayList!.totalEntries} inscrito(s) hoje',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (todayList != null)
            StatusPill(
              label: todayList!.isOpen ? 'Aberta' : 'Fechada',
              tone: todayList!.isOpen
                  ? StatusPillTone.positive
                  : StatusPillTone.neutral,
            ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onOpen,
    );
  }
}
