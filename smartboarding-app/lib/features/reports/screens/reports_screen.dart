import 'package:flutter/material.dart';
import 'package:smartboarding_app/features/reports/models/report_model.dart';
import 'package:smartboarding_app/features/reports/screens/report_detail_screen.dart';
import 'package:smartboarding_app/features/reports/services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = ReportService();
  final _scrollController = ScrollController();

  final List<ReportSummaryModel> _reports = [];
  int _page = 0;
  int _totalPages = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(0);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _page + 1 < _totalPages) {
      _loadPage(_page + 1);
    }
  }

  Future<void> _loadPage(int page) async {
    if (page == 0) {
      setState(() {
        _loading = true;
        _error = null;
        _reports.clear();
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final (reports, totalPages) = await _service.getAll(page: page);
      if (!mounted) return;
      setState(() {
        _reports.addAll(reports);
        _page = page;
        _totalPages = totalPages;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${_formatDate(iso)} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Relatórios gerados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!,
                              style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _loadPage(0),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  : _reports.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum relatório disponível.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadPage(0),
                          child: ListView.separated(
                            controller: _scrollController,
                            itemCount: _reports.length + (_loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              if (i == _reports.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                              final r = _reports[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  child: Icon(
                                    Icons.bar_chart,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                    size: 20,
                                  ),
                                ),
                                title: Text(r.routeName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                subtitle: Text(
                                  '${_formatDate(r.listDate)}  •  ${r.totalEntries} inscritos\n'
                                  'Gerado: ${_formatDateTime(r.generatedAt)}',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => ReportDetailScreen(
                                      reportId: r.id,
                                      routeName: r.routeName,
                                    ),
                                  ));
                                },
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
