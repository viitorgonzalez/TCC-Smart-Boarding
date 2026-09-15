import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// Itens relacionados numa superfície só, separados por divisor.
///
/// Substitui o padrão de um [Card] por item. Com um cartão por linha, cada
/// rota da lista pesava o mesmo que um bloco de conteúdo solto, e a tela virava
/// uma pilha de caixas de mesmo tamanho — o olho não achava onde começar.
/// Agrupando, a lista lê como uma coisa só e o cartão volta a significar
/// "conteúdo que merece destaque".
class AppListGroup extends StatelessWidget {
  final List<Widget> children;

  /// Recuo do divisor, alinhado ao texto quando os itens têm ícone à esquerda.
  /// Divisor de ponta a ponta corta o ícone ao meio e suja a coluna.
  final double dividerIndent;

  const AppListGroup({
    super.key,
    required this.children,
    this.dividerIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return AppCard(
      surface: AppSurface.grouped,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, indent: dividerIndent),
          ],
        ],
      ),
    );
  }
}

/// Linha de uma [AppListGroup].
///
/// [trailing] é pra informação e navegação. Ação destrutiva não entra aqui:
/// em vermelho cheio, ao lado do conteúdo, ela vira o elemento mais saturado
/// da tela sendo o mais raro — vai pro [menu], atrás de um toque.
class AppListItem extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;

  /// Subtítulo composto, quando texto puro não basta — um marcador de estado,
  /// por exemplo. Tem precedência sobre [subtitle].
  final Widget? subtitleChild;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Ações secundárias e destrutivas, num menu de três pontos.
  final List<PopupMenuEntry<VoidCallback>>? menu;

  const AppListItem({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.subtitleChild,
    this.trailing,
    this.onTap,
    this.menu,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: menu == null ? AppSpacing.lg : AppSpacing.sm,
      ),
      leading: leading,
      title: Text(title, style: texto.titleSmall),
      subtitle: switch ((subtitleChild, subtitle)) {
        (final Widget filho?, _) => Padding(
          padding: const EdgeInsets.only(top: 2),
          child: filho,
        ),
        (_, final String s?) => Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(s, style: texto.bodySmall),
        ),
        _ => null,
      },
      trailing: menu == null
          ? trailing
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?trailing,
                PopupMenuButton<VoidCallback>(
                  key: Key('menu_$title'),
                  tooltip: 'Mais ações',
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (acao) => acao(),
                  itemBuilder: (_) => menu!,
                ),
              ],
            ),
      onTap: onTap,
    );
  }
}

/// Item de menu destrutivo, no vermelho da paleta.
PopupMenuItem<VoidCallback> destructiveMenuItem({
  required String label,
  required IconData icon,
  required VoidCallback onSelected,
}) {
  return PopupMenuItem<VoidCallback>(
    value: onSelected,
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.danger),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: const TextStyle(color: AppColors.danger)),
      ],
    ),
  );
}

/// Ponto colorido antes do texto de estado.
///
/// Substitui a pílula quando ela competia por largura com o título: o ponto diz
/// a mesma coisa com um oitavo do espaço, e o nome da rota volta a caber numa
/// linha.
class StatusDot extends StatelessWidget {
  final Color color;
  const StatusDot(this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    margin: const EdgeInsets.only(right: AppSpacing.sm),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
