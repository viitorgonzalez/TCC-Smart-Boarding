import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../providers/registration_provider.dart';
import '../services/institution_service.dart';
import '../services/registration_service.dart';
import 'register_screen.dart';

// Entrada pública do fluxo de cadastro por convite: o e-mail manda um código
// de 6 dígitos (não um link) porque o App Link https:// exige domínio
// publicado+verificado (pendência de deploy, ver spec) — código funciona sem
// nenhuma dependência de domínio, em dev e produção, desde já.
class VerifyInviteCodeScreen extends StatefulWidget {
  const VerifyInviteCodeScreen({super.key});

  @override
  State<VerifyInviteCodeScreen> createState() => _VerifyInviteCodeScreenState();
}

class _VerifyInviteCodeScreenState extends State<VerifyInviteCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _service = RegistrationService();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = await _service.verifyCode(_emailCtrl.text.trim(), _codeCtrl.text.trim());
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => RegistrationProvider(RegistrationService(), InstitutionService()),
            child: RegisterScreen(token: token),
          ),
        ),
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Código inválido: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tenho um convite')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Digite o e-mail e o código de 6 dígitos que você recebeu no convite.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(labelText: 'Código', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) => (v == null || v.length != 6) ? 'Informe os 6 dígitos' : null,
                ),
                const SizedBox(height: 8),
                LoadingFilledButton(
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Continuar',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
