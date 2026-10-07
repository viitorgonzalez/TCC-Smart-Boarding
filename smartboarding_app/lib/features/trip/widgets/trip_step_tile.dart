import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';

class TripStepTile extends StatelessWidget {
  final String label;
  final bool done;
  final bool current;
  final String? reachedAt;

  final bool highlighted;

  const TripStepTile({
    super.key,
    required this.label,
    required this.done,
    required this.current,
    this.reachedAt,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = done
        ? AppColors.positiveFg
        : current
        ? AppColors.deepTeal
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: highlighted
          ? BoxDecoration(
              color: AppColors.deepTeal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle
                : current
                ? Icons.my_location
                : Icons.radio_button_unchecked,
            size: 20,
            color: cor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: done ? AppColors.charcoal : cor,
                fontWeight: current || done
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
          ),
          if (done && reachedAt != null)
            Text(
              formatTime(reachedAt),
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else if (current)
            const Text(
              'agora',
              style: TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
