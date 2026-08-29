import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Confirmação com motivo obrigatório. Toda mudança que quebra o combinado com
/// quem depende do transporte passa por aqui — o texto vira o aviso enviado.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String hint,
  required String confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(
      title: title,
      message: message,
      hint: hint,
      confirmLabel: confirmLabel,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  final String title;
  final String message;
  final String hint;
  final String confirmLabel;

  const _ReasonDialog({
    required this.title,
    required this.message,
    required this.hint,
    required this.confirmLabel,
  });

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Motivo',
                hintText: widget.hint,
              ),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Explique em poucas palavras'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _ctrl.text.trim());
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
