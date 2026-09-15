import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../institutions/providers/institution_provider.dart';
import '../../../core/widgets/async_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../lists/models/daily_list_model.dart';
import '../../lists/services/list_service.dart';
import '../models/route_model.dart';
import '../providers/route_provider.dart';
import 'route_detail_screen.dart';
import 'route_form_screen.dart';
import '../../../core/widgets/app_list_group.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/text/plural.dart';

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
                  icon: Icons.route_outlined,
                  title: 'Nenhuma rota cadastrada',
                  subtitle: 'Toque + para criar a primeira rota',
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([provider.load(), _loadTodayLists()]);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    children: [
                      AppListGroup(
                        dividerIndent: 68,
                        children: [
                          for (final route in routes)
                            _RouteTile(
                              route: route,
                              todayList: _todayLists[route.id],
                              onOpen: () => _openForm(context, provider, route),
                              onDelete: () =>
                                  _confirmDelete(context, provider, route),
                            ),
                        ],
                      ),
                    ],
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
    // O push nasce no Navigator, acima de qualquer provider desta tela: o que
    // nao for repassado aqui nao chega la. Faltando o InstitutionProvider, a
    // secao "Instituicoes atendidas" do detalhe estourava ProviderNotFound.
    final institutionProvider = context.read<InstitutionProvider>();

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: institutionProvider),
          ],
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

  String get _resumo {
    final lista = todayList;
    if (lista == null) return 'Sem lista hoje';
    return contagem(
      lista.totalEntries,
      'inscrito hoje',
      'inscritos hoje',
      zero: 'Ninguém inscrito hoje',
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = todayList;
    final texto = Theme.of(context).textTheme;

    return AppListItem(
      leading: const Icon(Icons.route_outlined, color: AppColors.deepTeal),
      title: route.name,
      // Estado no subtitulo, e nao numa pilula a direita: a pilula disputava
      // largura com o nome da rota e quebrava "Rota Universitaria de Formiga"
      // em duas linhas.
      subtitleChild: Row(
        children: [
          if (lista != null)
            StatusDot(
              lista.isOpen ? AppColors.positiveFg : AppColors.textSecondary,
            ),
          Expanded(
            child: Text(
              lista == null
                  ? _resumo
                  : '${lista.isOpen ? 'Aberta' : 'Fechada'} · $_resumo',
              style: texto.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      menu: [
        destructiveMenuItem(
          label: 'Excluir rota',
          icon: Icons.delete_outline,
          onSelected: onDelete,
        ),
      ],
      onTap: onOpen,
    );
  }
}
