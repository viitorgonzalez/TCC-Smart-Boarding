import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Substitui a AppBar nas telas raiz — no desenho não existe AppBar ali.
class AppHeader extends StatelessWidget {
  final String overline;
  final String title;
  final Widget? leading;
  final Widget? trailing;

  const AppHeader({
    super.key,
    required this.overline,
    required this.title,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.charcoal,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      overline,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      // Nome longo virava tres linhas e empurrava as acoes
                      // pra fora do alinhamento.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.deepTeal,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Uma ação por item, atrás de um ⋮.
///
/// Existe porque três botões sólidos lado a lado no cabeçalho escuro
/// competiam entre si com o mesmo peso visual. Abrir o perfil e sair são ações
/// ocasionais — não precisam de alvo permanente. Só o que se usa todo dia fica
/// à vista.
class HeaderMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onSelected;

  const HeaderMenuItem({
    required this.label,
    required this.icon,
    required this.onSelected,
  });
}

class HeaderOverflowMenu extends StatelessWidget {
  final List<HeaderMenuItem> items;

  const HeaderOverflowMenu({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      key: const Key('header_overflow_menu'),
      tooltip: 'Mais opções',
      // Contorno em vez de preenchido: o cabeçalho já tem um botão sólido (a
      // ação do dia), e dois blocos cheios voltariam a disputar a atenção.
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: AppColors.surface,
      onSelected: (i) => items[i].onSelected(),
      itemBuilder: (_) => [
        for (final (i, item) in items.indexed)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: AppColors.charcoal),
                const SizedBox(width: 12),
                Text(item.label),
              ],
            ),
          ),
      ],
    );
  }
}
