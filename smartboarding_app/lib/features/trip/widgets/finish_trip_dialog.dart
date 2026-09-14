import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/trip_status_model.dart';

/// Confirmação de encerramento. Lista as paradas não marcadas em vez de
/// bloquear: o ônibus pode pular parada legitimamente (ninguém esperando), e
/// travar o encerramento deixaria o admin preso no fim do dia. Mas ele precisa
/// ver o que ficou pra trás antes de decidir — pode ter sido esquecimento.
Future<bool> confirmFinishTrip(BuildContext context, TripStatus trip) async {
  final pendentes = trip.stops.where((s) => !s.reached).toList();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Finalizar trajeto?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendentes.isEmpty)
            const Text('Todas as paradas foram marcadas.')
          else ...[
            Text(
              pendentes.length == 1
                  ? '1 parada não foi marcada:'
                  : '${pendentes.length} paradas não foram marcadas:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final s in pendentes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.radio_button_unchecked,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.name)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Elas ficam registradas como não visitadas.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          const Text('Todos os alunos da rota são avisados.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Voltar'),
        ),
        FilledButton(
          key: const Key('trip_finish_confirm'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Finalizar'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
