import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/loading_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../../core/widgets/status_pill.dart';
import '../models/student_profile_model.dart';
import '../services/user_service.dart';
import 'profile_info_rows.dart';

/// Ficha do aluno, aberta ao tocar nele. Só o admin alcança: o endpoint por trás
/// é hasRole("ADMIN") justamente porque aqui trafega dado de contato.
class StudentProfileSheet extends StatefulWidget {
  final String userId;

  const StudentProfileSheet({super.key, required this.userId});

  @override
  State<StudentProfileSheet> createState() => _StudentProfileSheetState();
}

class _StudentProfileSheetState extends State<StudentProfileSheet> {
  final _service = UserService();
  StudentProfile? _profile;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _service.getProfile(widget.userId);
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  Future<void> _toggle(bool active) async {
    setState(() => _busy = true);
    try {
      final p = await _service.setActive(widget.userId, active);
      if (!mounted) return;
      setState(() => _profile = p);
      showSuccessSnackBar(
        context,
        active ? 'Aluno reativado' : 'Aluno desativado',
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: profile == null
          ? const LoadingCard()
          : StudentProfileBody(
              profile: profile,
              busy: _busy,
              onToggle: _toggle,
            ),
    );
  }
}

/// Corpo do card, separado pra poder ser testado sem rede.
class StudentProfileBody extends StatelessWidget {
  final StudentProfile profile;
  final bool busy;
  final ValueChanged<bool> onToggle;

  const StudentProfileBody({
    super.key,
    required this.profile,
    required this.onToggle,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            InitialsAvatar(
              text: profile.fullName.isNotEmpty
                  ? profile.fullName[0].toUpperCase()
                  : '?',
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.fullName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    [
                      profile.course,
                      profile.institution,
                    ].where((e) => e != null && e.isNotEmpty).join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            StatusPill(
              label: profile.isActive ? 'Ativo' : 'Inativo',
              tone: profile.isActive
                  ? StatusPillTone.positive
                  : StatusPillTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ProfileInfoRows(profile: profile),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: profile.isActive,
          onChanged: busy ? null : onToggle,
          title: const Text('Conta ativa'),
          subtitle: const Text(
            'A mudança fica registrada com seu nome e a hora.',
          ),
        ),
        const Divider(),
        Text('Idas recentes', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(
          profile.recentAttendance.isEmpty
              ? 'Nenhuma nos últimos 6 meses.'
              : profile.recentAttendance.take(6).map(formatDate).join(' · '),
          style: theme.textTheme.bodyMedium,
        ),
        if (profile.statusHistory.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Histórico de status', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final c in profile.statusHistory)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${c.activated ? 'Ativado' : 'Desativado'}'
                '${c.adminName == null ? '' : ' por ${c.adminName}'}'
                ' · ${formatDateTime(c.at)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
