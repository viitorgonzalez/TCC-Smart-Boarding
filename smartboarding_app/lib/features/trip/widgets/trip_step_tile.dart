import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Um passo do trajeto. O visual comunica o estado sem depender de texto:
/// concluído em verde, atual destacado, futuro esmaecido.
class TripStepTile extends StatelessWidget {
  final int position;
  final String label;
  final bool done;
  final bool current;
  final VoidCallback? onMark;

  const TripStepTile({
    super.key,
    required this.position,
    required this.label,
    required this.done,
    required this.current,
    this.onMark,
  });

  @override
  Widget build(BuildContext context) {
    final background = done
        ? AppColors.positiveBg
        : current
        ? AppColors.deepTeal
        : AppColors.surface;
    final foreground = done
        ? AppColors.positiveFg
        : current
        ? Colors.white
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: done ? AppColors.positiveBg : AppColors.ashGrey,
            child: done
                ? const Icon(Icons.check, size: 18, color: AppColors.positiveFg)
                : Text(
                    '$position',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkSlate,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                  if (done)
                    Text('Concluído', style: TextStyle(color: foreground))
                  else if (current && onMark != null)
                    TextButton(
                      onPressed: onMark,
                      child: const Text(
                        'Marcar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
