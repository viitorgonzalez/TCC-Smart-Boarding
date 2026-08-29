import 'package:flutter/material.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../registration/services/institution_service.dart';

// ─── Diálogo de criar instituição (mínimo pro dropdown do cadastro) ──────────

class CreateInstitutionDialog extends StatefulWidget {
  const CreateInstitutionDialog({super.key});

  @override
  State<CreateInstitutionDialog> createState() =>
      CreateInstitutionDialogState();
}

class CreateInstitutionDialogState extends State<CreateInstitutionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _service = InstitutionService();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.createInstitution(
        _nameCtrl.text.trim(),
        _addressCtrl.text.trim(),
        null,
        null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Falha ao criar instituição: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova instituição'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Endereço (opcional)',
              ),
            ),
          ],
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
          label: 'Criar',
        ),
      ],
    );
  }
}
