import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/async_builder.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

const _roles = ['STUDENT', 'DRIVER', 'ADMIN'];
const _roleLabels = {
  'STUDENT': 'Aluno',
  'DRIVER': 'Motorista',
  'ADMIN': 'Admin',
};

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (users) => users.isEmpty
              ? const Center(child: Text('Nenhum usuário cadastrado'))
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _UserTile(user: users[i]),
                  ),
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

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(user.fullName.characters.first)),
        title: Text(user.fullName),
        subtitle: Text(user.email),
        trailing: Chip(label: Text(_roleLabels[user.role] ?? user.role)),
      ),
    );
  }
}

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
            Text('Novo usuário',
                style: Theme.of(context).textTheme.titleLarge),
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
              items: _roles
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(_roleLabels[r]!),
                      ))
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
