import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/invite_code_model.dart';
import '../services/route_service.dart';

/// Códigos que o admin distribui pra turma entrar na rota.
///
/// O gesto inteiro é: gerar, copiar, mandar no grupo. Por isso o código fica
/// grande e monoespaçado, com o copiar do lado — ele nasce pra ser colado em
/// outro aplicativo, não pra ser lido na tela.
class RouteInviteCodesCard extends StatefulWidget {
  final String routeId;

  const RouteInviteCodesCard({super.key, required this.routeId});

  @override
  State<RouteInviteCodesCard> createState() => _RouteInviteCodesCardState();
}

class _RouteInviteCodesCardState extends State<RouteInviteCodesCard> {
  final _service = RouteService();
  List<InviteCode> _codes = const [];
  bool _busy = false;
  bool _carregou = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codes = await _service.getInviteCodes(widget.routeId);
      if (mounted) setState(() => _codes = codes);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _carregou = true);
    }
  }

  Future<void> _gerar() async {
    final validade = await showModalBottomSheet<CodeValidity>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Por quanto tempo o código vale?',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            for (final v in CodeValidity.values)
              ListTile(
                key: Key('validity_${v.name}'),
                leading: const Icon(Icons.schedule),
                title: Text(v.label),
                onTap: () => Navigator.pop(ctx, v),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (validade == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final novo = await _service.generateInviteCode(
        widget.routeId,
        expiresAt: validade.expiresFrom(DateTime.now()),
      );
      if (!mounted) return;
      setState(() => _codes = [novo, ..._codes]);
      await Clipboard.setData(ClipboardData(text: novo.code));
      if (mounted) {
        showSuccessSnackBar(context, 'Código ${novo.code} criado e copiado');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copiar(InviteCode code) async {
    await Clipboard.setData(ClipboardData(text: code.code));
    if (mounted) showSuccessSnackBar(context, 'Código copiado');
  }

  Future<void> _revogar(InviteCode code) async {
    setState(() => _busy = true);
    try {
      await _service.revokeInviteCode(widget.routeId, code.id);
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Código cancelado');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Quem já entrou continua na rota — revogar só impede entradas novas. Dizer
  /// isso antes evita o admin achar que está removendo a turma.
  Future<void> _confirmarRevogacao(InviteCode code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar este código?'),
        content: Text(
          'Ninguém mais consegue entrar com ${code.code}. '
          'Quem já entrou continua na rota.',
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
    if (ok ?? false) await _revogar(code);
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
    final ativos = _codes.where((c) => c.usable).toList();
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_carregou && _codes.isEmpty)
            const ListTile(
              title: Text('Nenhum código criado'),
              subtitle: Text(
                'Gere um código e mande pra turma — quem tiver ele entra '
                'nesta rota.',
              ),
            ),
          for (final code in _codes)
            ListTile(
              leading: Icon(
                code.usable ? Icons.vpn_key : Icons.key_off,
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
                '${_situacao(code)} · ${code.uses} '
                '${code.uses == 1 ? 'aluno entrou' : 'alunos entraram'}',
              ),
              trailing: code.usable
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('copy_code_${code.id}'),
                          tooltip: 'Copiar código',
                          icon: const Icon(Icons.copy),
                          onPressed: _busy ? null : () => _copiar(code),
                        ),
                        IconButton(
                          key: Key('revoke_code_${code.id}'),
                          tooltip: 'Cancelar código',
                          icon: const Icon(Icons.block),
                          onPressed: _busy
                              ? null
                              : () => _confirmarRevogacao(code),
                        ),
                      ],
                    )
                  : null,
            ),
          const Divider(height: 1),
          ListTile(
            key: const Key('generate_code'),
            leading: const Icon(Icons.add, color: AppColors.deepTeal),
            title: Text(ativos.isEmpty ? 'Gerar código' : 'Gerar outro código'),
            enabled: !_busy,
            onTap: _gerar,
          ),
        ],
      ),
    );
  }
}
