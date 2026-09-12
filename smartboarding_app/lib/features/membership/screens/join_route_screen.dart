import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../providers/membership_provider.dart';

/// Entrar numa rota com o código que o admin distribui.
class JoinRouteScreen extends StatefulWidget {
  const JoinRouteScreen({super.key});

  @override
  State<JoinRouteScreen> createState() => _JoinRouteScreenState();
}

class _JoinRouteScreenState extends State<JoinRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final route = await context.read<MembershipProvider>().join(
        _codeCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnackBar(context, 'Você entrou na ${route.name}');
    } catch (e) {
      // A mensagem vem do backend e distingue expirado de cancelado de
      // inexistente -- o aluno precisa saber se pede codigo novo ou se errou
      // a digitacao.
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar em uma rota')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Peça o código ao administrador da sua rota e digite abaixo.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  key: const Key('join_code_field'),
                  label: 'Código da rota',
                  controller: _codeCtrl,
                  icon: Icons.confirmation_number_outlined,
                  hint: 'Ex.: RU7K2M',
                  maxLength: 16,
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o código'
                      : null,
                ),
                const SizedBox(height: 20),
                LoadingFilledButton(
                  key: const Key('join_submit_button'),
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Entrar na rota',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
