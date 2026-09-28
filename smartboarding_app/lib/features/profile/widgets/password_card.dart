import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../services/profile_service.dart';

/// Senha local da conta, nos dois casos que existem.
///
/// Com [changing] falso é a criação da primeira senha, de quem entrou pelo
/// Google — não há senha antiga pra provar. Com [changing] verdadeiro é a
/// troca, e aí a senha atual é obrigatória: sem ela, quem pegasse o celular
/// desbloqueado trocaria a senha e tomaria a conta.
class PasswordCard extends StatefulWidget {
  /// A conta já tem senha: o caso é trocar, não criar.
  final bool changing;
  final VoidCallback? onSaved;

  const PasswordCard({super.key, required this.changing, this.onSaved});

  @override
  State<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _atualCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  bool _obscureAtual = true;
  bool _obscureSenha = true;
  bool _obscureConfirma = true;
  bool _salvando = false;
  bool _aberto = false;

  @override
  void dispose() {
    _atualCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      if (widget.changing) {
        await _service.changePassword(_atualCtrl.text, _senhaCtrl.text);
      } else {
        await _service.setLocalPassword(_senhaCtrl.text);
      }
      if (!mounted) return;
      showSuccessSnackBar(
        context,
        widget.changing
            ? 'Senha alterada.'
            : 'Senha criada. Agora você entra pelo Google ou por e-mail e senha.',
      );
      // Limpa os campos: deixar a senha digitada na tela depois de salva é
      // expô-la a quem olhar o aparelho por cima do ombro.
      _atualCtrl.clear();
      _senhaCtrl.clear();
      _confirmaCtrl.clear();
      setState(() => _aberto = false);
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _olho(bool escondido, VoidCallback alternar) => IconButton(
    tooltip: escondido ? 'Mostrar senha' : 'Ocultar senha',
    icon: Icon(
      escondido ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    ),
    onPressed: alternar,
  );

  @override
  Widget build(BuildContext context) {
    final trocando = widget.changing;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.password_outlined, color: AppColors.deepTeal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trocando ? 'Alterar senha' : 'Criar uma senha',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trocando
                          ? 'Para trocar, confirme a senha que você usa hoje.'
                          : 'Você entrou pelo Google. Com uma senha, passa a '
                                'entrar também por e-mail.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_aberto) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('profile_open_password_form'),
              onPressed: () => setState(() => _aberto = true),
              child: Text(trocando ? 'Alterar senha' : 'Criar senha'),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (trocando) ...[
                    AppTextField(
                      key: const Key('password_current_field'),
                      label: 'Senha atual',
                      controller: _atualCtrl,
                      icon: Icons.lock_outline,
                      obscureText: _obscureAtual,
                      autofocus: true,
                      suffix: _olho(
                        _obscureAtual,
                        () => setState(() => _obscureAtual = !_obscureAtual),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Informe sua senha atual'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppTextField(
                    key: const Key('password_new_field'),
                    label: 'Nova senha',
                    controller: _senhaCtrl,
                    icon: Icons.lock_outline,
                    obscureText: _obscureSenha,
                    autofocus: !trocando,
                    suffix: _olho(
                      _obscureSenha,
                      () => setState(() => _obscureSenha = !_obscureSenha),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mínimo de 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: const Key('password_confirm_field'),
                    label: 'Confirmar senha',
                    controller: _confirmaCtrl,
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirma,
                    suffix: _olho(
                      _obscureConfirma,
                      () =>
                          setState(() => _obscureConfirma = !_obscureConfirma),
                    ),
                    validator: (v) =>
                        v != _senhaCtrl.text ? 'As senhas não conferem' : null,
                  ),
                  const SizedBox(height: 16),
                  LoadingFilledButton(
                    key: const Key('password_submit'),
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
