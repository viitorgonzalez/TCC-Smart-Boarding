import 'package:flutter/material.dart';
import 'package:smartboarding_app/features/lists/models/daily_list_model.dart';
import 'package:smartboarding_app/features/lists/models/list_entry_model.dart';
import 'package:smartboarding_app/features/lists/services/list_service.dart';

class AdminListEntriesScreen extends StatefulWidget {
  final DailyListModel list;

  const AdminListEntriesScreen({super.key, required this.list});

  @override
  State<AdminListEntriesScreen> createState() => _AdminListEntriesScreenState();
}

class _AdminListEntriesScreenState extends State<AdminListEntriesScreen> {
  final _service = ListService();
  List<ListEntryModel> _entries = [];
  bool _loading = true;
  String? _error;

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
      final entries = await _service.getEntries(widget.list.id);
      if (!mounted) return;
      setState(() {
        _entries = entries;
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

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return Scaffold(
      appBar: AppBar(
        title: Text(list.routeName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: [
                _chip(list.status == 'OPEN' ? 'Aberta' : 'Encerrada',
                    list.status == 'OPEN' ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text('${list.date}  •  ${_entries.length} inscritos',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _entries.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum aluno inscrito ainda.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _entries.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final e = _entries[i];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  e.fullName.isNotEmpty
                                      ? e.fullName[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(e.fullName),
                              subtitle: Text(e.email),
                              trailing: Text(
                                '#${i + 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style:
              TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
