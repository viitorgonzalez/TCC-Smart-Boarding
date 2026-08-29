import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/async_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/user_model.dart';
import '../../routes/models/route_model.dart';
import '../../routes/providers/route_provider.dart';
import '../../../core/utils/async_value.dart';
import '../providers/user_provider.dart';
import '../widgets/create_user_form.dart';
import '../widgets/role_meta.dart';
import '../widgets/user_filter_bar.dart';
import '../widgets/user_section_header.dart';
import '../widgets/user_tile.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String? _filter; // null = todos; senão o papel filtrado.

  @override
  void initState() {
    super.initState();
    // Abre escopado na rota: a base de usuários cresce sem teto e o admin
    // trabalha por rota. "Todas as rotas" continua a um toque.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routes = switch (context.read<RouteProvider>().state) {
        AsyncData(:final value) => value.where((r) => r.isActive).toList(),
        _ => const <RouteModel>[],
      };
      if (routes.isNotEmpty && mounted) {
        final provider = context.read<UserProvider>();
        provider.routeId = routes.first.id;
        provider.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (users) => Column(
            children: [
              _RouteScope(
                selected: provider.routeId,
                onSelected: (id) {
                  provider.routeId = id;
                  provider.load();
                },
              ),
              UserFilterBar(
                users: users,
                selected: _filter,
                onSelected: (r) => setState(() => _filter = r),
              ),
              const Divider(height: 1),
              Expanded(
                child: users.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline,
                        title: 'Nenhum usuário cadastrado',
                      )
                    : RefreshIndicator(
                        onRefresh: provider.load,
                        child: _buildList(users),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateForm(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo admin'),
      ),
    );
  }

  Widget _buildList(List<UserModel> users) {
    final roles = _filter != null ? [_filter!] : roleHierarchy;

    final children = <Widget>[];
    for (final role in roles) {
      final group = sortUsersByName(users.where((u) => u.role == role));
      if (group.isEmpty) continue;
      children.add(UserSectionHeader(role: role, count: group.length));
      for (final user in group) {
        children.add(UserTile(user: user));
      }
    }

    if (children.isEmpty) {
      return const EmptyState(
        icon: Icons.filter_alt_off,
        title: 'Nenhum usuário neste filtro',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: children,
    );
  }

  void _openCreateForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<UserProvider>(),
        child: const CreateUserForm(),
      ),
    );
  }
}

/// Escopo da listagem. O padrão é a rota — ver o sistema inteiro é a exceção,
/// não o ponto de partida.
class _RouteScope extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _RouteScope({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final routes = switch (context.watch<RouteProvider>().state) {
      AsyncData(:final value) => value.where((r) => r.isActive).toList(),
      _ => const <RouteModel>[],
    };
    if (routes.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final route in routes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(route.name),
                selected: selected == route.id,
                showCheckmark: false,
                onSelected: (_) => onSelected(route.id),
              ),
            ),
          ChoiceChip(
            label: const Text('Todas as rotas'),
            selected: selected == null,
            showCheckmark: false,
            onSelected: (_) => onSelected(null),
          ),
        ],
      ),
    );
  }
}
