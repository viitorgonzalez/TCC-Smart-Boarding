import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/async_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/trip_type_chip.dart';
import '../models/daily_list_model.dart';
import '../models/list_entry_model.dart';
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
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'Nenhum inscrito nesta lista',
                )
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: InitialsAvatar(
                      text: entries[i].fullName.isNotEmpty
                          ? entries[i].fullName[0].toUpperCase()
                          : '?',
                    ),
                    title: Text(entries[i].fullName),
                    subtitle: Text(entries[i].email),
                    trailing: TripTypeChip(tripType: entries[i].tripType),
                  ),
                ),
        ),
      ),
    );
  }
}
