import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/async_value.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../providers/registration_provider.dart';

class RegisterScreen extends StatefulWidget {
  final String token;
  const RegisterScreen({super.key, required this.token});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _selectedInstitutionId;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationProvider>().loadInstitutions();
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedInstitutionId == null) return;
    final provider = context.read<RegistrationProvider>();
    await provider.submit(
      token: widget.token,
      fullName: _fullNameCtrl.text.trim(),
      password: _passwordCtrl.text,
      institutionId: _selectedInstitutionId!,
    );
    if (!mounted) return;
    if (provider.submitState is AsyncData) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Cadastro enviado, aguardando aprovação do administrador',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Seu convite')),
      body: SafeArea(
        child: Consumer<RegistrationProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _fullNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nome completo', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    ),
                    const SizedBox(height: 16),
                    switch (provider.institutions) {
                      AsyncData(:final value) => DropdownButtonFormField<String>(
                          initialValue: _selectedInstitutionId,
                          decoration: const InputDecoration(labelText: 'Instituição', border: OutlineInputBorder()),
                          items: value
                              .map((i) => DropdownMenuItem(value: i.id, child: Text(i.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedInstitutionId = v),
                          validator: (v) => v == null ? 'Selecione a instituição' : null,
                        ),
                      _ => const Center(child: CircularProgressIndicator()),
                    },
                    const SizedBox(height: 24),
                    LoadingFilledButton(
                      loading: provider.submitState is AsyncLoading,
                      onPressed: _submit,
                      label: 'Enviar cadastro',
                    ),
                    if (provider.submitState case AsyncError(:final message))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(message, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
