import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../models/address_model.dart';
import '../services/cep_service.dart';
import '../services/profile_service.dart';

/// Endereço do aluno, preenchido pelo CEP.
///
/// Card próprio, com botão de salvar próprio, porque o endereço vai direto pro
/// backend enquanto nome ainda passa pela fila do admin. Dois botões com
/// semânticas diferentes no mesmo formulário confundiriam: a pessoa não saberia
/// o que já valeu e o que foi só pedido.
class AddressCard extends StatefulWidget {
  final Address initial;
  final VoidCallback? onSaved;

  /// Injetáveis pro teste; em produção cada um constrói o seu.
  final CepService? cepService;
  final ProfileService? profileService;

  const AddressCard({
    super.key,
    required this.initial,
    this.onSaved,
    this.cepService,
    this.profileService,
  });

  @override
  State<AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<AddressCard> {
  static const _digitosDoCep = 8;

  late final CepService _cep = widget.cepService ?? CepService();
  late final ProfileService _profile = widget.profileService ?? ProfileService();

  final _cepCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _ufCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _numeroFocus = FocusNode();

  bool _buscando = false;
  bool _salvando = false;

  /// Evita repetir a consulta do mesmo CEP a cada rebuild do campo.
  String? _ultimoConsultado;

  @override
  void initState() {
    super.initState();
    _cepCtrl.text = widget.initial.zipCode ?? '';
    _ruaCtrl.text = widget.initial.street ?? '';
    _bairroCtrl.text = widget.initial.neighborhood ?? '';
    _cidadeCtrl.text = widget.initial.city ?? '';
    _ufCtrl.text = widget.initial.state ?? '';
    _numeroCtrl.text = widget.initial.streetNumber ?? '';
    _complementoCtrl.text = widget.initial.complement ?? '';
    _ultimoConsultado = _soDigitos(_cepCtrl.text);
    _cepCtrl.addListener(_aoDigitarCep);
  }

  @override
  void dispose() {
    _cepCtrl.removeListener(_aoDigitarCep);
    for (final c in [
      _cepCtrl,
      _ruaCtrl,
      _bairroCtrl,
      _cidadeCtrl,
      _ufCtrl,
      _numeroCtrl,
      _complementoCtrl,
    ]) {
      c.dispose();
    }
    _numeroFocus.dispose();
    super.dispose();
  }

  static String _soDigitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  Future<void> _aoDigitarCep() async {
    final digitos = _soDigitos(_cepCtrl.text);
    if (digitos.length != _digitosDoCep || digitos == _ultimoConsultado) return;
    _ultimoConsultado = digitos;

    setState(() => _buscando = true);
    final achado = await _cep.lookup(digitos);
    if (!mounted) return;
    setState(() => _buscando = false);

    // Nulo é "não sei": os campos ficam como estão pra pessoa digitar. Limpar
    // aqui apagaria o que ela já tinha escrito à mão.
    if (achado == null) return;

    setState(() {
      _ruaCtrl.text = achado.street ?? _ruaCtrl.text;
      _bairroCtrl.text = achado.neighborhood ?? _bairroCtrl.text;
      _cidadeCtrl.text = achado.city ?? _cidadeCtrl.text;
      _ufCtrl.text = achado.state ?? _ufCtrl.text;
    });
    // O número é o único que o CEP não sabe, então é pra lá que o foco vai.
    _numeroFocus.requestFocus();
  }

  Address get _montado => Address(
    zipCode: _texto(_cepCtrl),
    street: _texto(_ruaCtrl),
    neighborhood: _texto(_bairroCtrl),
    city: _texto(_cidadeCtrl),
    state: _texto(_ufCtrl),
    streetNumber: _texto(_numeroCtrl),
    complement: _texto(_complementoCtrl),
  );

  static String? _texto(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await _profile.updateAddress(_montado);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Endereço salvo');
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final faltando = _montado.faltando;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Endereço',
                style: Theme.of(context).textTheme.titleSmall,
              ),
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
            controller: _cepCtrl,
            icon: Icons.markunread_mailbox_outlined,
            hint: '00000-000',
            keyboardType: TextInputType.number,
            maxLength: 9,
            inputFormatters: [_CepFormatter()],
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: const Key('address_street_field'),
            label: 'Rua',
            controller: _ruaCtrl,
            icon: Icons.place_outlined,
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: const Key('address_neighborhood_field'),
            label: 'Bairro',
            controller: _bairroCtrl,
            icon: Icons.holiday_village_outlined,
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
                  controller: _cidadeCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  key: const Key('address_state_field'),
                  label: 'UF',
                  controller: _ufCtrl,
                  maxLength: 2,
                  textCapitalization: TextCapitalization.characters,
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
                  controller: _numeroCtrl,
                  focusNode: _numeroFocus,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppTextField(
                  key: const Key('address_complement_field'),
                  label: 'Complemento',
                  controller: _complementoCtrl,
                  hint: 'Opcional',
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

          const SizedBox(height: 16),
          LoadingFilledButton(
            key: const Key('address_save_button'),
            loading: _salvando,
            onPressed: _salvar,
            label: 'Salvar endereço',
          ),
        ],
      ),
    );
  }
}

/// Põe o hífen enquanto se digita. O teclado numérico não tem um, e sem isso o
/// campo mostra 35570000 enquanto todo mundo lê CEP como 35570-000.
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
