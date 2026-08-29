import 'package:flutter/material.dart';

/// Sem o motivo à vista o aluno reenvia às cegas o mesmo cadastro negado.
class RejectionNotice extends StatelessWidget {
  final String? reason;
  const RejectionNotice({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cadastro não aprovado',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (reason != null && reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason!,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Corrija os dados abaixo e envie de novo.',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
