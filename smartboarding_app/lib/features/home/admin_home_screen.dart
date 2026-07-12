import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/async_builder.dart';
import '../lists/models/daily_list_model.dart';
import '../lists/providers/admin_list_provider.dart';
import '../lists/screens/admin_list_entries_screen.dart';
import '../notifications/providers/notification_provider.dart';
import '../notifications/screens/broadcast_screen.dart';
import '../notifications/services/notification_service.dart';
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
            create: (_) => AdminListProvider(ListService())..load()),
        ChangeNotifierProvider(
            create: (_) => RouteProvider(RouteService())..load()),
        ChangeNotifierProvider(
            create: (_) => ReportProvider(ReportService())..load()),
        ChangeNotifierProvider(
            create: (_) => NotificationProvider(NotificationService())),
        ChangeNotifierProvider(
            create: (_) => UserProvider(UserService())..load()),
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
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Listas'),
          NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Rotas'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Relatórios'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Broadcast'),
          NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Usuários'),
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
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: provider.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lists.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: list.isOpen
              ? Colors.green.shade50
              : Colors.grey.shade100,
          child: Icon(Icons.people_alt_outlined,
              color: list.isOpen ? Colors.green : Colors.grey),
        ),
        title: Text(list.routeName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${list.totalEntries} inscrito(s) · ${list.date}'),
        trailing: _StatusChip(isOpen: list.isOpen),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminListEntriesScreen(list: list),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isOpen;
  const _StatusChip({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        isOpen ? 'Aberta' : 'Fechada',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isOpen ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Nenhuma lista disponível hoje',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
}
