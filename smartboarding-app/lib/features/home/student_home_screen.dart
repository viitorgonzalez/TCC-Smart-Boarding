import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/features/lists/models/daily_list_model.dart';
import 'package:smartboarding_app/features/lists/services/list_service.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _service = ListService();

  List<DailyListModel> _lists = [];
  final Map<String, bool> _enrolled = {};
  bool _loading = true;
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lists = await _service.getTodayLists();
      final email =
          context.read<AuthProvider>().currentUser?.email ?? '';

      // Fetch entries for all lists in parallel to check enrollment
      final Map<String, bool> enrolled = {};
      await Future.wait(
        lists.map((l) async {
          try {
            final entries = await _service.getEntries(l.id);
            enrolled[l.id] = entries.any((e) => e.email == email);
          } catch (_) {
            enrolled[l.id] = false;
          }
        }),
      );

      if (!mounted) return;
      setState(() {
        _lists = lists;
        _enrolled.addAll(enrolled);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _toggle(DailyListModel list) async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    final isEnrolled = _enrolled[list.id] ?? false;
    try {
      if (isEnrolled) {
        await _service.removeEntry(list.id);
        if (mounted) setState(() => _enrolled[list.id] = false);
      } else {
        await _service.addEntry(list.id);
        if (mounted) setState(() => _enrolled[list.id] = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartBoarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _lists.isEmpty
                      ? _EmptyView()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _lists.length,
                          itemBuilder: (_, i) => _ListCard(
                            list: _lists[i],
                            isEnrolled: _enrolled[_lists[i].id] ?? false,
                            onToggle: () => _toggle(_lists[i]),
                            actionLoading: _actionLoading,
                          ),
                        ),
                ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final DailyListModel list;
  final bool isEnrolled;
  final VoidCallback onToggle;
  final bool actionLoading;

  const _ListCard({
    required this.list,
    required this.isEnrolled,
    required this.onToggle,
    required this.actionLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    list.routeName,
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusChip(status: list.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(list.date, style: tt.bodySmall),
                const SizedBox(width: 16),
                const Icon(Icons.people_outline,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${list.totalEntries} inscritos', style: tt.bodySmall),
              ],
            ),
            if (list.isOpen) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: isEnrolled
                    ? OutlinedButton.icon(
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Sair da lista'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: cs.error),
                        onPressed: actionLoading ? null : onToggle,
                      )
                    : FilledButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Entrar na lista'),
                        onPressed: actionLoading ? null : onToggle,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'OPEN';
    return Chip(
      label: Text(isOpen ? 'Aberta' : 'Encerrada',
          style: TextStyle(
            fontSize: 11,
            color: isOpen ? Colors.green.shade800 : Colors.grey.shade700,
          )),
      backgroundColor:
          isOpen ? Colors.green.shade50 : Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(
          color: isOpen ? Colors.green.shade300 : Colors.grey.shade400,
          width: 0.5),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Nenhuma lista disponível hoje.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
