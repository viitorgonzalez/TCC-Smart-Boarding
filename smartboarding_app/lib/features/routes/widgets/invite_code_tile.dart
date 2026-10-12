import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/invite_code_model.dart';

/// Uma linha da lista de códigos.
///
/// Fora da tela porque ela cresceu além do limite de 300 linhas que o CI cobra,
/// e porque a linha é o que muda quando o código ganha estado novo (expirado,
/// cancelado, travado por instituição) — a tela só a posiciona.
class InviteCodeTile extends StatelessWidget {
  final InviteCode code;

  /// Modo de seleção múltipla: troca o ícone por checkbox e some com as ações
  /// individuais, pra não misturar "selecionar" com "cancelar".
  final bool selecionando;
  final bool marcado;
  final bool ocupado;

  final VoidCallback onAlternar;
  final VoidCallback onEntrarNaSelecao;
  final VoidCallback onRevogar;

  const InviteCodeTile({
    super.key,
    required this.code,
    required this.selecionando,
    required this.marcado,
    required this.ocupado,
    required this.onAlternar,
    required this.onEntrarNaSelecao,
    required this.onRevogar,
  });

  static String situacao(InviteCode code) {
    if (code.revoked) return 'Cancelado';
    if (code.expired) return 'Expirado';
    final ate = code.expiresAt;
    if (ate == null) return 'Sem prazo';
    return 'Vale até ${ate.day.toString().padLeft(2, '0')}/'
        '${ate.month.toString().padLeft(2, '0')}/${ate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('code_${code.id}'),
      selected: marcado,
      selectedTileColor: AppColors.positiveBg,
      leading: selecionando
          ? Checkbox(
              key: Key('check_${code.id}'),
              value: marcado,
              onChanged: (_) => onAlternar(),
            )
          : Icon(
              code.usable ? Icons.vpn_key_outlined : Icons.key_off_outlined,
              color: code.usable ? AppColors.deepTeal : AppColors.textSecondary,
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
        '${situacao(code)} · ${code.uses} '
        '${code.uses == 1 ? 'aluno entrou' : 'alunos entraram'}',
      ),
      onLongPress: selecionando ? null : onEntrarNaSelecao,
      onTap: selecionando ? onAlternar : null,
      trailing: selecionando || !code.usable ? null : _acoes(context),
    );
  }

  Widget _acoes(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key('copy_${code.id}'),
          tooltip: 'Copiar código',
          icon: const Icon(Icons.copy_outlined),
          onPressed: ocupado
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: code.code));
                  if (context.mounted) {
                    showSuccessSnackBar(context, 'Código copiado');
                  }
                },
        ),
        IconButton(
          key: Key('revoke_${code.id}'),
          tooltip: 'Cancelar código',
          icon: const Icon(Icons.block_outlined),
          onPressed: ocupado ? null : onRevogar,
        ),
      ],
    );
  }
}
