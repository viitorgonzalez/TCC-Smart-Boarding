import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/profile_update_model.dart';

/// A folha que mostra o que o aluno pediu e deixa o admin decidir.
///
/// Devolve `'aprovar'`, `'rejeitar'` ou nulo (fechou sem decidir) — a decisão
/// de o que fazer com isso fica na tela, que é quem tem o serviço.
Future<String?> mostrarDetalheDaSolicitacao(
  BuildContext context,
  ProfileUpdate p,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.studentName ?? 'Solicitação',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 12),
            for (final d in p.diffs) DiffRow(diff: d),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: AppColors.danger,
                    ),
                    label: const Text('Recusar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    onPressed: () => Navigator.pop(ctx, 'rejeitar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Aprovar'),
                    onPressed: () => Navigator.pop(ctx, 'aprovar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Um campo pedido: o valor atual riscado, o novo em destaque. Mostrar os dois
/// é o que permite o admin decidir sem abrir o cadastro em outra tela.
class DiffRow extends StatelessWidget {
  final ProfileFieldDiff diff;
  const DiffRow({super.key, required this.diff});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diff.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  diff.before,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  diff.after,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
