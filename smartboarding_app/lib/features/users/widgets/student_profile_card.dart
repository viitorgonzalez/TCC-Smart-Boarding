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

/// Ficha do aluno, aberta ao tocar nele. Só o admin alcança: o endpoint por trás
/// é hasRole("ADMIN") justamente porque aqui trafega dado de contato.
class StudentProfileSheet extends StatefulWidget {
  final String userId;

  const StudentProfileSheet({super.key, required this.userId});

  @override
  State<StudentProfileSheet> createState() => StudentProfileSheetState();
}

class StudentProfileSheetState extends State<StudentProfileSheet> {
  final _service = UserService();
  StudentProfile? _profile;
  bool _busy = false;
  // null = ainda nao sabemos (carregando ou a busca falhou). Enquanto for
  // null, a trava do ultimo admin fica de fora -- desabilitar sem dado seria
  // pior que deixar o backend recusar, que e o comportamento de hoje.
  int? _adminCount;

  /// Resolve quando as duas buscas do initState (perfil e contagem de admins)
  /// terminam -- sucesso ou falha, já que as duas tratam o próprio erro
  /// internamente e nunca relançam. Existe só pro teste aguardar a ficha
  /// carregar por condição, não por uma duração chutada -- ver
  /// student_profile_card_test.dart.
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

  /// Conta os admins pelo mesmo endpoint que a tela de usuarios ja usa --
  /// sem endpoint novo. Fica em silencio no erro: essa contagem so serve pra
  /// UI evitar um toque que o backend ia recusar de qualquer forma, entao uma
  /// falha aqui nao pode virar outro alerta pro admin.
  Future<void> _loadAdminCount() async {
    try {
      final users = await _service.getUsers();
      final count = users.where((u) => u.role == 'ADMIN').length;
      if (mounted) setState(() => _adminCount = count);
    } catch (_) {
      // _adminCount continua null de proposito.
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

  Future<void> _toggleRole() async {
    final atual = _profile;
    if (atual == null) return;
    final novoPapel = atual.role == 'ADMIN' ? 'STUDENT' : 'ADMIN';
    setState(() => _busy = true);
    try {
      final p = await _service.setRole(widget.userId, novoPapel);
      if (!mounted) return;
      setState(() => _profile = p);
      showSuccessSnackBar(
        context,
        novoPapel == 'ADMIN'
            ? 'Acesso de administrador concedido'
            : 'Acesso de administrador removido',
      );
      // A contagem muda pra todo mundo depois de promover/rebaixar -- reflete
      // aqui pra travar de novo se esta virou a ultima conta admin.
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
    // Identifica a propria conta pelo e-mail: e a mesma chave que o resto do
    // app usa pra "sou eu" (StudentListProvider.setUserEmail em main.dart) --
    // o token de sessao nunca carregou um id de usuario.
    final meuEmail = context.watch<AuthProvider>().token?.email;
    final ehAPropriaConta = profile != null && profile.email == meuEmail;
    // null (ainda carregando/falhou) nao trava por engano -- só com contagem
    // confirmada de exatamente 1 admin (esta conta) a trava entra.
    final ehUltimoAdmin =
        profile != null &&
        profile.role == 'ADMIN' &&
        _adminCount != null &&
        _adminCount! <= 1;
    return Padding(
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
    );
  }
}

/// Corpo do card, separado pra poder ser testado sem rede.
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
