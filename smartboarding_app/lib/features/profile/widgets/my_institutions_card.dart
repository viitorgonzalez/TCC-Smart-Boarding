import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../institutions/models/institution_model.dart';
import '../../institutions/services/institution_service.dart';
import '../services/profile_service.dart';

/// Instituições do aluno. É pré-requisito pra entrar em rota — sem nenhuma, o
/// backend recusa o código com PROFILE_INCOMPLETE.
///
/// Aceita mais de uma: quem faz dois cursos não precisa escolher qual declarar.
class MyInstitutionsCard extends StatefulWidget {
  final VoidCallback? onChanged;

  const MyInstitutionsCard({super.key, this.onChanged});

  @override
  State<MyInstitutionsCard> createState() => _MyInstitutionsCardState();
}

class _MyInstitutionsCardState extends State<MyInstitutionsCard> {
  final _profile = ProfileService();
  final _catalogo = InstitutionService();

  List<String> _minhas = const [];
  List<InstitutionModel> _todas = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resultados = await Future.wait([
        _profile.myInstitutions(),
        _catalogo.getInstitutions(),
      ]);
      if (!mounted) return;
      setState(() {
        _minhas = resultados[0] as List<String>;
        _todas = resultados[1] as List<InstitutionModel>;
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _agir(Future<void> Function() acao, String sucesso) async {
    try {
      await acao();
      await _load();
      if (mounted) {
        showSuccessSnackBar(context, sucesso);
        widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    }
  }

  Future<void> _adicionar() async {
    final disponiveis = _todas.where((i) => !_minhas.contains(i.id)).toList();
    if (disponiveis.isEmpty) {
      showErrorSnackBar(context, 'Você já declarou todas as instituições.');
      return;
    }
    final escolhida = await showDialog<InstitutionModel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Onde você estuda?'),
        children: [
          for (final i in disponiveis)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, i),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.school_outlined),
                title: Text(i.name),
              ),
            ),
        ],
      ),
    );
    if (escolhida == null || !mounted) return;
    await _agir(
      () => _profile.addInstitution(escolhida.id),
      '${escolhida.name} adicionada',
    );
  }

  String _nome(String id) {
    for (final i in _todas) {
      if (i.id == id) return i.name;
    }
    return 'Instituição';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Onde você estuda',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (_minhas.isEmpty)
                const Icon(
                  Icons.error_outline,
                  color: AppColors.danger,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_minhas.isEmpty)
            const Text(
              'Defina ao menos uma para poder entrar em uma rota.',
              style: TextStyle(color: AppColors.danger),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in _minhas)
                  Chip(
                    label: Text(_nome(id)),
                    // A primeira declarada e a principal: e ela que decide em
                    // que contagem da lista o aluno entra.
                    avatar: id == _minhas.first
                        ? const Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.deepTeal,
                          )
                        : null,
                    onDeleted: () => _agir(
                      () => _profile.removeInstitution(id),
                      '${_nome(id)} removida',
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('profile_add_institution'),
            onPressed: _adicionar,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar instituição'),
          ),
        ],
      ),
    );
  }
}
