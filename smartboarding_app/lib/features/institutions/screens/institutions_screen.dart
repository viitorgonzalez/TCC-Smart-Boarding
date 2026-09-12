import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../routes/models/route_model.dart';
import '../models/institution_model.dart';
import '../providers/institution_provider.dart';
import '../widgets/institution_form.dart';

/// Catálogo de instituições. É aqui que elas nascem e são editadas; a tela da
/// rota apenas escolhe entre as que existem.
class InstitutionsScreen extends StatelessWidget {
  /// Rotas só para exibir o nome de quem atende cada instituição.
  final List<RouteModel> routes;

  const InstitutionsScreen({super.key, this.routes = const []});

  String? _routeName(String? routeId) {
    if (routeId == null) return null;
    for (final r in routes) {
      if (r.id == routeId) return r.name;
    }
    return null;
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() acao,
    String sucesso,
  ) async {
    try {
      await acao();
      if (context.mounted) {
        showSuccessSnackBar(context, sucesso);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, AppException.fromError(e));
      }
    }
  }

  Future<void> _criar(BuildContext context) async {
    final dados = await showInstitutionForm(context);
    if (dados == null || !context.mounted) return;
    await _run(
      context,
      () => context.read<InstitutionProvider>().create(
        dados.name,
        address: dados.address,
      ),
      'Instituição cadastrada',
    );
  }

  Future<void> _editar(BuildContext context, InstitutionModel i) async {
    final dados = await showInstitutionForm(context, existente: i);
    if (dados == null || !context.mounted) return;
    await _run(
      context,
      () => context.read<InstitutionProvider>().update(
        i.id,
        name: dados.name,
        address: dados.address,
      ),
      'Instituição atualizada',
    );
  }

  Future<void> _remover(BuildContext context, InstitutionModel i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover ${i.name}?'),
        content: const Text(
          'Alunos vinculados a ela impedem a remoção — o backend recusa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(
      context,
      () => context.read<InstitutionProvider>().remove(i.id),
      'Instituição removida',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('institutions_add_button'),
        onPressed: () => _criar(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova instituição'),
      ),
      body: Consumer<InstitutionProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (institutions) => institutions.isEmpty
              ? const EmptyState(
                  icon: Icons.school_outlined,
                  title: 'Nenhuma instituição cadastrada',
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: institutions.length,
                    itemBuilder: (_, i) {
                      final inst = institutions[i];
                      final rota = _routeName(inst.routeId);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.school,
                            color: AppColors.deepTeal,
                          ),
                          title: Text(inst.name),
                          subtitle: Text(
                            // Sem rota o aluno dessa instituição não enxerga
                            // lista nenhuma; dizer isso evita o mistério.
                            rota == null
                                ? 'Sem rota atendendo'
                                : 'Atendida por $rota',
                            style: TextStyle(
                              color: rota == null
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => v == 'edit'
                                ? _editar(context, inst)
                                : _remover(context, inst),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Remover'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
