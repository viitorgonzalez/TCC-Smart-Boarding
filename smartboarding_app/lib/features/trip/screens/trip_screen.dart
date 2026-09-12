import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_builder.dart';
import '../models/trip_status_model.dart';
import '../providers/trip_provider.dart';
import '../widgets/finish_trip_dialog.dart';
import '../widgets/next_stop_card.dart';
import '../widgets/trip_progress_card.dart';
import '../widgets/trip_step_tile.dart';

/// Conduzir o trajeto do dia.
///
/// Iniciar e finalizar pedem confirmação porque disparam aviso pra rota inteira
/// e não têm volta. Marcar chegada não pede: era uma confirmação por parada, o
/// que transformava o uso normal numa sequência de diálogos. O risco de toque
/// acidental some pelo desenho — a ação é um botão grande e único na tela, não
/// um link pequeno no meio de uma lista.
class TripScreen extends StatelessWidget {
  const TripScreen({super.key});

  Future<bool> _confirmStart(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Iniciar o trajeto de hoje?'),
        content: const Text('Todos os alunos da rota são avisados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Iniciar'),
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
            busy: provider.busy,
            onStart: () async {
              if (await _confirmStart(context)) await provider.start();
            },
            onMark: (stop) => provider.checkpoint(stop.stopId),
            onFinish: () async {
              if (!context.mounted) return;
              if (await confirmFinishTrip(context, trip)) {
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
  final bool busy;
  final VoidCallback onStart;
  final void Function(TripStop) onMark;
  final VoidCallback onFinish;

  const _TripBody({
    required this.trip,
    required this.busy,
    required this.onStart,
    required this.onMark,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final atual = trip.current;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TripProgressCard(trip: trip),
        const SizedBox(height: 20),

        if (trip.notStarted) ...[
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              key: const Key('trip_start_button'),
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar trajeto'),
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (atual != null) ...[
          NextStopCard(stop: atual, busy: busy, onMark: () => onMark(atual)),
          const SizedBox(height: 20),
        ],

        // Em andamento sem parada atual = todas marcadas. Dizer isso evita a
        // duvida de "sumiu o botao, travou?".
        if (trip.inProgress && atual == null && trip.stops.isNotEmpty) ...[
          const AppCard(
            child: Row(
              children: [
                Icon(Icons.done_all, color: AppColors.positiveFg),
                SizedBox(width: 12),
                Expanded(child: Text('Todas as paradas foram marcadas.')),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (trip.stops.isNotEmpty) ...[
          Text('Paradas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          AppCard(
            child: Column(
              children: [
                for (final stop in trip.stops)
                  TripStepTile(
                    label: stop.name,
                    done: stop.reached,
                    current: atual?.stopId == stop.stopId,
                    reachedAt: stop.reachedAt,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (trip.finished)
          const AppCard(
            child: Row(
              children: [
                Icon(Icons.flag, color: AppColors.positiveFg),
                SizedBox(width: 12),
                Expanded(child: Text('Trajeto concluído.')),
              ],
            ),
          )
        else if (trip.inProgress)
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              key: const Key('trip_finish_button'),
              onPressed: onFinish,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Finalizar trajeto'),
            ),
          ),
      ],
    );
  }
}
