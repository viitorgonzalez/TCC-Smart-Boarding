import 'package:flutter/material.dart';

import '../../routes/models/map_stop.dart';
import '../../routes/services/road_route_service.dart';
import '../../routes/widgets/route_map.dart';
import '../models/trip_status_model.dart';

/// O trajeto no mapa, com as paradas já alcançadas marcadas.
///
/// Some quando nenhuma parada tem coordenada — um mapa vazio sobre Formiga
/// diria menos do que a lista de paradas que já está abaixo dele.
class TripMap extends StatelessWidget {
  final TripStatus trip;

  /// Injetável só para teste, igual ao RouteMap.
  final RoadRouteService? roadRoute;

  const TripMap({super.key, required this.trip, this.roadRoute});

  @override
  Widget build(BuildContext context) {
    final located = trip.stops.where((s) => s.hasCoordinates).toList();
    if (located.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: RouteMap(
        key: const Key('trip_map'),
        roadRoute: roadRoute,
        compact: true,
        stops: [
          for (final s in located)
            MapStop(
              id: s.stopId,
              name: s.name,
              latitude: s.latitude!,
              longitude: s.longitude!,
              sequence: s.sequence,
              reached: s.reached,
            ),
        ],
      ),
    );
  }
}
