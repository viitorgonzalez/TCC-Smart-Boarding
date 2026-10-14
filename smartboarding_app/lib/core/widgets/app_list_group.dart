import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class AppListGroup extends StatelessWidget {
  final List<Widget> children;

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

class AppListItem extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;

  final Widget? subtitleChild;
  final Widget? trailing;
  final VoidCallback? onTap;

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
