import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/async_value.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/feature_card.dart';
import '../admin/providers/admin_stats_provider.dart';
import '../admin/services/admin_stats_service.dart';
import '../notifications/providers/notification_provider.dart';
import '../notifications/screens/broadcast_screen.dart';
import '../warnings/screens/warnings_screen.dart';
import '../notifications/screens/notifications_inbox_screen.dart';
import '../notifications/services/notification_service.dart';
import '../registration/providers/registration_provider.dart';
import '../registration/screens/registration_approvals_screen.dart';
import '../registration/services/institution_service.dart';
import '../registration/services/registration_service.dart';
import 'widgets/generate_invite_dialog.dart';
import '../reports/providers/report_provider.dart';
import '../reports/screens/reports_screen.dart';
import '../reports/services/report_service.dart';
import '../routes/providers/route_provider.dart';
import '../routes/screens/routes_screen.dart';
import '../routes/services/route_service.dart';
import '../users/providers/user_provider.dart';
import '../users/screens/user_management_screen.dart';
import '../users/services/user_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Providers escopados ao admin — criados aqui, destruídos ao sair
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RouteProvider(RouteService())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(ReportService())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(NotificationService()),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(UserService())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              RegistrationProvider(RegistrationService(), InstitutionService())
                ..loadPending(),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminStatsProvider(AdminStatsService())..load(),
        ),
      ],
      child: const _AdminDashboard(),
    );
  }
}

// ─── Painel do admin (dashboard de cards) ────────────────────────────────────

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  /// O push sai no Navigator raiz, acima do MultiProvider — sem repassar as
  /// instâncias, cada tela abriria sem o seu provider.
  void _open(
    BuildContext context,
    String title,
    Widget child, {
    List<Widget>? actions,
  }) {
    final routeProvider = context.read<RouteProvider>();
    final reportProvider = context.read<ReportProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final userProvider = context.read<UserProvider>();
    final registrationProvider = context.read<RegistrationProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: routeProvider),
            ChangeNotifierProvider.value(value: reportProvider),
            ChangeNotifierProvider.value(value: notificationProvider),
            ChangeNotifierProvider.value(value: userProvider),
            ChangeNotifierProvider.value(value: registrationProvider),
          ],
          child: Scaffold(
            appBar: AppBar(title: Text(title), actions: actions),
            body: child,
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<RegistrationProvider>().loadPending(),
      context.read<AdminStatsProvider>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.token?.fullName ?? 'Admin';
    final pending = switch (context.watch<RegistrationProvider>().pending) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            overline: 'GESTÃO DE TRANSPORTE',
            title: 'Painel do Admin',
            trailing: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.mutedTeal,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AlertCard(
                    icon: Icons.person_add_alt_1,
                    title: 'Solicitações',
                    subtitle: 'Aguardando aprovação',
                    count: pending,
                    onTap: () => _open(
                      context,
                      'Solicitações de cadastro',
                      const RegistrationApprovalsScreen(),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.mail_outline),
                          tooltip: 'Gerar convite',
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => const GenerateInviteDialog(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle('Funcionalidades'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      FeatureCard(
                        icon: Icons.route_outlined,
                        label: 'Rotas e Listas',
                        onTap: () => _open(
                          context,
                          'Rotas e Listas',
                          const RoutesScreen(),
                        ),
                      ),
                      FeatureCard(
                        icon: Icons.campaign_outlined,
                        label: 'Enviar Aviso',
                        onTap: () => _open(
                          context,
                          'Enviar Aviso',
                          const BroadcastScreen(),
                        ),
                      ),
                      FeatureCard(
                        icon: Icons.notifications_none,
                        label: 'Avisos enviados',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationsInboxScreen(canManage: true),
                          ),
                        ),
                      ),
                      FeatureCard(
                        icon: Icons.report_gmailerrorred_outlined,
                        label: 'Advertências',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const WarningsScreen(canManage: true),
                          ),
                        ),
                      ),
                      FeatureCard(
                        icon: Icons.bar_chart_outlined,
                        label: 'Relatórios',
                        onTap: () =>
                            _open(context, 'Relatórios', const ReportsScreen()),
                      ),
                      FeatureCard(
                        icon: Icons.group_outlined,
                        label: 'Usuários',
                        onTap: () => _open(
                          context,
                          'Usuários',
                          const UserManagementScreen(),
                          // Aluno só nasce por convite; sem isto a tela de
                          // usuários não teria como trazer um.
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.person_add_alt_outlined),
                              tooltip: 'Convidar aluno',
                              onPressed: () => showDialog<bool>(
                                context: context,
                                builder: (_) => const GenerateInviteDialog(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle('Resumo de Hoje'),
                  const SizedBox(height: 12),
                  const _TodaySummary(),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: auth.logout,
                      child: const Text(
                        'Sair do Painel',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminStatsProvider>(
      builder: (context, provider, _) {
        final rows = switch (provider.state) {
          AsyncData(:final value) => [
            ('Alunos Ativos', '${value.activeStudents}'),
            ('Rotas em Uso', '${value.routesInUse}'),
            ('Ocupação', '${value.occupancyPercent}%'),
          ],
          AsyncError() => [('Não foi possível carregar', '—')],
          _ => [
            ('Alunos Ativos', '…'),
            ('Rotas em Uso', '…'),
            ('Ocupação', '…'),
          ],
        };
        return Container(
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(color: Colors.white24, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          rows[i].$1,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        rows[i].$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Tab de listas (admin) ────────────────────────────────────────────────────
