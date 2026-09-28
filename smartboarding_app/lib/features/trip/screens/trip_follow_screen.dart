import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../models/trip_status_model.dart';
import '../services/trip_service.dart';
import '../widgets/trip_step_tile.dart';

/// O aluno acompanha onde o ônibus parou.
///
/// Só dentro do app, como pedido: nada de push. Quem quer saber abre a tela;
/// quem não quer não é interrompido.
class TripFollowScreen extends StatefulWidget {
  final String listId;

  /// Injetável pro teste; em produção constrói o seu.
  final TripService? service;

  const TripFollowScreen({super.key, required this.listId, this.service});

  @override
  State<TripFollowScreen> createState() => _TripFollowScreenState();
}

class _TripFollowScreenState extends State<TripFollowScreen> {
  /// 20s: o dado muda a cada parada, e o trajeto dura minutos. Mais rápido
  /// gastaria bateria de quem está no ônibus pra ganhar segundos que ninguém
  /// percebe; mais lento faria a tela parecer travada.
  static const _intervalo = Duration(seconds: 20);

  late final TripService _service = widget.service ?? TripService();
  Timer? _timer;

  TripStatus? _trip;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
    _timer = Timer.periodic(_intervalo, (_) => _carregar());
  }

  @override
  void dispose() {
    // Timer vivo depois de sair é vazamento, e gasta bateria de quem está no
    // ônibus justamente quando ela importa.
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final novo = await _service.status(widget.listId);
      if (!mounted) return;
      setState(() {
        _trip = novo;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Só mostra erro se ainda não há nada na tela: uma falha de polling com
      // dado bom à vista não deve apagar o que o aluno está lendo.
      if (_trip == null) setState(() => _erro = AppException.fromError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acompanhar trajeto')),
      body: SafeArea(child: _corpo()),
    );
  }

  Widget _corpo() {
    if (_erro case final erro?) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(erro)),
      );
    }
    final trip = _trip;
    if (trip == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (trip.notStarted)
            const AppCard(
              key: Key('trip_follow_not_started'),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.textSecondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'O trajeto ainda não começou. '
                      'Esta tela atualiza sozinha quando o ônibus sair.',
                    ),
                  ),
                ],
              ),
            )
          else if (trip.myStop case final minha?)
            _MinhaParada(minha: minha, concluido: trip.finished),

          const SizedBox(height: 20),
          Text('Paradas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          AppCard(
            child: Column(
              children: [
                for (final stop in trip.stops)
                  TripStepTile(
                    key: stop.reached
                        ? Key('trip_follow_stop_${stop.stopId}_reached')
                        : Key('trip_follow_stop_${stop.stopId}'),
                    label: stop.name,
                    done: stop.reached,
                    current: trip.current?.stopId == stop.stopId,
                    reachedAt: stop.reachedAt,
                    // A parada dele em destaque: é o ponto que interessa nessa
                    // lista, e sem marcação ele a procura a cada atualização.
                    highlighted: trip.myStop?.stopId == stop.stopId,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinhaParada extends StatelessWidget {
  final MyStop minha;
  final bool concluido;

  const _MinhaParada({required this.minha, required this.concluido});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    if (minha.alreadyReached || concluido) {
      return AppCard(
        key: const Key('trip_follow_already_reached'),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.positiveFg),
            const SizedBox(width: 12),
            Expanded(child: Text('O ônibus já passou por ${minha.stopName}.')),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOCÊ DESCE EM',
            style: texto.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(minha.stopName, style: texto.headlineSmall),

          // Nulo é "não sei": mostrar zero viraria "o ônibus chegou".
          if (minha.etaMinutes case final min?) ...[
            const SizedBox(height: 14),
            Row(
              key: const Key('trip_follow_eta'),
              children: [
                const Icon(Icons.schedule, size: 18, color: AppColors.deepTeal),
                const SizedBox(width: 8),
                Text(
                  'Cerca de $min min até ${minha.stopName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ],

          if (minha.fallback) ...[
            const SizedBox(height: 12),
            Row(
              key: const Key('trip_follow_fallback_warning'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sua instituição não tem parada declarada nesta rota. '
                    'Este é o último ponto do trajeto.',
                    style: texto.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
