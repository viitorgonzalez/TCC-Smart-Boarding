import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_card.dart';
import '../models/trip_status_model.dart';

/// Cabeçalho do trajeto: onde está e quanto falta, sem precisar contar as
/// paradas na lista abaixo.
class TripProgressCard extends StatelessWidget {
  final TripStatus trip;

  const TripProgressCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final total = trip.stops.length;
    final feitas = trip.stops.where((s) => s.reached).length;
    final theme = Theme.of(context);

    final (rotulo, cor) = switch (trip) {
      _ when trip.finished => ('Concluído', AppColors.positiveFg),
      // A perna muda o que o admin espera ver na lista abaixo; dizer qual e
      // evita a duvida de "por que as paradas inverteram?".
      _ when trip.inProgress && trip.onReturn => (
        'Volta em andamento',
        AppColors.deepTeal,
      ),
      _ when trip.inProgress => ('Ida em andamento', AppColors.deepTeal),
      _ => ('Não iniciado', AppColors.textSecondary),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trip.routeName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            trip.startedAt == null
                ? rotulo
                : '$rotulo · saiu às ${formatTime(trip.startedAt)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: cor),
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: feitas / total,
                minHeight: 8,
                backgroundColor: AppColors.ashGrey,
                valueColor: AlwaysStoppedAnimation(
                  trip.finished ? AppColors.positiveFg : AppColors.deepTeal,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$feitas de $total ${total == 1 ? 'parada' : 'paradas'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
