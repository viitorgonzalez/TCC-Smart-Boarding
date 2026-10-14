import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/date_format.dart';

class CloseCountdown extends StatefulWidget {
  final String? closeTime;
  const CloseCountdown({super.key, required this.closeTime});

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
    final label = formatCloseTime(widget.closeTime);
    final remaining = timeUntilListClose(widget.closeTime);
    if (parseTimeOfDay(widget.closeTime) == null) {
      return const SizedBox.shrink();
    }
    final closed = remaining == null;
    final color = closed ? cs.error : cs.primary;
    final text = closed
        ? 'Inscrições encerradas · fechava às $label'
        : 'Fecha em ${humanizeDuration(remaining)} · às $label';

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
