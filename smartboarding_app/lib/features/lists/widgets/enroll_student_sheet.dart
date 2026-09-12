import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/theme/app_theme.dart';
import '../../users/models/user_model.dart';

/// Escolha do aluno e decisão sobre a advertência na inclusão tardia.
class EnrollDecision {
  final bool issueWarning;
  final String? reason;
  const EnrollDecision({required this.issueWarning, this.reason});
}

class StudentPicker extends StatefulWidget {
  final List<UserModel> students;
  const StudentPicker({super.key, required this.students});

  @override
  State<StudentPicker> createState() => StudentPickerState();
}

class StudentPickerState extends State<StudentPicker> {
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

class EnrollSheet extends StatefulWidget {
  final UserModel student;
  const EnrollSheet({super.key, required this.student});

  @override
  State<EnrollSheet> createState() => EnrollSheetState();
}

class EnrollSheetState extends State<EnrollSheet> {
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
                      EnrollDecision(
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

/// Confirmação final da inclusão tardia. Existe separada do EnrollSheet porque
/// a ação é irreversível pelo lado do aluno: a advertência entra no histórico
/// dele e sair de lá exige o admin apagar à mão.
Future<bool> confirmEnroll(
  BuildContext context,
  UserModel student,
  EnrollDecision decision,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Incluir ${student.fullName}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('O aluno entra na lista mesmo fora do horário.'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                decision.issueWarning
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                size: 20,
                color: decision.issueWarning
                    ? AppColors.danger
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  decision.issueWarning
                      ? 'Uma advertência vai para o histórico do aluno.'
                      : 'Nenhuma advertência será gerada.',
                  style: TextStyle(
                    fontWeight: decision.issueWarning
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          if (decision.issueWarning && decision.reason != null) ...[
            const SizedBox(height: 10),
            Text(
              'Motivo: ${decision.reason}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
