import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/async_builder.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _DetailProvider(ReportService(), reportId)..load(),
      child: const _DetailView(),
    );
  }
}

// ─── Provider local ───────────────────────────────────────────────────────────

class _DetailProvider extends ChangeNotifier {
  final ReportService _service;
  final String reportId;

  AsyncValue<ReportDetail> _state = const AsyncLoading();
  AsyncValue<ReportDetail> get state => _state;

  _DetailProvider(this._service, this.reportId);

  Future<void> load() async {
    _state = const AsyncLoading();
    notifyListeners();
    try {
      _state = AsyncData(await _service.getById(reportId));
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }
}

// ─── UI ───────────────────────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return Consumer<_DetailProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            switch (provider.state) {
              AsyncData(:final value) => value.routeName,
              _ => 'Relatório',
            },
          ),
        ),
        body: AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (report) => _ReportBody(report: report),
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final ReportDetail report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    List<dynamic> enrolled = [];
    if (report.snapshotData != null) {
      try {
        enrolled = jsonDecode(report.snapshotData!) as List;
      } catch (_) {}
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cabeçalho
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.routeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(height: 24),
                _InfoRow('Data', formatDate(report.listDate)),
                _InfoRow('Total de inscritos', '${report.totalEntries}'),
                _InfoRow('Gerado em', formatDateTime(report.generatedAt)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Lista de inscritos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (enrolled.isEmpty)
          Text('Sem dados de inscritos.',
              style: TextStyle(color: Colors.grey.shade500))
        else
          ...enrolled.asMap().entries.map((e) {
            final data = e.value as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text('${e.key + 1}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
              ),
              title: Text(data['fullName']?.toString() ?? ''),
              subtitle: Text(data['email']?.toString() ?? ''),
            );
          }),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
