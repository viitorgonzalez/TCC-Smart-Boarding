import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../institutions/models/institution_model.dart';
import '../../institutions/services/institution_service.dart';
import '../models/invite_code_model.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';
import '../../../core/text/plural.dart';

/// Controle dos códigos de acesso, de todas as rotas do admin.
///
/// Tela própria porque o código é a porta de entrada da rota, e essa decisão
/// não pertence ao dia a dia de uma rota específica: dentro do detalhe ela
/// ficava soterrada sob lista de presença, veículos e paradas.
class InviteCodesScreen extends StatefulWidget {
  /// As rotas do admin. Vem pronta pra tela não repetir a busca que o painel
  /// já fez ao abrir.
  final List<RouteModel> routes;

  const InviteCodesScreen({super.key, required this.routes});

  @override
  State<InviteCodesScreen> createState() => _InviteCodesScreenState();
}

class _InviteCodesScreenState extends State<InviteCodesScreen> {
  final _service = RouteService();
  final _catalogo = InstitutionService();

  List<InviteCode> _codes = const [];
  bool _carregando = true;
  bool _ocupado = false;

  /// Ids marcados. Vazio com [_selecionando] ligado é o estado logo após entrar
  /// no modo — o admin ainda não escolheu nada.
  final Set<String> _marcados = {};
  bool _selecionando = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codes = await _service.getAllInviteCodes();
      if (mounted) setState(() => _codes = codes);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<T?> _escolher<T>(String titulo, List<(String, String, T)> opcoes) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(titulo, style: Theme.of(ctx).textTheme.titleMedium),
              ),
              for (final (rotulo, detalhe, valor) in opcoes)
                ListTile(
                  key: Key('opcao_$rotulo'),
                  title: Text(rotulo),
                  subtitle: detalhe.isEmpty ? null : Text(detalhe),
                  onTap: () => Navigator.pop(ctx, valor),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _gerar() async {
    final rota = widget.routes.length == 1
        ? widget.routes.single
        : await _escolher<RouteModel>('Para qual rota?', [
            for (final r in widget.routes) (r.name, '', r),
          ]);
    if (rota == null || !mounted) return;

    final validade = await _escolher<CodeValidity>(
      'Por quanto tempo o código vale?',
      [for (final v in CodeValidity.values) (v.label, '', v)],
    );
    if (validade == null || !mounted) return;

    List<InstitutionModel> instituicoes;
    try {
      instituicoes = await _catalogo.getInstitutions();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
      return;
    }
    if (!mounted) return;

    final instituicao = await _escolher<String>('Quem pode usar esse código?', [
      (
        'Qualquer instituição',
        'Vale pra aluno de qualquer instituição cadastrada no app',
        '',
      ),
      for (final i in instituicoes)
        (i.name, 'Só alunos dessa instituição', i.id),
    ]);
    if (instituicao == null || !mounted) return;

    setState(() => _ocupado = true);
    try {
      final novo = await _service.generateInviteCode(
        rota.id,
        expiresAt: validade.expiresFrom(DateTime.now()),
        // String vazia é a escolha "qualquer instituição"; nulo seria
        // indistinguível de ter fechado a folha sem escolher.
        institutionId: instituicao.isEmpty ? null : instituicao,
      );
      await Clipboard.setData(ClipboardData(text: novo.code));
      await _load();
      if (mounted) {
        showSuccessSnackBar(context, 'Código ${novo.code} criado e copiado');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _alternarSelecao(String id) {
    setState(() {
      if (!_marcados.remove(id)) _marcados.add(id);
      // Desmarcar o último sai do modo: manter a barra de seleção vazia na
      // tela deixa o admin preso num estado sem saída óbvia.
      if (_marcados.isEmpty) _selecionando = false;
    });
  }

  void _entrarNaSelecao(String id) {
    setState(() {
      _selecionando = true;
      _marcados.add(id);
    });
  }

  void _sairDaSelecao() {
    setState(() {
      _selecionando = false;
      _marcados.clear();
    });
  }

  /// Seleciona os que já não servem pra nada — é o caso de uso real de limpar.
  void _marcarInutilizaveis() {
    setState(() {
      _selecionando = true;
      _marcados
        ..clear()
        ..addAll(_codes.where((c) => !c.usable).map((c) => c.id));
      if (_marcados.isEmpty) _selecionando = false;
    });
  }

  Future<void> _apagarMarcados() async {
    final quantos = _marcados.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          quantos == 1 ? 'Apagar este código?' : 'Apagar $quantos códigos?',
        ),
        content: const Text(
          'Eles somem desta tela. Quem já entrou continua na rota, e o '
          'relatório mantém por onde cada aluno chegou.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            key: const Key('confirm_archive'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !mounted) return;

    setState(() => _ocupado = true);
    try {
      await _service.archiveInviteCodes(_marcados.toList());
      _sairDaSelecao();
      await _load();
      if (mounted) {
        showSuccessSnackBar(
          context,
          contagem(quantos, 'código apagado', 'códigos apagados'),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _revogar(InviteCode code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar este código?'),
        content: Text(
          'Quem já entrou continua na rota. Quem ainda tiver o código '
          '${code.code} não consegue mais usá-lo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar código'),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !mounted) return;

    setState(() => _ocupado = true);
    try {
      await _service.revokeInviteCode(code.routeId!, code.id);
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Código cancelado');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  String _situacao(InviteCode code) {
    if (code.revoked) return 'Cancelado';
    if (code.expired) return 'Expirado';
    final ate = code.expiresAt;
    if (ate == null) return 'Sem prazo';
    return 'Vale até ${ate.day.toString().padLeft(2, '0')}/'
        '${ate.month.toString().padLeft(2, '0')}/${ate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final porRota = <String, List<InviteCode>>{};
    for (final c in _codes) {
      porRota.putIfAbsent(c.routeName ?? 'Rota', () => []).add(c);
    }

    final inutilizaveis = _codes.where((c) => !c.usable).length;

    return Scaffold(
      appBar: _selecionando
          // Barra de seleção no lugar do título: enquanto o admin escolhe, o
          // que importa é quantos marcou e o que fazer com eles.
          ? AppBar(
              leading: IconButton(
                key: const Key('exit_selection'),
                icon: const Icon(Icons.close),
                onPressed: _sairDaSelecao,
              ),
              title: Text(
                '${_marcados.length} selecionado'
                '${_marcados.length == 1 ? '' : 's'}',
              ),
              actions: [
                IconButton(
                  key: const Key('archive_selected'),
                  tooltip: 'Apagar selecionados',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _ocupado ? null : _apagarMarcados,
                ),
              ],
            )
          : AppBar(
              title: const Text('Códigos de acesso'),
              actions: [
                if (inutilizaveis > 0)
                  IconButton(
                    key: const Key('select_unusable'),
                    tooltip: 'Selecionar expirados e cancelados',
                    icon: const Icon(Icons.checklist),
                    onPressed: _marcarInutilizaveis,
                  ),
              ],
            ),
      floatingActionButton: _selecionando
          ? null
          : FloatingActionButton.extended(
              key: const Key('generate_code_fab'),
              onPressed: _ocupado || widget.routes.isEmpty ? null : _gerar,
              icon: const Icon(Icons.add),
              label: const Text('Gerar código'),
            ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _codes.isEmpty
          ? const _Vazio()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              children: [
                for (final entrada in porRota.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      entrada.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (final code in entrada.value)
                          ListTile(
                            key: Key('code_${code.id}'),
                            selected: _marcados.contains(code.id),
                            selectedTileColor: AppColors.positiveBg,
                            leading: _selecionando
                                ? Checkbox(
                                    key: Key('check_${code.id}'),
                                    value: _marcados.contains(code.id),
                                    onChanged: (_) => _alternarSelecao(code.id),
                                  )
                                : Icon(
                                    code.usable
                                        ? Icons.vpn_key_outlined
                                        : Icons.key_off_outlined,
                                    color: code.usable
                                        ? AppColors.deepTeal
                                        : AppColors.textSecondary,
                                  ),
                            title: Text(
                              code.code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 20,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${code.institutionName ?? 'Qualquer instituição'} · '
                              '${_situacao(code)} · ${code.uses} '
                              '${code.uses == 1 ? 'aluno entrou' : 'alunos entraram'}',
                            ),
                            // Segurar entra no modo de seleção: é o gesto que
                            // o usuário já conhece de qualquer lista de app.
                            onLongPress: _selecionando
                                ? null
                                : () => _entrarNaSelecao(code.id),
                            onTap: _selecionando
                                ? () => _alternarSelecao(code.id)
                                : null,
                            trailing: _selecionando
                                ? null
                                : code.usable
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        key: Key('copy_${code.id}'),
                                        tooltip: 'Copiar código',
                                        icon: const Icon(Icons.copy_outlined),
                                        onPressed: _ocupado
                                            ? null
                                            : () async {
                                                await Clipboard.setData(
                                                  ClipboardData(
                                                    text: code.code,
                                                  ),
                                                );
                                                if (context.mounted) {
                                                  showSuccessSnackBar(
                                                    context,
                                                    'Código copiado',
                                                  );
                                                }
                                              },
                                      ),
                                      IconButton(
                                        key: Key('revoke_${code.id}'),
                                        tooltip: 'Cancelar código',
                                        icon: const Icon(Icons.block_outlined),
                                        onPressed: _ocupado
                                            ? null
                                            : () => _revogar(code),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.vpn_key_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum código criado',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Gere um código e mande pra turma — quem tiver ele entra na rota.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
