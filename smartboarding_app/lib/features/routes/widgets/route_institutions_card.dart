import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../institutions/models/institution_model.dart';
import '../../institutions/providers/institution_provider.dart';

/// Instituições atendidas pela rota. Aqui só se ESCOLHE entre as que existem —
/// cadastrar e editar é na tela de Instituições.
///
/// Antes o caminho primário era "cadastrar nesta rota", o que espalhava o
/// cadastro por dentro de cada rota e escondia a lista real do catálogo.
class RouteInstitutionsCard extends StatelessWidget {
  final String routeId;

  const RouteInstitutionsCard({super.key, required this.routeId});

  Future<void> _run(
    BuildContext context,
    Future<void> Function() acao,
    String sucesso,
  ) async {
    try {
      await acao();
      if (context.mounted) {
        showSuccessSnackBar(context, sucesso);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, AppException.fromError(e));
      }
    }
  }

  Future<void> _escolher(BuildContext context) async {
    final provider = context.read<InstitutionProvider>();
    final disponiveis = provider.unlinked;

    if (disponiveis.isEmpty) {
      showErrorSnackBar(
        context,
        'Nenhuma instituição sem rota. Cadastre em Instituições.',
      );
      return;
    }

    final escolhida = await showDialog<InstitutionModel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Adicionar instituição'),
        children: [
          for (final i in disponiveis)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, i),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.school_outlined),
                title: Text(i.name),
                subtitle: i.address == null ? null : Text(i.address!),
              ),
            ),
        ],
      ),
    );
    if (escolhida == null || !context.mounted) return;
    await _run(
      context,
      () => provider.linkRoute(escolhida.id, routeId),
      '${escolhida.name} passa a ser atendida por esta rota',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InstitutionProvider>(
      builder: (context, provider, _) {
        final atendidas = provider.servedBy(routeId);

        return AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              if (atendidas.isEmpty)
                const ListTile(
                  title: Text('Nenhuma instituição atendida'),
                  subtitle: Text(
                    'Alunos só enxergam a lista se a instituição deles for '
                    'atendida por uma rota.',
                  ),
                ),
              for (final i in atendidas)
                ListTile(
                  leading: const Icon(Icons.school, color: AppColors.deepTeal),
                  title: Text(i.name),
                  subtitle: i.address == null
                      ? null
                      : Text(
                          i.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: IconButton(
                    tooltip: 'Remover desta rota',
                    icon: const Icon(Icons.link_off, size: 20),
                    // Desvincular nao apaga a instituicao: ela volta pro
                    // catalogo, disponivel pra outra rota.
                    onPressed: () => _run(
                      context,
                      () => provider.linkRoute(i.id, null),
                      '${i.name} não é mais atendida por esta rota',
                    ),
                  ),
                ),
              const Divider(height: 1),
              ListTile(
                key: const Key('route_add_institution'),
                leading: const Icon(Icons.add, color: AppColors.deepTeal),
                title: const Text('Adicionar instituição'),
                onTap: () => _escolher(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
