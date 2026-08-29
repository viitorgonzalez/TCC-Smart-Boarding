import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/async_value.dart';
import '../../admin/providers/admin_stats_provider.dart';

/// Resumo de hoje no painel do admin.
class TodaySummary extends StatelessWidget {
  const TodaySummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminStatsProvider>(
      builder: (context, provider, _) {
        final rows = switch (provider.state) {
          AsyncData(:final value) => [
            ('Alunos Ativos', '${value.activeStudents}'),
            ('Rotas em Uso', '${value.routesInUse}'),
            ('Ocupação', '${value.occupancyPercent}%'),
          ],
          AsyncError() => [('Não foi possível carregar', '—')],
          _ => [
            ('Alunos Ativos', '…'),
            ('Rotas em Uso', '…'),
            ('Ocupação', '…'),
          ],
        };
        return Container(
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(color: Colors.white24, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          rows[i].$1,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        rows[i].$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Tab de listas (admin) ────────────────────────────────────────────────────
