import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

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

  final TextCapitalization textCapitalization;

  final bool autofocus;

  final List<String>? autofillHints;

  final TextInputAction? textInputAction;

  final List<TextInputFormatter>? inputFormatters;

  final FocusNode? focusNode;

  final VoidCallback? onSubmitted;

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
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
    this.focusNode,
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
          focusNode: focusNode,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          textCapitalization: textCapitalization,
          autofocus: autofocus,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
          decoration: InputDecoration(
            counterText: maxLength == null ? null : '',
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(icon),
            suffixIcon: suffix,
            fillColor: readOnly ? AppColors.background : AppColors.surface,
          ),
        ),
      ],
    );
  }
}
