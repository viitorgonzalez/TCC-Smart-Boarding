import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/async_builder.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/snackbar_utils.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/trip_type_chip.dart';
import '../lists/models/list_entry_model.dart';
import '../lists/models/list_with_enrollment.dart';
import '../../core/models/trip_type.dart';
import '../lists/providers/student_list_provider.dart';
import '../lists/services/list_service.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.token?.fullName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Boarding'),
            if (name.isNotEmpty)
              Text(
                'Olá, $name',
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
            onPressed: () => context.read<StudentListProvider>().load(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Consumer<StudentListProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (items) => items.isEmpty
              ? const EmptyState(
                  icon: Icons.event_busy,
                  title: 'Nenhuma lista disponível hoje',
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ListCard(
                        item: items[i],
                        onEnter: (tripType) =>
                            _enter(context, provider, items[i], tripType),
                        onLeave: () => _leave(context, provider, items[i]),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _enter(
    BuildContext context,
    StudentListProvider provider,
    ListWithEnrollment item,
    String tripType,
  ) async {
    try {
      await provider.enter(item.list.id, tripType);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _leave(
    BuildContext context,
    StudentListProvider provider,
    ListWithEnrollment item,
  ) async {
    try {
      await provider.leave(item.list.id);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  void _showError(BuildContext context, Object e) {
    showErrorSnackBar(context, e.toString());
  }
}

/// Bottom sheet para escolher a direção (ida/volta). Retorna o valor da API.
Future<String?> showTripTypePicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Escolha a direção',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          for (final t in tripTypes)
            ListTile(
              leading: Icon(t.icon),
              title: Text(t.label),
              trailing: current == t.value
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, t.value),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

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

// ─── Card de lista ────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final ListWithEnrollment item;
  final void Function(String tripType) onEnter;
  final VoidCallback onLeave;

  const _ListCard({
    required this.item,
    required this.onEnter,
    required this.onLeave,
  });

  Future<void> _pickAndEnter(BuildContext context, {String? current}) async {
    final chosen = await showTripTypePicker(context, current: current);
    if (chosen != null) onEnter(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final list = item.list;
    final cs = Theme.of(context).colorScheme;

    return Card(
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                StatusPill(
                  label: list.isOpen ? 'Aberta' : 'Fechada',
                  tone: list.isOpen
                      ? StatusPillTone.positive
                      : StatusPillTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${list.totalEntries} inscrito(s) · ${formatDate(list.date)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () =>
                    showListMembers(context, list.id, list.routeName),
                icon: const Icon(Icons.people_outline, size: 18),
                label: const Text('Ver quem está na lista'),
              ),
            ),
            if (item.isEnrolled) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Você está na lista',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Direção atual + trocar (enquanto a lista estiver aberta)
              Row(
                children: [
                  TripTypeChip(tripType: item.tripType, iconSize: 18),
                  if (list.isOpen)
                    TextButton.icon(
                      onPressed: () =>
                          _pickAndEnter(context, current: item.tripType),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Trocar direção'),
                    ),
                ],
              ),
            ],
            if (list.isOpen) ...[
              const SizedBox(height: 12),
              const _CloseCountdown(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: item.isEnrolled
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                        ),
                        onPressed: onLeave,
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Sair da lista'),
                      )
                    : FilledButton.icon(
                        onPressed: () => _pickAndEnter(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Entrar na lista'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Contagem regressiva até o fechamento (16:00) ─────────────────────────────

class _CloseCountdown extends StatefulWidget {
  const _CloseCountdown();

  @override
  State<_CloseCountdown> createState() => _CloseCountdownState();
}

class _CloseCountdownState extends State<_CloseCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = timeUntilListClose();
    final closingSoon = remaining == null;
    final color = closingSoon ? cs.error : cs.primary;
    final text = closingSoon
        ? 'Fechamento às 16:00 — encerrando'
        : 'Fecha em ${humanizeDuration(remaining)} · às 16:00';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
