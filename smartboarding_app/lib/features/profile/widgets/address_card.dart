import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/address_model.dart';
import '../services/cep_service.dart';

class AddressCard extends StatefulWidget {
  final TextEditingController cepCtrl;
  final TextEditingController ruaCtrl;
  final TextEditingController bairroCtrl;
  final TextEditingController cidadeCtrl;
  final TextEditingController ufCtrl;
  final TextEditingController numeroCtrl;
  final TextEditingController complementoCtrl;
  final bool readOnly;

  final CepService? cepService;

  const AddressCard({
    super.key,
    required this.cepCtrl,
    required this.ruaCtrl,
    required this.bairroCtrl,
    required this.cidadeCtrl,
    required this.ufCtrl,
    required this.numeroCtrl,
    required this.complementoCtrl,
    this.readOnly = false,
    this.cepService,
  });

  @override
  State<AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<AddressCard> {
  static const _digitosDoCep = 8;

  late final CepService _cep = widget.cepService ?? CepService();
  final _numeroFocus = FocusNode();

  bool _buscando = false;

  String? _ultimoConsultado;

  void _aoDigitar() => setState(() {});

  @override
  void initState() {
    super.initState();
    _ultimoConsultado = _soDigitos(widget.cepCtrl.text);
    widget.cepCtrl.addListener(_aoDigitarCep);
    for (final c in [
      widget.cepCtrl,
      widget.ruaCtrl,
      widget.bairroCtrl,
      widget.numeroCtrl,
    ]) {
      c.addListener(_aoDigitar);
    }
  }

  @override
  void dispose() {
    widget.cepCtrl.removeListener(_aoDigitarCep);
    for (final c in [
      widget.cepCtrl,
      widget.ruaCtrl,
      widget.bairroCtrl,
      widget.numeroCtrl,
    ]) {
      c.removeListener(_aoDigitar);
    }
    _numeroFocus.dispose();
    super.dispose();
  }

  static String _soDigitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  Future<void> _aoDigitarCep() async {
    final digitos = _soDigitos(widget.cepCtrl.text);
    if (digitos.length != _digitosDoCep || digitos == _ultimoConsultado) return;
    _ultimoConsultado = digitos;

    setState(() => _buscando = true);
    final achado = await _cep.lookup(digitos);
    if (!mounted) return;
    setState(() => _buscando = false);

    if (achado == null) return;

    setState(() {
      widget.ruaCtrl.text = achado.street ?? widget.ruaCtrl.text;
      widget.bairroCtrl.text = achado.neighborhood ?? widget.bairroCtrl.text;
      widget.cidadeCtrl.text = achado.city ?? widget.cidadeCtrl.text;
      widget.ufCtrl.text = achado.state ?? widget.ufCtrl.text;
    });
    _numeroFocus.requestFocus();
  }

  static String? _texto(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    final montado = Address(
      zipCode: _texto(widget.cepCtrl),
      street: _texto(widget.ruaCtrl),
      neighborhood: _texto(widget.bairroCtrl),
      city: _texto(widget.cidadeCtrl),
      state: _texto(widget.ufCtrl),
      streetNumber: _texto(widget.numeroCtrl),
      complement: _texto(widget.complementoCtrl),
    );
    final faltando = montado.faltando;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Endereço', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (_buscando)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'É por ele que o motorista sabe onde você embarca.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          AppTextField(
            key: const Key('address_zip_field'),
            label: 'CEP',
            controller: widget.cepCtrl,
            icon: Icons.markunread_mailbox_outlined,
            hint: '00000-000',
            keyboardType: TextInputType.number,
            maxLength: 9,
            inputFormatters: [_CepFormatter()],
            readOnly: widget.readOnly,
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: const Key('address_street_field'),
            label: 'Rua',
            controller: widget.ruaCtrl,
            icon: Icons.place_outlined,
            readOnly: widget.readOnly,
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: const Key('address_neighborhood_field'),
            label: 'Bairro',
            controller: widget.bairroCtrl,
            icon: Icons.holiday_village_outlined,
            readOnly: widget.readOnly,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  key: const Key('address_city_field'),
                  label: 'Cidade',
                  controller: widget.cidadeCtrl,
                  readOnly: widget.readOnly,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  key: const Key('address_state_field'),
                  label: 'UF',
                  controller: widget.ufCtrl,
                  maxLength: 2,
                  textCapitalization: TextCapitalization.characters,
                  readOnly: widget.readOnly,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  key: const Key('address_number_field'),
                  label: 'Número',
                  controller: widget.numeroCtrl,
                  focusNode: _numeroFocus,
                  keyboardType: TextInputType.number,
                  readOnly: widget.readOnly,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppTextField(
                  key: const Key('address_complement_field'),
                  label: 'Complemento',
                  controller: widget.complementoCtrl,
                  hint: 'Opcional',
                  readOnly: widget.readOnly,
                ),
              ),
            ],
          ),

          if (faltando.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              key: const Key('address_missing_warning'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Falta preencher: ${faltando.join(', ')}. '
                    'Sem isso você não consegue entrar na lista.',
                    style: const TextStyle(color: AppColors.danger),
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

class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue novo,
  ) {
    final digitos = novo.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final texto = limitado.length > 5
        ? '${limitado.substring(0, 5)}-${limitado.substring(5)}'
        : limitado;
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
