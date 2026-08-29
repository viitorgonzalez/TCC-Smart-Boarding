import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Botões de zoom e reenquadramento do mapa.
class MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const MapButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.control),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: AppColors.charcoal),
          ),
        ),
      ),
    );
  }
}

/// Origem e destino ganham cor própria: num trajeto é o que se lê primeiro.
