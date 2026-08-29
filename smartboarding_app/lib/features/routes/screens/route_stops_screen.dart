import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/errors/app_exception.dart';
import '../models/stop_model.dart';
import '../services/route_service.dart';
import '../widgets/route_map.dart';

/// "Ver trajeto completo": as paradas da rota na ordem de passagem.
class RouteStopsScreen extends StatefulWidget {
  final String routeId;
  final String routeName;

  const RouteStopsScreen({
    super.key,
    required this.routeId,
    required this.routeName,
  });

  @override
  State<RouteStopsScreen> createState() => _RouteStopsScreenState();
}

class _RouteStopsScreenState extends State<RouteStopsScreen> {
  late Future<List<StopModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = RouteService().getStops(widget.routeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trajeto da rota')),
      body: SafeArea(
        child: FutureBuilder<List<StopModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(AppException.fromError(snapshot.error!)),
              );
            }
            final stops = snapshot.data ?? const <StopModel>[];
            if (stops.isEmpty) {
              return const Center(
                child: Text('Nenhuma parada cadastrada nesta rota'),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // O aluno também vê o traçado no mapa, não só a sequência —
                // saber por onde o ônibus passa é a informação principal aqui.
                RouteMap(
                  stops: [
                    for (final s in stops)
                      if (s.hasCoordinates)
                        MapStop(
                          name: s.name,
                          latitude: s.latitude!,
                          longitude: s.longitude!,
                          sequence: s.sequence,
                        ),
                  ],
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < stops.length; i++)
                  _StopTile(
                    stop: stops[i],
                    isFirst: i == 0,
                    isLast: i == stops.length - 1,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Linha do tempo vertical: a ordem das paradas é a informação principal.
class _StopTile extends StatelessWidget {
  final StopModel stop;
  final bool isFirst;
  final bool isLast;

  const _StopTile({
    required this.stop,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 12,
                color: isFirst ? Colors.transparent : AppColors.stroke,
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.deepTeal,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 3),
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : AppColors.stroke,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PARADA ${stop.sequence}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stop.name,
                    style: Theme.of(context).textTheme.titleMedium,
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
