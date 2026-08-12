import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/async_builder.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) => AsyncBuilder(
        value: provider.state,
        onRetry: provider.load,
        builder: (items) => items.isEmpty
            ? const _EmptyState()
            : NotificationListener<ScrollEndNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 300) provider.loadMore();
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + (provider.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _ReportTile(report: items[i]);
                    },
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
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            Icons.bar_chart,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Text(
          report.routeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${formatDate(report.listDate)} · ${report.totalEntries} inscrito(s)',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(reportId: report.id),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bar_chart, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(
          'Nenhum relatório disponível',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ],
    ),
  );
}
