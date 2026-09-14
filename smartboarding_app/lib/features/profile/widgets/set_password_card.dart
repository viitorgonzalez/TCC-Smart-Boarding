import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../services/profile_service.dart';

/// Criar senha local pra quem entrou pelo Google.
///
/// Só aparece a quem ainda não tem senha: oferecer a todos faria metade tomar
/// 409 do backend, que recusa sobrescrever senha existente de propósito —
/// trocar senha exige provar posse da antiga, e isso é o fluxo de recuperação.
class SetPasswordCard extends StatefulWidget {
  final VoidCallback? onCreated;

  const SetPasswordCard({super.key, this.onCreated});

  @override
  State<SetPasswordCard> createState() => _SetPasswordCardState();
}

class _SetPasswordCardState extends State<SetPasswordCard> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  bool _obscureSenha = true;
  bool _obscureConfirma = true;
  bool _salvando = false;
  bool _aberto = false;

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await _service.setLocalPassword(_senhaCtrl.text);
      if (!mounted) return;
      showSuccessSnackBar(
        context,
        'Senha criada. Agora você entra pelo Google ou por e-mail e senha.',
      );
      widget.onCreated?.call();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.password, color: AppColors.deepTeal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Criar uma senha',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Você entrou pelo Google. Com uma senha, passa a entrar '
                      'também por e-mail.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_aberto) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('profile_open_set_password'),
              onPressed: () => setState(() => _aberto = true),
              child: const Text('Criar senha'),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    key: const Key('set_password_field'),
                    label: 'Nova senha',
                    controller: _senhaCtrl,
                    icon: Icons.lock_outline,
                    obscureText: _obscureSenha,
                    autofocus: true,
                    suffix: IconButton(
                      tooltip: _obscureSenha
                          ? 'Mostrar senha'
                          : 'Ocultar senha',
                      icon: Icon(
                        _obscureSenha
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureSenha = !_obscureSenha),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mínimo de 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: const Key('set_password_confirm_field'),
                    label: 'Confirmar senha',
                    controller: _confirmaCtrl,
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
                        v != _senhaCtrl.text ? 'As senhas não conferem' : null,
                  ),
                  const SizedBox(height: 16),
                  LoadingFilledButton(
                    key: const Key('set_password_submit'),
                    loading: _salvando,
                    onPressed: _salvar,
                    label: 'Salvar senha',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
