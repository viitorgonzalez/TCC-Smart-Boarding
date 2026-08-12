import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/async_builder.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

// ── Hierarquia de cargos (topo → base) e metadados de cada papel ──────────────
// Sem cores por papel: a diferenciação é feita pelo ícone + nome.

const _hierarchy = ['ADMIN', 'DRIVER', 'STUDENT'];

class _RoleMeta {
  final String singular;
  final String plural;
  final IconData icon;
  const _RoleMeta(this.singular, this.plural, this.icon);
}

const _roleMeta = <String, _RoleMeta>{
  'ADMIN': _RoleMeta(
    'Administrador',
    'Administradores',
    Icons.admin_panel_settings,
  ),
  'DRIVER': _RoleMeta('Motorista', 'Motoristas', Icons.directions_bus_filled),
  'STUDENT': _RoleMeta('Aluno', 'Alunos', Icons.school),
};

_RoleMeta _metaFor(String role) =>
    _roleMeta[role] ?? const _RoleMeta('Usuário', 'Usuários', Icons.person);

List<UserModel> _sortedByName(Iterable<UserModel> users) {
  final list = users.toList();
  list.sort(
    (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
  );
  return list;
}

// ── Tela ──────────────────────────────────────────────────────────────────────

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
              _FilterBar(
                users: users,
                selected: _filter,
                onSelected: (r) => setState(() => _filter = r),
              ),
              const Divider(height: 1),
              Expanded(
                child: users.isEmpty
                    ? const Center(child: Text('Nenhum usuário cadastrado'))
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
    final roles = _filter != null ? [_filter!] : _hierarchy;

    final children = <Widget>[];
    for (final role in roles) {
      final group = _sortedByName(users.where((u) => u.role == role));
      if (group.isEmpty) continue;
      children.add(_SectionHeader(role: role, count: group.length));
      for (final user in group) {
        children.add(_UserTile(user: user));
      }
    }

    if (children.isEmpty) {
      return const Center(child: Text('Nenhum usuário neste filtro'));
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
        child: const _CreateUserForm(),
      ),
    );
  }
}

// ── Barra de filtro por papel ─────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final List<UserModel> users;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _FilterBar({
    required this.users,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    int countOf(String role) => users.where((u) => u.role == role).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          FilterChip(
            label: Text('Todos (${users.length})'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final role in _hierarchy) ...[
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(_metaFor(role).icon, size: 18),
              label: Text('${_metaFor(role).plural} (${countOf(role)})'),
              selected: selected == role,
              onSelected: (_) => onSelected(role),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Cabeçalho de seção (um por papel), na ordem da hierarquia ─────────────────

class _SectionHeader extends StatelessWidget {
  final String role;
  final int count;
  const _SectionHeader({required this.role, required this.count});

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(role);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(meta.icon, color: cs.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            meta.plural,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const Expanded(child: Divider(indent: 12)),
        ],
      ),
    );
  }
}

// ── Tile de usuário ───────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(user.role);
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.surfaceContainerHighest,
          child: Icon(meta.icon, color: cs.onSurfaceVariant, size: 20),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            meta.singular,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Formulário de criação ─────────────────────────────────────────────────────

class _CreateUserForm extends StatefulWidget {
  const _CreateUserForm();

  @override
  State<_CreateUserForm> createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<_CreateUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'STUDENT';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<UserProvider>().create(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        role: _role,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário criado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao criar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Novo usuário', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Papel'),
              items: _hierarchy
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Row(
                        children: [
                          Icon(_metaFor(r).icon, size: 18),
                          const SizedBox(width: 8),
                          Text(_metaFor(r).singular),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (r) => setState(() => _role = r ?? 'STUDENT'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Criar usuário'),
            ),
          ],
        ),
      ),
    );
  }
}
