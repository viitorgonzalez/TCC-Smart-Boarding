import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../services/auth_service.dart';

/// Código e nova senha na mesma tela: o backend valida os dois juntos, então não
/// há estado intermediário pra guardar.
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _service = AuthService();
  bool _loading = false;
  bool _obscureSenha = true;
  bool _obscureConfirma = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.resetPassword(
        email: widget.email,
        code: _codeCtrl.text.trim(),
        newPassword: _passCtrl.text,
      );
      if (!mounted) return;
      showSuccessSnackBar(context, 'Senha redefinida. Faça login.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ashGrey,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Redefinir senha',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Escolha uma senha forte que você não tenha utilizado antes.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  key: const Key('reset_code_field'),
                  label: 'Código recebido por e-mail',
                  controller: _codeCtrl,
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().length != 6)
                      ? 'O código tem 6 dígitos'
                      : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  key: const Key('reset_password_field'),
                  label: 'Nova senha',
                  controller: _passCtrl,
                  icon: Icons.lock_outline,
                  obscureText: _obscureSenha,
                  suffix: IconButton(
                    tooltip: _obscureSenha ? 'Mostrar senha' : 'Ocultar senha',
                    icon: Icon(
                      _obscureSenha
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureSenha = !_obscureSenha),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo de 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  key: const Key('reset_confirm_field'),
                  label: 'Confirmar nova senha',
                  controller: _confirmCtrl,
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirma,
                  suffix: IconButton(
                    tooltip: _obscureConfirma
                        ? 'Mostrar senha'
                        : 'Ocultar senha',
                    icon: Icon(
                      _obscureConfirma
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirma = !_obscureConfirma),
                  ),
                  validator: (v) =>
                      (v != _passCtrl.text) ? 'As senhas não conferem' : null,
                ),
                const SizedBox(height: 28),
                LoadingFilledButton(
                  key: const Key('reset_submit_button'),
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Redefinir senha',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
