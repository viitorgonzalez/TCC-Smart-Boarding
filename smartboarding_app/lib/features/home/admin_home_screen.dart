import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/async_builder.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entity_list_tile.dart';
import '../../core/widgets/status_pill.dart';
import '../lists/models/daily_list_model.dart';
import '../lists/providers/admin_list_provider.dart';
import '../lists/screens/admin_list_entries_screen.dart';
import '../notifications/providers/notification_provider.dart';
import '../notifications/screens/broadcast_screen.dart';
import '../notifications/services/notification_service.dart';
import '../registration/providers/registration_provider.dart';
import '../registration/screens/registration_approvals_screen.dart';
import '../registration/services/institution_service.dart';
import '../registration/services/registration_service.dart';
import 'widgets/create_institution_dialog.dart';
import 'widgets/generate_invite_dialog.dart';
import '../reports/providers/report_provider.dart';
import '../reports/screens/reports_screen.dart';
import '../reports/services/report_service.dart';
import '../routes/providers/route_provider.dart';
import '../routes/screens/routes_screen.dart';
import '../routes/services/route_service.dart';
import '../lists/services/list_service.dart';
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
          create: (_) => AdminListProvider(ListService())..load(),
        ),
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
      ],
      child: const _AdminShell(),
    );
  }
}

// ─── Shell do admin com NavigationBar ────────────────────────────────────────

class _AdminShell extends StatefulWidget {
  const _AdminShell();

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Boarding'),
        actions: [
          if (_index == 1)
            IconButton(
              icon: const Icon(Icons.school_outlined),
              tooltip: 'Nova instituição',
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const CreateInstitutionDialog(),
              ),
            ),
          if (_index == 5)
            IconButton(
              icon: const Icon(Icons.person_add_alt_outlined),
              tooltip: 'Gerar convite',
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const GenerateInviteDialog(),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _AdminListsTab(),
          RoutesScreen(),
          ReportsScreen(),
          BroadcastScreen(),
          UserManagementScreen(),
          RegistrationApprovalsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Listas',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Rotas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Relatórios',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Broadcast',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Usuários',
          ),
          NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg),
            label: 'Cadastros',
          ),
        ],
      ),
    );
  }
}

// ─── Tab de listas (admin) ────────────────────────────────────────────────────

class _AdminListsTab extends StatelessWidget {
  const _AdminListsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminListProvider>(
      builder: (context, provider, _) => AsyncBuilder(
        value: provider.state,
        onRetry: provider.load,
        builder: (lists) => lists.isEmpty
            ? const EmptyState(
                icon: Icons.event_busy,
                title: 'Nenhuma lista disponível hoje',
              )
            : RefreshIndicator(
                onRefresh: provider.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lists.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _ListTile(list: lists[i]),
                ),
              ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final DailyList list;
  const _ListTile({required this.list});

  @override
  Widget build(BuildContext context) {
    return EntityListTile(
      leading: CircleAvatar(
        backgroundColor: list.isOpen
            ? Colors.green.shade50
            : Colors.grey.shade100,
        child: Icon(
          Icons.people_alt_outlined,
          color: list.isOpen ? Colors.green : Colors.grey,
        ),
      ),
      title: list.routeName,
      subtitle: Text(
        '${list.totalEntries} inscrito(s) · ${formatDate(list.date)}',
      ),
      trailing: StatusPill(
        label: list.isOpen ? 'Aberta' : 'Fechada',
        tone: list.isOpen ? StatusPillTone.positive : StatusPillTone.neutral,
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminListEntriesScreen(list: list)),
      ),
    );
  }
}
