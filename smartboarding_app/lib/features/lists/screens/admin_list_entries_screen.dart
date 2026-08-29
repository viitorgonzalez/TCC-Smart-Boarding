import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/institution_breakdown.dart';
import '../../../core/utils/async_value.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/async_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../../core/widgets/trip_type_chip.dart';
import '../../users/models/user_model.dart';
import '../../users/services/user_service.dart';
import '../models/daily_list_model.dart';
import '../models/list_entry_model.dart';
import '../services/list_service.dart';

class AdminListEntriesScreen extends StatelessWidget {
  final DailyList list;
  const AdminListEntriesScreen({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          _EntriesProvider(ListService(), list.id, list.routeId)..load(),
      child: _EntriesView(list: list),
    );
  }
}

// ─── Provider local (scoped) ──────────────────────────────────────────────────

class _EntriesProvider extends ChangeNotifier {
  final ListService _service;
  final String listId;

  /// A inclusão pelo admin escolhe entre os alunos da rota desta lista.
  final String routeId;

  AsyncValue<List<ListEntry>> _state = const AsyncLoading();
  AsyncValue<List<ListEntry>> get state => _state;

  _EntriesProvider(this._service, this.listId, this.routeId);

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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addStudent(context, provider),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Incluir aluno'),
        ),
        body: AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (entries) => entries.isEmpty
              ? RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.people_outline,
                        title: 'Nenhum inscrito nesta lista',
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.builder(
                    // +1 pelo cabeçalho com a divisão por instituição.
                    itemCount: entries.length + 1,
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: InstitutionBreakdown(
                            counts: _countByInstitution(entries),
                          ),
                        );
                      }
                      final i = index - 1;
                      return ListTile(
                        leading: InitialsAvatar(
                          text: entries[i].fullName.isNotEmpty
                              ? entries[i].fullName[0].toUpperCase()
                              : '?',
                        ),
                        title: Text(entries[i].fullName),
                        isThreeLine: true,
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entries[i].email),
                            Text(
                              'Entrou às ${formatTime(entries[i].createdAt)}',
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TripTypeChip(tripType: entries[i].tripType),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.person_remove_outlined,
                                size: 20,
                                color: AppColors.danger,
                              ),
                              tooltip: 'Tirar da lista',
                              onPressed: () =>
                                  _removeStudent(context, provider, entries[i]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

/// Inclusão tardia: o admin põe o aluno na lista mesmo fechada, e decide se
/// isso vira advertência — colocar o nome no prazo é responsabilidade do aluno,
/// mas nem todo atraso é culpa dele.
Future<void> _addStudent(
  BuildContext context,
  _EntriesProvider provider,
) async {
  final students = await _pickStudent(context, provider.routeId);
  if (students == null || !context.mounted) return;

  final decision = await showModalBottomSheet<_EnrollDecision>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _EnrollSheet(student: students),
  );
  if (decision == null) return;

  try {
    await ListService().addEntryAsAdmin(
      provider.listId,
      userId: students.id,
      issueWarning: decision.issueWarning,
      warningReason: decision.reason,
    );
    if (context.mounted) {
      showSuccessSnackBar(
        context,
        decision.issueWarning
            ? '${students.fullName} incluído com advertência'
            : '${students.fullName} incluído sem advertência',
      );
    }
    await provider.load();
  } catch (e) {
    if (context.mounted) showErrorSnackBar(context, AppException.fromError(e));
  }
}

Future<UserModel?> _pickStudent(BuildContext context, String routeId) async {
  List<UserModel> students;
  try {
    students = (await UserService().getUsers(
      routeId: routeId,
    )).where((u) => u.role == 'STUDENT').toList();
  } catch (e) {
    if (context.mounted) showErrorSnackBar(context, AppException.fromError(e));
    return null;
  }
  if (!context.mounted) return null;
  if (students.isEmpty) {
    showErrorSnackBar(context, 'Nenhum aluno nesta rota.');
    return null;
  }
  return showModalBottomSheet<UserModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _StudentPicker(students: students),
  );
}

Future<void> _removeStudent(
  BuildContext context,
  _EntriesProvider provider,
  ListEntry entry,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Tirar da lista?'),
      content: Text('${entry.fullName} sai da lista de hoje.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Tirar'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ListService().removeEntryAsAdmin(provider.listId, entry.userId);
    if (context.mounted) showSuccessSnackBar(context, 'Removido da lista');
    await provider.load();
  } catch (e) {
    if (context.mounted) showErrorSnackBar(context, AppException.fromError(e));
  }
}

class _EnrollDecision {
  final bool issueWarning;
  final String? reason;
  const _EnrollDecision({required this.issueWarning, this.reason});
}

class _StudentPicker extends StatefulWidget {
  final List<UserModel> students;
  const _StudentPicker({required this.students});

  @override
  State<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends State<_StudentPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.students
        .where(
          (s) => s.fullName.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Qual aluno?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por nome',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search,
                      title: 'Nenhum aluno com esse nome',
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: InitialsAvatar(
                          text: filtered[i].fullName.isNotEmpty
                              ? filtered[i].fullName[0].toUpperCase()
                              : '?',
                        ),
                        title: Text(filtered[i].fullName),
                        subtitle: Text(
                          filtered[i].institution ?? filtered[i].email,
                        ),
                        onTap: () => Navigator.pop(context, filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollSheet extends StatefulWidget {
  final UserModel student;
  const _EnrollSheet({required this.student});

  @override
  State<_EnrollSheet> createState() => _EnrollSheetState();
}

class _EnrollSheetState extends State<_EnrollSheet> {
  bool _issueWarning = true;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Incluir ${widget.student.fullName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Entra na lista mesmo fora do horário.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _issueWarning,
              onChanged: (v) => setState(() => _issueWarning = v),
              title: const Text('Gerar advertência'),
              subtitle: const Text(
                'Colocar o nome no prazo é responsabilidade do aluno — mas a '
                'escolha é sua.',
              ),
            ),
            if (_issueWarning) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _reasonCtrl,
                maxLines: 2,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  hintText: 'Em branco usa o motivo padrão.',
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _EnrollDecision(
                        issueWarning: _issueWarning,
                        reason: _reasonCtrl.text.trim().isEmpty
                            ? null
                            : _reasonCtrl.text.trim(),
                      ),
                    ),
                    child: const Text('Incluir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, int> _countByInstitution(List<ListEntry> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    final name = entry.institutionName ?? 'Sem instituição';
    counts[name] = (counts[name] ?? 0) + 1;
  }
  return counts;
}
