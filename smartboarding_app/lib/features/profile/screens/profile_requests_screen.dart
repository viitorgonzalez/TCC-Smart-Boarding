import 'package:flutter/material.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/async_value.dart';
import '../../../core/widgets/app_list_group.dart';
import '../../../core/widgets/async_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/profile_update_model.dart';
import '../services/profile_service.dart';
import '../widgets/profile_request_sheet.dart';

class ProfileRequestsScreen extends StatefulWidget {
  const ProfileRequestsScreen({super.key});

  @override
  State<ProfileRequestsScreen> createState() => _ProfileRequestsScreenState();
}

enum _Filtro { pendentes, aprovados, rejeitados, todos }

class _ProfileRequestsScreenState extends State<ProfileRequestsScreen> {
  final _service = ProfileService();
  AsyncValue<List<ProfileUpdate>> _state = const AsyncLoading();
  _Filtro _filtro = _Filtro.pendentes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const AsyncLoading());
    try {
      final pedidos = await _service.allRequests();
      if (!mounted) return;
      setState(() => _state = AsyncData(pedidos));
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = AsyncError(AppException.fromError(e)));
    }
  }

  bool _combina(ProfileUpdate p) => switch (_filtro) {
    _Filtro.pendentes => p.pending,
    _Filtro.aprovados => p.status == 'APPROVED',
    _Filtro.rejeitados => p.rejected,
    _Filtro.todos => true,
  };

  Future<void> _aprovar(ProfileUpdate p) async {
    try {
      await _service.approve(p.id);
      if (mounted) showSuccessSnackBar(context, 'Solicitação aprovada');
      await _load();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  Future<void> _rejeitar(ProfileUpdate p) async {
    final motivo = await _pedirMotivo();
    if (motivo == null || motivo.trim().isEmpty || !mounted) return;
    try {
      await _service.reject(p.id, motivo.trim());
      if (mounted) showSuccessSnackBar(context, 'Solicitação recusada');
      await _load();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  Future<String?> _pedirMotivo() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recusar solicitação'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'É o que o aluno vê pra saber o que corrigir',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirDetalhe(ProfileUpdate p) async {
    if (!p.pending) return;
    final acao = await mostrarDetalheDaSolicitacao(context, p);
    if (acao == 'aprovar') await _aprovar(p);
    if (acao == 'rejeitar') await _rejeitar(p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitações de perfil')),
      body: AsyncBuilder(
        value: _state,
        onRetry: _load,
        builder: (todos) {
          int contar(_Filtro f) => todos.where((p) => _combinaCom(p, f)).length;

          final filtrados = todos.where(_combina).toList();

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    for (final f in _Filtro.values) ...[
                      if (f != _Filtro.pendentes) const SizedBox(width: 8),
                      FilterChip(
                        label: Text('${_rotulo(f)} (${contar(f)})'),
                        selected: _filtro == f,
                        onSelected: (_) => setState(() => _filtro = f),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtrados.isEmpty
                    ? EmptyState(
                        icon: Icons.inbox_outlined,
                        title:
                            'Nenhuma solicitação ${_rotulo(_filtro).toLowerCase()}',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            AppListGroup(
                              dividerIndent: 68,
                              children: [
                                for (final p in filtrados)
                                  AppListItem(
                                    leading: Icon(
                                      _iconeDe(p),
                                      color: _corDe(p),
                                    ),
                                    title: p.studentName ?? 'Aluno',
                                    subtitle: p.changes.entries
                                        .map((e) => '${e.key}: ${e.value}')
                                        .join(' · '),
                                    trailing: p.pending
                                        ? const Icon(Icons.chevron_right)
                                        : null,
                                    onTap: () => _abrirDetalhe(p),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _combinaCom(ProfileUpdate p, _Filtro f) => switch (f) {
    _Filtro.pendentes => p.pending,
    _Filtro.aprovados => p.status == 'APPROVED',
    _Filtro.rejeitados => p.rejected,
    _Filtro.todos => true,
  };

  static String _rotulo(_Filtro f) => switch (f) {
    _Filtro.pendentes => 'Pendentes',
    _Filtro.aprovados => 'Aprovados',
    _Filtro.rejeitados => 'Rejeitados',
    _Filtro.todos => 'Todos',
  };

  static IconData _iconeDe(ProfileUpdate p) => switch (p.status) {
    'APPROVED' => Icons.check_circle_outline,
    'REJECTED' => Icons.cancel_outlined,
    _ => Icons.hourglass_top,
  };

  static Color _corDe(ProfileUpdate p) => switch (p.status) {
    'APPROVED' => AppColors.positiveFg,
    'REJECTED' => AppColors.danger,
    _ => AppColors.deepTeal,
  };
}
