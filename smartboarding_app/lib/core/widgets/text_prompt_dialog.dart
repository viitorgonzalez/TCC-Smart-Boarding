import 'package:flutter/material.dart';

/// Pergunta um texto curto. Devolve nulo se o usuário cancelar ou deixar em
/// branco — quem chama não precisa distinguir os dois casos.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String hint,
  String? helper,
  String confirmLabel = 'Adicionar',
}) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint, helperText: helper),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  final text = controller.text.trim();
  return (ok == true && text.isNotEmpty) ? text : null;
}
