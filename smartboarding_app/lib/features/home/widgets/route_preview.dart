import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../lists/models/daily_list_model.dart';
import '../../routes/screens/route_stops_screen.dart';
import '../../routes/models/map_stop.dart';
import '../../routes/widgets/route_map.dart';

/// Blocos de apoio do cartão do aluno: veículo definido no fechamento (RN16)
/// e prévia do trajeto.
class ProposedVehicle extends StatelessWidget {
  final List<VehicleSummary> vehicles;
  final int shortfall;

  const ProposedVehicle({
    super.key,
    required this.vehicles,
    required this.shortfall,
  });

  @override
  Widget build(BuildContext context) {
    final insufficient = shortfall > 0;
    final color = insufficient ? AppColors.danger : AppColors.positiveFg;
    final background = insufficient ? AppColors.dangerBg : AppColors.positiveBg;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                insufficient ? Icons.warning_amber : Icons.directions_bus,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                'TRANSPORTE DEFINIDO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            vehicles.isEmpty
                ? 'Nenhum veículo disponível na rota'
                : vehicles
                      .map((v) => '${v.label} (${v.capacity})')
                      .join('  +  '),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          if (insufficient) ...[
            const SizedBox(height: 4),
            Text(
              '$shortfall pessoa(s) sem lugar na frota',
              style: TextStyle(fontSize: 13, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class RoutePreview extends StatelessWidget {
  final DailyList list;
  const RoutePreview({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final located = list.stops.where((s) => s.hasCoordinates).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RouteMap(
          compact: true,
          stops: [
            for (final s in located)
              MapStop(
                name: s.name,
                latitude: s.latitude!,
                longitude: s.longitude!,
                sequence: s.sequence,
              ),
          ],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouteStopsScreen(
                routeId: list.routeId,
                routeName: list.routeName,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.route_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                located.length < 2
                    ? '${located.length} parada'
                    : '${located.length} paradas · ${located.first.name} → ${located.last.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              'ver mapa',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.deepTeal,
            ),
          ],
        ),
      ],
    );
  }
}
