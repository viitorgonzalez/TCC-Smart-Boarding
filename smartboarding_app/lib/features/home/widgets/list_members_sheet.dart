import 'package:flutter/material.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/trip_type_chip.dart';
import '../../lists/models/list_entry_model.dart';
import '../../lists/services/list_service.dart';

/// Mostra quem está inscrito na lista (nome + direção), pra qualquer aluno.
void showListMembers(BuildContext context, String listId, String routeName) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MembersSheet(listId: listId, routeName: routeName),
  );
}

class _MembersSheet extends StatefulWidget {
  final String listId;
  final String routeName;
  const _MembersSheet({required this.listId, required this.routeName});

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  late Future<List<ListEntry>> _future = ListService().getEntries(
    widget.listId,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quem está na lista · ${widget.routeName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() {
                    _future = ListService().getEntries(widget.listId);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: FutureBuilder<List<ListEntry>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: ErrorState(
                        message: 'Erro ao carregar: ${snap.error}',
                      ),
                    );
                  }
                  final entries = snap.data ?? [];
                  if (entries.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Ninguém na lista ainda.'),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return ListTile(
                        dense: true,
                        leading: InitialsAvatar(
                          text: e.fullName.isNotEmpty
                              ? e.fullName[0].toUpperCase()
                              : '?',
                        ),
                        title: Text(e.fullName),
                        trailing: TripTypeChip(tripType: e.tripType),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
