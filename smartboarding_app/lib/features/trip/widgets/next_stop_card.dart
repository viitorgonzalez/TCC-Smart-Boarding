import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../models/trip_status_model.dart';

class NextStopCard extends StatelessWidget {
  final TripStop stop;
  final bool busy;
  final VoidCallback onMark;

  const NextStopCard({
    super.key,
    required this.stop,
    required this.onMark,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PRÓXIMA PARADA',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(stop.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              key: const Key('trip_mark_button'),
              onPressed: busy ? null : onMark,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.place),
              label: Text(busy ? 'Registrando...' : 'Cheguei aqui'),
            ),
          ),
        ],
      ),
    );
  }
}
