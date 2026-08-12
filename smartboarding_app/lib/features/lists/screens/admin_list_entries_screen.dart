import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/async_builder.dart';
import '../models/daily_list_model.dart';
import '../models/list_entry_model.dart';
import '../models/trip_type.dart';
import '../services/list_service.dart';

class AdminListEntriesScreen extends StatelessWidget {
  final DailyList list;
  const AdminListEntriesScreen({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _EntriesProvider(ListService(), list.id)..load(),
      child: _EntriesView(list: list),
    );
  }
}

// ─── Provider local (scoped) ──────────────────────────────────────────────────

class _EntriesProvider extends ChangeNotifier {
  final ListService _service;
  final String listId;

  AsyncValue<List<ListEntry>> _state = const AsyncLoading();
  AsyncValue<List<ListEntry>> get state => _state;

  _EntriesProvider(this._service, this.listId);

  Future<void> load() async {
    _state = const AsyncLoading();
    notifyListeners();
    try {
      _state = AsyncData(await _service.getEntries(listId));
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }
}

// ─── UI ───────────────────────────────────────────────────────────────────────

class _EntriesView extends StatelessWidget {
  final DailyList list;
  const _EntriesView({required this.list});

  @override
  Widget build(BuildContext context) {
    return Consumer<_EntriesProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(list.routeName),
              Text(
                formatDate(list.date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.load,
            ),
          ],
        ),
        body: AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (entries) => entries.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        entries[i].fullName.isNotEmpty
                            ? entries[i].fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(entries[i].fullName),
                    subtitle: Text(entries[i].email),
                    trailing: Chip(
                      avatar: Icon(
                        tripTypeInfo(entries[i].tripType).icon,
                        size: 16,
                      ),
                      label: Text(
                        tripTypeLabel(entries[i].tripType),
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
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
        Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(
          'Nenhum inscrito nesta lista',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ],
    ),
  );
}
