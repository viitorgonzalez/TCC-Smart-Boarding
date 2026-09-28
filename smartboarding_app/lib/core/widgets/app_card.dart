import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Superfície branca sobre o fundo. O [surface] escolhe como ela se separa —
/// ver [AppSurface].
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final AppSurface surface;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.onLongPress,
    this.surface = AppSurface.card,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    // Material em vez de Container pintado: com a cor num DecoratedBox solto,
    // o ink de qualquer ListTile com onTap la dentro era pintado ATRAS do fundo
    // -- toque sem retorno visual, e o Flutter reclamando em debug.
    final material = Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: surface == AppSurface.card
            ? const BorderSide(color: AppColors.stroke)
            : BorderSide.none,
      ),
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, onLongPress: onLongPress, child: content),
    );

    if (surface != AppSurface.floating) return material;
    // A sombra vai num DecoratedBox por fora: no Material ela sai junto com o
    // recorte e vaza por cima do proprio conteudo.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.floating,
      ),
      child: material,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

class StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final Color? valueColor;

  const StatBlock({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(letterSpacing: 0.4),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.charcoal,
              ),
            ),
            if (suffix != null)
              Text(
                ' / $suffix',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
