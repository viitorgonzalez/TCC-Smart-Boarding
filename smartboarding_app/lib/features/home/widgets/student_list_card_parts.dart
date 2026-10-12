import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../lists/models/daily_list_model.dart';

class TempoDeViagem extends StatelessWidget {
  final MyTripTime tempo;

  const TempoDeViagem({super.key, required this.tempo});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('list_trip_time'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.schedule, size: 18, color: AppColors.deepTeal),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cerca de ${tempo.avgMinutes} min até ${tempo.stopName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              if (tempo.fallback)
                Text(
                  'Sua instituição não tem parada declarada nesta rota — '
                  'este é o último ponto do trajeto.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileWarning extends StatelessWidget {
  final List<String> missing;
  final VoidCallback? onFix;

  const ProfileWarning({super.key, required this.missing, this.onFix});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('list_profile_warning'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                size: 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Complete seu perfil para entrar na lista.',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              'Falta: ${missing.join(', ')}.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              key: const Key('list_profile_fix_button'),
              onPressed: onFix,
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Completar perfil'),
            ),
          ),
        ],
      ),
    );
  }
}
