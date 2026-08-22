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
  final _emailCtrl = TextEditingController();
  String? _selectedInstitutionId;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RegistrationProvider>();
      provider.validateInvite(widget.token).then((_) {
        if (!mounted) return;
        if (provider.inviteEmail case AsyncData(:final value)) {
          _emailCtrl.text = value;
          provider.loadInstitutions();
        }
      });
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
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

  Widget _messageScreen({
    required IconData icon,
    required Color color,
    required String text,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: color),
                const SizedBox(height: 16),
                Text(text, textAlign: TextAlign.center),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 24),
                  FilledButton(onPressed: onAction, child: Text(actionLabel)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tela pushada por cima de tudo (deep-link ou "tenho um convite") -- sem
  // isso o usuário fica preso aqui, sem AppBar/back nem rota anterior óbvia
  // pra onde voltar depois de terminar o fluxo.
  void _backToLogin() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _messageScreen(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        text: 'Cadastro enviado, aguardando aprovação do administrador',
        actionLabel: 'Voltar para o login',
        onAction: _backToLogin,
      );
    }

    if (context.watch<RegistrationProvider>().inviteEmail case AsyncError(
      :final message,
    )) {
      return _messageScreen(
        icon: Icons.error_outline,
        color: Colors.red,
        text: message,
        actionLabel: 'Voltar',
        onAction: _backToLogin,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Seu convite')),
      body: SafeArea(
        child: Consumer<RegistrationProvider>(
          builder: (context, provider, _) {
            return switch (provider.inviteEmail) {
              AsyncLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              AsyncError(:final message) => _messageScreen(
                icon: Icons.error_outline,
                color: Colors.red,
                text: message,
              ),
              AsyncData() => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe a senha';
                          if (v.length < 6) {
                            return 'Senha deve ter no mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      switch (provider.institutions) {
                        AsyncData(:final value) =>
                          DropdownButtonFormField<String>(
                            initialValue: _selectedInstitutionId,
                            decoration: const InputDecoration(
                              labelText: 'Instituição',
                              border: OutlineInputBorder(),
                            ),
                            items: value
                                .map(
                                  (i) => DropdownMenuItem(
                                    value: i.id,
                                    child: Text(i.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedInstitutionId = v),
                            validator: (v) =>
                                v == null ? 'Selecione a instituição' : null,
                          ),
                        AsyncError(:final message) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              message,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context
                                  .read<RegistrationProvider>()
                                  .loadInstitutions(),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
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
                          child: Text(
                            message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            };
          },
        ),
      ),
    );
  }
}
