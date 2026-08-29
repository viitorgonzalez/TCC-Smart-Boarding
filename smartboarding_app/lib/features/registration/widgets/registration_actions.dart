import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../providers/registration_provider.dart';

/// Aprovar e negar aparecem na lista e na tela de detalhe — as duas precisam do
/// mesmo diálogo, da mesma confirmação e do mesmo tratamento de erro.
Future<bool> confirmApprove(BuildContext context, String id) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Aprovar cadastro?'),
      content: const Text('A conta do aluno será criada de fato.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  return _run(
    context,
    () => context.read<RegistrationProvider>().approve(id),
    'Cadastro aprovado',
  );
}

/// O motivo é obrigatório: é ele que vai no e-mail e na tela quando o aluno
/// volta pra corrigir — negar em silêncio deixa o reenvio às cegas.
Future<bool> promptReject(BuildContext context, String id) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (context) => const RejectDialog(),
  );
  if (reason == null || !context.mounted) return false;
  return _run(
    context,
    () => context.read<RegistrationProvider>().reject(id, reason),
    'Cadastro negado',
  );
}

Future<bool> _run(
  BuildContext context,
  Future<void> Function() action,
  String successMessage,
) async {
  try {
    await action();
    if (context.mounted) showSuccessSnackBar(context, successMessage);
    return true;
  } catch (e) {
    if (context.mounted) showErrorSnackBar(context, e.toString());
    return false;
  }
}

class RejectDialog extends StatefulWidget {
  const RejectDialog({super.key});

  @override
  State<RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<RejectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _reasonCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Negar cadastro?'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'O aluno recebe o motivo por e-mail e pode corrigir os dados.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonCtrl,
              autofocus: true,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                hintText: 'Ex.: nome não confere com o documento',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o motivo' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _confirm, child: const Text('Negar')),
      ],
    );
  }
}
