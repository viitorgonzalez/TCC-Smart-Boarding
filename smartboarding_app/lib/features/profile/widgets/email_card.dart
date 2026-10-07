import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../services/profile_service.dart';

class EmailCard extends StatefulWidget {
  final String currentEmail;
  final VoidCallback onChanged;

  const EmailCard({
    super.key,
    required this.currentEmail,
    required this.onChanged,
  });

  @override
  State<EmailCard> createState() => _EmailCardState();
}

class _EmailCardState extends State<EmailCard> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _aberto = false;
  bool _codigoEnviado = false;
  bool _enviando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pedirCodigo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await _service.requestEmailChange(_emailCtrl.text.trim());
      if (!mounted) return;
      showSuccessSnackBar(context, 'Código enviado pro novo e-mail');
      setState(() => _codigoEnviado = true);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _confirmar() async {
    if (_codeCtrl.text.trim().length != 6) {
      showErrorSnackBar(context, 'O código tem 6 dígitos');
      return;
    }
    setState(() => _enviando = true);
    try {
      await _service.confirmEmailChange(_codeCtrl.text.trim());
      if (!mounted) return;
      widget.onChanged();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _cancelar() {
    setState(() {
      _aberto = false;
      _codigoEnviado = false;
      _emailCtrl.clear();
      _codeCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.alternate_email, color: AppColors.deepTeal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alterar e-mail',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Atual: ${widget.currentEmail}',
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
              key: const Key('profile_open_email_form'),
              onPressed: () => setState(() => _aberto = true),
              child: const Text('Alterar e-mail'),
            ),
          ] else if (!_codigoEnviado) ...[
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    key: const Key('email_new_field'),
                    label: 'Novo e-mail',
                    controller: _emailCtrl,
                    icon: Icons.alternate_email,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Informe um e-mail válido'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _enviando ? null : _cancelar,
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LoadingFilledButton(
                          key: const Key('email_send_code'),
                          loading: _enviando,
                          onPressed: _pedirCodigo,
                          label: 'Enviar código',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              'Enviamos um código de 6 dígitos pra ${_emailCtrl.text.trim()}. '
              'Ao confirmar, sua sessão atual é encerrada e você entra de novo '
              'com o e-mail novo.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AppTextField(
              key: const Key('email_code_field'),
              label: 'Código recebido por e-mail',
              controller: _codeCtrl,
              icon: Icons.pin_outlined,
              autofocus: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _enviando ? null : _cancelar,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LoadingFilledButton(
                    key: const Key('email_confirm_code'),
                    loading: _enviando,
                    onPressed: _confirmar,
                    label: 'Confirmar',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
