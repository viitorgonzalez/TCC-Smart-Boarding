import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusPillTone { positive, neutral, danger }

class StatusPill extends StatelessWidget {
  final String label;
  final StatusPillTone tone;

  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusPillTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    // Cores literais em vez do ColorScheme: o desenho usa um verde de
    // confirmação próprio (#E8F5E9/#2E7D32) que não é derivável do seed.
    final (background, foreground) = switch (tone) {
      StatusPillTone.positive => (AppColors.positiveBg, AppColors.positiveFg),
      StatusPillTone.neutral => (AppColors.background, AppColors.textSecondary),
      StatusPillTone.danger => (AppColors.dangerBg, AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
