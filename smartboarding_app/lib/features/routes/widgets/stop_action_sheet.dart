import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/stop_model.dart';

enum StopAction { move, insertAfter, rename, linkInstitution, remove }

/// O que fazer com a parada tocada.
///
/// Rolável porque a folha cresce com o número de opções: sem isso, aparelho
/// baixo corta a última ação — e a última é "Remover".
Future<StopAction?> escolherAcaoDaParada(
  BuildContext context,
  StopModel stop, {
  required bool podeVincularInstituicao,
  required String? instituicaoAtual,
}) {
  return showModalBottomSheet<StopAction>(
    context: context,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                stop.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('Parada ${stop.sequence}'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.open_with, color: AppColors.deepTeal),
              title: const Text('Mover para outro local'),
              onTap: () => Navigator.pop(context, StopAction.move),
            ),
            ListTile(
              leading: const Icon(
                Icons.add_location_alt_outlined,
                color: AppColors.deepTeal,
              ),
              title: const Text('Inserir parada depois desta'),
              onTap: () => Navigator.pop(context, StopAction.insertAfter),
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.deepTeal,
              ),
              title: const Text('Renomear'),
              onTap: () => Navigator.pop(context, StopAction.rename),
            ),
            // Some quando a rota não tem instituição: oferecer uma escolha sem
            // opção é um beco.
            if (podeVincularInstituicao)
              ListTile(
                key: const Key('stop_link_institution'),
                leading: const Icon(
                  Icons.school_outlined,
                  color: AppColors.deepTeal,
                ),
                title: const Text('Instituição atendida'),
                subtitle: Text(instituicaoAtual ?? 'Nenhuma — parada comum'),
                onTap: () => Navigator.pop(context, StopAction.linkInstitution),
              ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text('Remover'),
              onTap: () => Navigator.pop(context, StopAction.remove),
            ),
          ],
        ),
      ),
    ),
  );
}
