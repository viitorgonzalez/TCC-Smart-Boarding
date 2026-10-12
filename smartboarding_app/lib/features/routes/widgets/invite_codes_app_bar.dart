import 'package:flutter/material.dart';

/// A barra troca de identidade no modo de seleção: título vira a contagem e as
/// ações viram "apagar o que está marcado". Separada da tela porque são duas
/// barras diferentes, não uma com variações — misturá-las num ternário dentro
/// do `build` escondia qual ação existe em qual modo.
class InviteCodesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool selecionando;
  final int marcados;
  final int inutilizaveis;
  final bool ocupado;

  final VoidCallback onSair;
  final VoidCallback onApagarMarcados;
  final VoidCallback onMarcarInutilizaveis;

  const InviteCodesAppBar({
    super.key,
    required this.selecionando,
    required this.marcados,
    required this.inutilizaveis,
    required this.ocupado,
    required this.onSair,
    required this.onApagarMarcados,
    required this.onMarcarInutilizaveis,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (!selecionando) {
      return AppBar(
        title: const Text('Códigos de acesso'),
        actions: [
          if (inutilizaveis > 0)
            IconButton(
              key: const Key('select_unusable'),
              tooltip: 'Selecionar expirados e cancelados',
              icon: const Icon(Icons.checklist),
              onPressed: onMarcarInutilizaveis,
            ),
        ],
      );
    }
    return AppBar(
      leading: IconButton(
        key: const Key('exit_selection'),
        icon: const Icon(Icons.close),
        onPressed: onSair,
      ),
      title: Text('$marcados selecionado${marcados == 1 ? '' : 's'}'),
      actions: [
        IconButton(
          key: const Key('archive_selected'),
          tooltip: 'Apagar selecionados',
          icon: const Icon(Icons.delete_outline),
          onPressed: ocupado ? null : onApagarMarcados,
        ),
      ],
    );
  }
}
