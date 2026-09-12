import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrarComGoogle() async {
    setState(() => _loading = true);
    try {
      // false = o usuario fechou a escolha de conta. Nao e erro: mostrar
      // mensagem vermelha por desistencia irrita sem informar nada.
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Falha no login: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // As telas de autenticação são as únicas sobre Ash Grey no desenho; o resto
    // do app é #F4F6F4 (ver design-system.md).
    return Scaffold(
      backgroundColor: AppColors.ashGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A logo ja carrega o wordmark: repetir "Smart Boarding" em
                // texto logo abaixo duplicaria o nome na mesma dobra.
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    // Limitado pela largura da tela, nao por um numero fixo:
                    // em aparelho estreito um valor cravado estoura a margem.
                    width: MediaQuery.sizeOf(context).width * 0.72,
                    semanticLabel: 'Smart Boarding',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bem-vindo de volta! Entre para conferir seu transporte.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  key: const Key('login_email_field'),
                  autofocus: true,
                  label: 'Email',
                  controller: _emailCtrl,
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'E-mail inválido'
                      : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  key: const Key('login_password_field'),
                  label: 'Senha',
                  controller: _passCtrl,
                  icon: Icons.lock_outline,
                  obscureText: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe a senha' : null,
                ),
                const SizedBox(height: 28),
                LoadingFilledButton(
                  key: const Key('login_submit_button'),
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Entrar',
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  child: const Text(
                    'Criar conta',
                    style: TextStyle(
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    key: const Key('login_google_button'),
                    onPressed: _loading ? null : _entrarComGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Entrar com Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.charcoal,
                      side: const BorderSide(color: AppColors.stroke),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('login_forgot_password'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text(
                    'Esqueci minha senha',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
