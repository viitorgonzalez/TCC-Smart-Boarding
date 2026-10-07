import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/text/names.dart';
import '../../core/utils/async_value.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/feature_card.dart';
import '../lists/providers/student_list_provider.dart';
import '../membership/providers/membership_provider.dart';
import '../membership/screens/join_route_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../membership/widgets/no_route_card.dart';
import '../membership/widgets/route_selector.dart';
import '../notifications/screens/notifications_inbox_screen.dart';
import '../reports/screens/my_attendance_screen.dart';
import '../warnings/screens/warnings_screen.dart';
import 'my_routes_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  void _open(BuildContext context, Widget screen, {bool keepList = false}) {
    final listProvider = context.read<StudentListProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => keepList
            ? ChangeNotifierProvider.value(value: listProvider, child: screen)
            : screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.token?.fullName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final saudacao = primeiroNome(name, fallback: 'Aluno');

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            overline: _greeting(),
            title: saudacao,
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.mutedTeal,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeaderIconButton(
                  key: const Key('student_home_join_route'),
                  icon: Icons.add,
                  tooltip: 'Entrar com código',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JoinRouteScreen()),
                  ),
                ),
                HeaderOverflowMenu(
                  items: [
                    HeaderMenuItem(
                      label: 'Meu perfil',
                      icon: Icons.person_outline,
                      onSelected: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                    ),
                    HeaderMenuItem(
                      label: 'Sair',
                      icon: Icons.logout,
                      onSelected: auth.logout,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: context.read<StudentListProvider>().load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (context.watch<MembershipProvider>().hasNoRoute) ...[
                    const NoRouteCard(),
                    const SizedBox(height: 24),
                  ] else ...[
                    const RouteSelector(),
                    const _TodayStatus(),
                    const SizedBox(height: 24),
                  ],
                  const SectionTitle('O que você pode fazer'),
                  const SizedBox(height: 12),
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
                        icon: Icons.directions_bus_outlined,
                        label: 'Minhas rotas',
                        onTap: () => _open(
                          context,
                          const MyRoutesScreen(),
                          keepList: true,
                        ),
                      ),
                      FeatureCard(
                        icon: Icons.campaign_outlined,
                        label: 'Avisos',
                        onTap: () =>
                            _open(context, const NotificationsInboxScreen()),
                      ),
                      FeatureCard(
                        icon: Icons.event_available_outlined,
                        label: 'Minhas idas',
                        onTap: () => _open(context, const MyAttendanceScreen()),
                      ),
                      FeatureCard(
                        icon: Icons.report_gmailerrorred_outlined,
                        label: 'Advertências',
                        onTap: () => _open(context, const WarningsScreen()),
                      ),
                    ],
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

class _TodayStatus extends StatelessWidget {
  const _TodayStatus();

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentListProvider>(
      builder: (context, provider, _) {
        final (icon, title, subtitle, color) = switch (provider.state) {
          AsyncLoading() => (
            Icons.hourglass_empty,
            'Carregando...',
            'buscando a lista de hoje',
            AppColors.textSecondary,
          ),
          AsyncError() => (
            Icons.cloud_off,
            'Sem conexão',
            'não deu pra carregar a lista de hoje',
            AppColors.danger,
          ),
          AsyncData(:final value) when value.isEmpty => (
            Icons.event_busy,
            'Sem lista hoje',
            'nenhuma lista aberta para a sua rota',
            AppColors.textSecondary,
          ),
          AsyncData(:final value) when value.any((i) => i.isEnrolled) => (
            Icons.check_circle,
            'Você está na lista',
            value.first.list.routeName,
            AppColors.positiveFg,
          ),
          AsyncData(:final value)
              when value.every((i) => !i.list.acceptsChanges) =>
            (
              Icons.lock_clock,
              'Lista fechada',
              value.first.list.routeName,
              AppColors.textSecondary,
            ),
          AsyncData(:final value) => (
            Icons.info_outline,
            'Você ainda não entrou',
            value.first.list.routeName,
            AppColors.deepTeal,
          ),
        };

        return AppCard(
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
