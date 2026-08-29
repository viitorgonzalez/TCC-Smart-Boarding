import 'package:flutter/material.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../registration/services/registration_service.dart';

// ─── Diálogo de gerar convite (aba Cadastros) ────────────────────────────────

class GenerateInviteDialog extends StatefulWidget {
  const GenerateInviteDialog({super.key});

  @override
  State<GenerateInviteDialog> createState() => GenerateInviteDialogState();
}

class GenerateInviteDialogState extends State<GenerateInviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _service = RegistrationService();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.generateInvite(_emailCtrl.text.trim());
      if (mounted) {
        showSuccessSnackBar(context, 'Convite enviado');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Falha ao gerar convite: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerar convite'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'E-mail'),
          keyboardType: TextInputType.emailAddress,
          validator: (v) =>
              (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        LoadingFilledButton(
          loading: _loading,
          onPressed: _submit,
          label: 'Gerar convite',
        ),
      ],
    );
  }
}
