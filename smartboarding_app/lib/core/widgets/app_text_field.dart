import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Diz ao gerenciador de senhas do aparelho o que este campo guarda. Sem
  /// isso ele nao oferece preencher, e a pessoa digita e-mail e senha na mao em
  /// todo login.
  final List<String>? autofillHints;

  /// Tecla de acao do teclado: `next` pula pro proximo campo, `done` fecha e
  /// envia. Sem definir, o teclado mostra "return" e nao navega -- num
  /// formulario de quatro campos isso e um toque a mais por campo.
  final TextInputAction? textInputAction;

  /// Formata enquanto se digita (mascara de CEP, telefone). Sem isso o campo
  /// mostra 35570000 enquanto todo mundo le CEP como 35570-000.
  final List<TextInputFormatter>? inputFormatters;

  /// Deixa outra tela mandar o foco pra ca. E o que permite ao CEP, depois de
  /// preencher rua e bairro sozinho, pular direto pro unico campo que sobrou.
  final FocusNode? focusNode;

  /// Chamado quando a tecla de acao e apertada. E o que faz o `done` enviar o
  /// formulario em vez de so fechar o teclado.
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
            // O contador "0/9" embaixo do campo so faz sentido onde o limite
            // e a informacao (uma bio, um motivo). Em CEP e UF ele e ruido:
            // o formato ja diz quanto cabe.
            counterText: maxLength == null ? null : '',
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
