import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/async_builder.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/user_model.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (users) => Column(
            children: [
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
        label: const Text('Novo usuário'),
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
