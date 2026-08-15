import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/date_format.dart';

/// Contagem regressiva até o fechamento (16:00).
class CloseCountdown extends StatefulWidget {
  const CloseCountdown({super.key});

  @override
  State<CloseCountdown> createState() => _CloseCountdownState();
}

class _CloseCountdownState extends State<CloseCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = timeUntilListClose();
    final closingSoon = remaining == null;
    final color = closingSoon ? cs.error : cs.primary;
    final text = closingSoon
        ? 'Fechamento às 16:00 — encerrando'
        : 'Fecha em ${humanizeDuration(remaining)} · às 16:00';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
