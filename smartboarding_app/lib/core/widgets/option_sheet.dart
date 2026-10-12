import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Escolha de uma opção numa folha, com rótulo e um detalhe opcional embaixo.
///
/// Genérica de propósito: três telas já pediam o mesmo gesto (validade do
/// código, instituição do código, instituição da parada) e cada uma montava a
/// própria folha. Nulo quando a pessoa fecha sem escolher.
Future<T?> escolherOpcao<T>(
  BuildContext context,
  String titulo,
  List<(String rotulo, String detalhe, T valor)> opcoes, {

  /// Key própria por opção. Sem isso a key sai do rótulo, que muda junto com o
  /// texto — e teste preso a texto quebra na primeira correção de português.
  Key Function(T valor)? keyOf,
}) {
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
                key: keyOf?.call(valor) ?? Key('opcao_$rotulo'),
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
