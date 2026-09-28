import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/async_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';
import 'report_detail_screen.dart';
import '../../../core/text/plural.dart';
import '../../../core/widgets/app_list_group.dart';
import '../../../core/theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) => AsyncBuilder(
        value: provider.state,
        onRetry: provider.load,
        builder: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.bar_chart,
                title: 'Nenhum relatório disponível',
              )
            : NotificationListener<ScrollEndNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 300) provider.loadMore();
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      AppListGroup(
                        dividerIndent: 68,
                        children: [
                          for (final report in items)
                            _ReportTile(report: report),
                        ],
                      ),
                      if (provider.hasMore)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Tiles e estados ──────────────────────────────────────────────────────────

class _ReportTile extends StatelessWidget {
  final ReportSummary report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return AppListItem(
      leading: const Icon(Icons.bar_chart_outlined, color: AppColors.deepTeal),
      title: report.routeName,
      subtitle:
          '${formatDate(report.listDate)} · '
          '${contagem(report.totalEntries, 'inscrito', 'inscritos')}',
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportDetailScreen(reportId: report.id),
        ),
      ),
    );
  }
}
