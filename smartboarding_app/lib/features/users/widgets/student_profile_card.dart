import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/loading_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../../core/widgets/status_pill.dart';
import '../models/student_profile_model.dart';
import '../services/user_service.dart';
import 'profile_info_rows.dart';

class StudentProfileSheet extends StatefulWidget {
  final String userId;

  final VoidCallback? onChanged;

  const StudentProfileSheet({super.key, required this.userId, this.onChanged});

  @override
  State<StudentProfileSheet> createState() => StudentProfileSheetState();
}

class StudentProfileSheetState extends State<StudentProfileSheet> {
  final _service = UserService();
  StudentProfile? _profile;
  bool _busy = false;
  int? _adminCount;

  @visibleForTesting
  late final Future<void> carregado;

  @override
  void initState() {
    super.initState();
    carregado = Future.wait([_load(), _loadAdminCount()]);
  }

  Future<void> _load() async {
    try {
      final p = await _service.getProfile(widget.userId);
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  Future<void> _loadAdminCount() async {
    try {
      final count = await _service.getAdminCount();
      if (mounted) setState(() => _adminCount = count);
    } catch (_) {}
  }

  Future<void> _toggle(bool active) async {
    setState(() => _busy = true);
    try {
      final p = await _service.setActive(widget.userId, active);
      widget.onChanged?.call();
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

  Future<void> _toggleRole() async {
    final atual = _profile;
    if (atual == null) return;
    final novoPapel = atual.role == 'ADMIN' ? 'STUDENT' : 'ADMIN';
    setState(() => _busy = true);
    try {
      final p = await _service.setRole(widget.userId, novoPapel);
      widget.onChanged?.call();
      if (!mounted) return;
      setState(() => _profile = p);
      showSuccessSnackBar(
        context,
        novoPapel == 'ADMIN'
            ? 'Acesso de administrador concedido'
            : 'Acesso de administrador removido',
      );
      await _loadAdminCount();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final meuEmail = context.watch<AuthProvider>().token?.email;
    final ehAPropriaConta = profile != null && profile.email == meuEmail;
    final ehUltimoAdmin =
        profile != null &&
        profile.role == 'ADMIN' &&
        _adminCount != null &&
        _adminCount! <= 1;
    return PopScope(
      canPop: !_busy,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: profile == null
            ? const LoadingCard()
            : StudentProfileBody(
                profile: profile,
                busy: _busy,
                onToggle: _toggle,
                onToggleRole: _toggleRole,
                ehAPropriaConta: ehAPropriaConta,
                ehUltimoAdmin: ehUltimoAdmin,
              ),
      ),
    );
  }
}

class StudentProfileBody extends StatelessWidget {
  final StudentProfile profile;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onToggleRole;
  final bool ehAPropriaConta;
  final bool ehUltimoAdmin;

  const StudentProfileBody({
    super.key,
    required this.profile,
    required this.onToggle,
    required this.onToggleRole,
    required this.ehAPropriaConta,
    required this.ehUltimoAdmin,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cannotDeactivate = profile.role == 'ADMIN' && profile.isActive;
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
          key: const Key('profile_active_switch'),
          contentPadding: EdgeInsets.zero,
          value: profile.isActive,
          onChanged: busy || cannotDeactivate ? null : onToggle,
          title: const Text('Conta ativa'),
          subtitle: Text(
            cannotDeactivate
                ? 'Remova o acesso de administrador antes de desativar.'
                : 'A mudança fica registrada com seu nome e a hora.',
          ),
        ),
        if (!ehAPropriaConta)
          ListTile(
            key: const Key('profile_role_action'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.shield_outlined),
            title: Text(
              profile.role == 'ADMIN'
                  ? 'Remover acesso de administrador'
                  : 'Tornar administrador',
            ),
            subtitle: const Text('Fica registrado com seu nome e a hora.'),
            enabled:
                !busy &&
                (profile.role == 'ADMIN' || profile.isActive) &&
                !ehUltimoAdmin,
            onTap: busy ? null : onToggleRole,
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
