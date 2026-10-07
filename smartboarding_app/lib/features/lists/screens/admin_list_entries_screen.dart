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
import '../../../core/widgets/student_sheet.dart';
import '../../../core/widgets/trip_type_chip.dart';
import '../../users/models/user_model.dart';
import '../../users/services/user_service.dart';
import '../models/daily_list_model.dart';
import '../models/list_entry_model.dart';
import '../services/list_service.dart';
import '../widgets/enroll_student_sheet.dart';

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

class _EntriesProvider extends ChangeNotifier {
  final ListService _service;
  final String listId;

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
                        onTap: () =>
                            showStudentProfile(context, entries[i].userId),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: Text(entries[i].fullName)),
                            if (entries[i].addedByAdmin) ...[
                              const SizedBox(width: 6),
                              const Tooltip(
                                message: 'Incluído pelo admin',
                                child: Icon(
                                  Icons.admin_panel_settings_outlined,
                                  size: 16,
                                  color: AppColors.deepTeal,
                                ),
                              ),
                            ],
                          ],
                        ),
                        isThreeLine: true,
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entries[i].email ?? '—'),
                            Text(
                              entries[i].addedByAdmin
                                  ? 'Incluído pelo admin às ${formatTime(entries[i].createdAt)}'
                                  : 'Entrou às ${formatTime(entries[i].createdAt)}',
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

Future<void> _addStudent(
  BuildContext context,
  _EntriesProvider provider,
) async {
  final students = await _pickStudent(context, provider.routeId);
  if (students == null || !context.mounted) return;

  final decision = await showModalBottomSheet<EnrollDecision>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => EnrollSheet(student: students),
  );
  if (decision == null || !context.mounted) return;

  if (!await confirmEnroll(context, students, decision)) return;
  if (!context.mounted) return;

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
    students = (await UserService().getAllUsers(
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
    builder: (_) => StudentPicker(students: students),
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

Map<String, int> _countByInstitution(List<ListEntry> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    final name = entry.institutionName ?? 'Sem instituição';
    counts[name] = (counts[name] ?? 0) + 1;
  }
  return counts;
}
