import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';

/// Uma parada na lista do trajeto. É leitura: a ação mora no card de próxima
/// parada, um alvo só na tela. O horário registrado fica visível porque é o que
/// permite conferir o ritmo do trajeto depois.
class TripStepTile extends StatelessWidget {
  final String label;
  final bool done;
  final bool current;
  final String? reachedAt;

  const TripStepTile({
    super.key,
    required this.label,
    required this.done,
    required this.current,
    this.reachedAt,
  });

  @override
  Widget build(BuildContext context) {
    final cor = done
        ? AppColors.positiveFg
        : current
        ? AppColors.deepTeal
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
