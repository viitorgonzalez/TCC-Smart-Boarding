import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
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
import '../reports/providers/report_provider.dart';
import '../reports/screens/reports_screen.dart';
import '../reports/services/report_service.dart';
import '../routes/providers/route_provider.dart';
import '../routes/screens/routes_screen.dart';
import '../routes/services/route_service.dart';
import '../users/providers/user_provider.dart';
import '../../core/utils/async_value.dart';
import '../institutions/providers/institution_provider.dart';
import '../institutions/screens/institutions_screen.dart';
import '../routes/screens/invite_codes_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../profile/screens/profile_requests_screen.dart';
import '../users/screens/user_management_screen.dart';
import '../users/services/user_service.dart';
import 'widgets/today_summary.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          create: (_) => AdminStatsProvider(AdminStatsService())..load(),
        ),
        ChangeNotifierProvider(create: (_) => InstitutionProvider()..load()),
      ],
      child: const _AdminDashboard(),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

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
    final institutionProvider = context.read<InstitutionProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: routeProvider),
            ChangeNotifierProvider.value(value: reportProvider),
            ChangeNotifierProvider.value(value: notificationProvider),
            ChangeNotifierProvider.value(value: userProvider),
            ChangeNotifierProvider.value(value: institutionProvider),
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
    await context.read<AdminStatsProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.token?.fullName ?? 'Admin';

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            overline: 'GESTÃO DE TRANSPORTE',
            title: 'Painel do Admin',
            trailing: InkWell(
              key: const Key('admin_open_profile'),
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: CircleAvatar(
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
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  GridView.count(
                    padding: EdgeInsets.zero,
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: AppGrid.featureAspectRatio,
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
                        icon: Icons.vpn_key_outlined,
                        label: 'Códigos de acesso',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => InviteCodesScreen(
                              routes: switch (context
                                  .read<RouteProvider>()
                                  .state) {
                                AsyncData(:final value) => value,
                                _ => const [],
                              },
                            ),
                          ),
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
                        icon: Icons.group_outlined,
                        label: 'Usuários',
                        onTap: () => _open(
                          context,
                          'Usuários',
                          const UserManagementScreen(),
                        ),
                      ),
                      FeatureCard(
                        icon: Icons.bar_chart_outlined,
                        label: 'Relatórios',
                        onTap: () =>
                            _open(context, 'Relatórios', const ReportsScreen()),
                      ),
                      FeatureCard(
                        icon: Icons.school_outlined,
                        label: 'Instituições',
                        onTap: () => _open(
                          context,
                          'Instituições',
                          InstitutionsScreen(
                            routes: switch (context
                                .read<RouteProvider>()
                                .state) {
                              AsyncData(:final value) => value,
                              _ => const [],
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<AdminStatsProvider>(
                    builder: (context, provider, _) {
                      final pending = switch (provider.state) {
                        AsyncData(:final value) => value.pendingProfileRequests,
                        _ => 0,
                      };
                      return AlertCard(
                        icon: Icons.fact_check_outlined,
                        title: 'Solicitações',
                        subtitle: 'Pedidos de alteração de perfil pra revisar',
                        count: pending,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileRequestsScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle('Resumo de Hoje'),
                  const SizedBox(height: 12),
                  const TodaySummary(),
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
