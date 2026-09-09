import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_builder.dart';
import '../models/trip_status_model.dart';
import '../providers/trip_provider.dart';
import '../widgets/trip_step_tile.dart';

/// Conduzir o trajeto do dia. Cada ação pede confirmação porque dispara aviso
/// pra todos da rota — toque acidental sai caro.
class TripScreen extends StatelessWidget {
  const TripScreen({super.key});

  Future<bool> _confirm(BuildContext context, String question) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(question),
        content: const Text('Todos os alunos da rota são avisados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conduzir trajeto')),
      body: Consumer<TripProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (trip) => _TripBody(
            trip: trip,
            onStart: () async {
              if (await _confirm(context, 'Iniciar o trajeto de hoje?')) {
                await provider.start();
              }
            },
            onMark: (stop) async {
              if (await _confirm(
                context,
                'Confirmar chegada na parada "${stop.name}"?',
              )) {
                await provider.checkpoint(stop.stopId);
              }
            },
            onFinish: () async {
              if (await _confirm(context, 'Finalizar o trajeto de hoje?')) {
                await provider.finish();
              }
            },
          ),
        ),
      ),
    );
  }
}

class _TripBody extends StatelessWidget {
  final TripStatus trip;
  final VoidCallback onStart;
  final void Function(TripStop) onMark;
  final VoidCallback onFinish;

  const _TripBody({
    required this.trip,
    required this.onStart,
    required this.onMark,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final current = trip.current;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRAJETO SELECIONADO',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trip.routeName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TripStepTile(
          position: 1,
          label: 'Trajeto iniciado',
          done: !trip.notStarted,
          current: trip.notStarted,
          onMark: trip.notStarted ? onStart : null,
        ),
        for (var i = 0; i < trip.stops.length; i++)
          TripStepTile(
            position: i + 2,
            label: 'Parada: ${trip.stops[i].name}',
            done: trip.stops[i].reached,
            current: current?.stopId == trip.stops[i].stopId,
            onMark: current?.stopId == trip.stops[i].stopId
                ? () => onMark(trip.stops[i])
                : null,
          ),
        const SizedBox(height: 12),
        if (trip.finished)
          const AppCard(child: Text('Trajeto concluído.'))
        else
          FilledButton(
            onPressed: trip.inProgress ? onFinish : null,
            child: const Text('Finalizar trajeto'),
          ),
      ],
    );
  }
}
