import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../models/invite_code_model.dart';
import 'invite_code_tile.dart';

/// Os códigos agrupados por rota.
///
/// O agrupamento mora aqui e não na tela porque é decisão de apresentação: o
/// backend devolve uma lista plana, e quem olha a tela pensa por rota.
class InviteCodesList extends StatelessWidget {
  final List<InviteCode> codes;
  final bool selecionando;
  final Set<String> marcados;
  final bool ocupado;

  final void Function(String id) onAlternar;
  final void Function(String id) onEntrarNaSelecao;
  final void Function(InviteCode code) onRevogar;

  const InviteCodesList({
    super.key,
    required this.codes,
    required this.selecionando,
    required this.marcados,
    required this.ocupado,
    required this.onAlternar,
    required this.onEntrarNaSelecao,
    required this.onRevogar,
  });

  @override
  Widget build(BuildContext context) {
    final porRota = <String, List<InviteCode>>{};
    for (final c in codes) {
      porRota.putIfAbsent(c.routeName ?? 'Rota', () => []).add(c);
    }

    return ListView(
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
                  InviteCodeTile(
                    code: code,
                    selecionando: selecionando,
                    marcado: marcados.contains(code.id),
                    ocupado: ocupado,
                    onAlternar: () => onAlternar(code.id),
                    onEntrarNaSelecao: () => onEntrarNaSelecao(code.id),
                    onRevogar: () => onRevogar(code),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}
