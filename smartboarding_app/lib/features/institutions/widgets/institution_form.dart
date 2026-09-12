import 'package:flutter/material.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/institution_model.dart';

/// Formulário de instituição. Devolve nome e endereço, ou nulo se cancelar.
/// Endereço vazio vira null em vez de string vazia — "" no banco aparece como
/// campo em branco na tela e não se distingue de "não informado".
Future<({String name, String? address})?> showInstitutionForm(
  BuildContext context, {
  InstitutionModel? existente,
}) async {
  final nameCtrl = TextEditingController(text: existente?.name ?? '');
  final addressCtrl = TextEditingController(text: existente?.address ?? '');
  final formKey = GlobalKey<FormState>();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        existente == null ? 'Nova instituição' : 'Editar instituição',
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              key: const Key('institution_name_field'),
              label: 'Nome',
              controller: nameCtrl,
              icon: Icons.school_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              key: const Key('institution_address_field'),
              label: 'Endereço',
              controller: addressCtrl,
              icon: Icons.place_outlined,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('institution_save_button'),
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );

  if (ok != true) return null;
  final endereco = addressCtrl.text.trim();
  return (
    name: nameCtrl.text.trim(),
    address: endereco.isEmpty ? null : endereco,
  );
}
