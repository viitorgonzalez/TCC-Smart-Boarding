import 'package:flutter/material.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../services/profile_service.dart';

/// Telefone e curso — o que o aluno muda sozinho.
///
/// Fora da fila de aprovação porque nenhum dos dois decide em qual transporte
/// a pessoa entra: o telefone a alcança, o curso a descreve. E como o telefone
/// é pré-requisito pra entrar na lista, depender de um admin pra preenchê-lo
/// deixaria o aluno esperando enquanto perde a viagem.
class OwnDataCard extends StatefulWidget {
  final String? phone;
  final String? course;
  final bool isStudent;
  final VoidCallback? onSaved;

  /// Injetável pro teste; em produção constrói o seu.
  final ProfileService? service;

  const OwnDataCard({
    super.key,
    required this.phone,
    required this.course,
    required this.isStudent,
    this.onSaved,
    this.service,
  });

  @override
  State<OwnDataCard> createState() => _OwnDataCardState();
}

class _OwnDataCardState extends State<OwnDataCard> {
  late final ProfileService _service = widget.service ?? ProfileService();
  final _phoneCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.phone ?? '';
    _courseCtrl.text = widget.course ?? '';
    _phoneCtrl.addListener(_aoDigitar);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_aoDigitar);
    _phoneCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  /// O aviso de pendência tem que sumir enquanto se digita, não só depois de
  /// salvar: ver o alerta vermelho com o campo já preenchido parece erro.
  void _aoDigitar() => setState(() {});

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await _service.updateOwnProfile(
        phone: _phoneCtrl.text.trim(),
        // Nem chega a ir pro admin; mandar mesmo assim gravaria curso de uma
        // sessão anterior que trocou de papel.
        course: widget.isStudent ? _courseCtrl.text.trim() : null,
      );
      if (!mounted) return;
      showSuccessSnackBar(context, 'Dados salvos');
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semTelefone = _phoneCtrl.text.trim().isEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Seus dados', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'O telefone é o único contato direto no dia da viagem.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          AppTextField(
            key: const Key('own_data_phone_field'),
            label: 'Telefone',
            controller: _phoneCtrl,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          if (widget.isStudent) ...[
            const SizedBox(height: 12),
            AppTextField(
              key: const Key('own_data_course_field'),
              label: 'Curso',
              controller: _courseCtrl,
              icon: Icons.school_outlined,
              hint: 'Opcional',
            ),
          ],

          if (semTelefone) ...[
            const SizedBox(height: 14),
            Row(
              key: const Key('own_data_missing_warning'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Falta preencher: Telefone. '
                    'Sem isso você não consegue entrar na lista.',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          LoadingFilledButton(
            key: const Key('own_data_save_button'),
            loading: _salvando,
            onPressed: _salvar,
            label: 'Salvar dados',
          ),
        ],
      ),
    );
  }
}
