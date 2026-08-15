import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../providers/user_provider.dart';
import 'role_meta.dart';

class CreateUserForm extends StatefulWidget {
  const CreateUserForm({super.key});

  @override
  State<CreateUserForm> createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<CreateUserForm> {
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
      showErrorSnackBar(context, 'Falha ao criar: $e');
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
              items: roleHierarchy
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Row(
                        children: [
                          Icon(metaFor(r).icon, size: 18),
                          const SizedBox(width: 8),
                          Text(metaFor(r).singular),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (r) => setState(() => _role = r ?? 'STUDENT'),
            ),
            const SizedBox(height: 24),
            LoadingFilledButton(
              loading: _saving,
              onPressed: _submit,
              label: 'Criar usuário',
            ),
          ],
        ),
      ),
    );
  }
}
