import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Rótulo fica **acima** da caixa, não flutuante como o padrão do Material.
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final String? hint;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  /// Campo de codigo entra em caixa alta sozinho: o codigo e normalizado no
  /// backend de qualquer jeito, mas ver o que se digita igual ao que esta no
  /// quadro evita a duvida de "sera que precisa ser maiuscula?".
  final TextCapitalization textCapitalization;

  /// Primeiro campo do formulario abre com o teclado pronto: sem isso o usuario
  /// precisa de um toque a mais so pra comecar a digitar.
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.suffix,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          textCapitalization: textCapitalization,
          autofocus: autofocus,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(icon),
            suffixIcon: suffix,
            // O readOnly do desenho (e-mail do convite) fica acinzentado pra
            // não parecer editável.
            fillColor: readOnly ? AppColors.background : AppColors.surface,
          ),
        ),
      ],
    );
  }
}
