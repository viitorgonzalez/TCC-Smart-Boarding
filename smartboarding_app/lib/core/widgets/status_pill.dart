import 'package:flutter/material.dart';

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
    final cs = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      StatusPillTone.positive => (cs.primaryContainer, cs.onPrimaryContainer),
      StatusPillTone.neutral => (
        cs.surfaceContainerHighest,
        cs.onSurfaceVariant,
      ),
      StatusPillTone.danger => (cs.errorContainer, cs.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
