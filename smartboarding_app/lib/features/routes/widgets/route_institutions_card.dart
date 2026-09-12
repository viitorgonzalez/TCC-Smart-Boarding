import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../institutions/models/institution_model.dart';
import '../../institutions/services/institution_service.dart';

/// Instituições atendidas pela rota. O aluno só enxerga a rota se a instituição
/// dele apontar pra cá (RN15), então criar já nasce vinculada.
class RouteInstitutionsCard extends StatelessWidget {
  final String routeId;
  final List<InstitutionModel> institutions;
  final Future<void> Function(Future<void> Function(), String) run;

  const RouteInstitutionsCard({
    super.key,
    required this.routeId,
    required this.institutions,
    required this.run,
  });

  InstitutionService get _service => InstitutionService();

  @override
  Widget build(BuildContext context) => _card(context);

  Widget _card(BuildContext context) {
    final linked = institutions.where((i) => i.routeId == routeId).toList();
    final others = institutions.where((i) => i.routeId != routeId).toList();

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          if (linked.isEmpty)
            const ListTile(
              title: Text('Nenhuma instituição atendida'),
              subtitle: Text(
                'Alunos só veem esta rota se a instituição deles apontar pra ela.',
              ),
            ),
          for (final institution in linked)
            ListTile(
              leading: const Icon(Icons.school, color: AppColors.deepTeal),
              title: Text(institution.name),
              subtitle: institution.address == null
                  ? null
                  : Text(
                      institution.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) => _institutionAction(context, v, institution),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'unlink', child: Text('Desvincular')),
                  PopupMenuItem(value: 'delete', child: Text('Remover')),
                ],
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add, color: AppColors.deepTeal),
            title: const Text('Cadastrar instituição nesta rota'),
            onTap: () => _promptCreateInstitution(context),
          ),
          if (others.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.deepTeal),
              title: const Text('Vincular uma já cadastrada'),
              onTap: () => _promptLinkInstitution(context, others),
            ),
        ],
      ),
    );
  }

  /// Escopado por rota porque a base de usuários cresce sem teto.

  Future<void> _institutionAction(
    BuildContext context,
    String action,
    InstitutionModel i,
  ) async {
    switch (action) {
      case 'edit':
        final data = await _promptInstitutionForm(
          context,
          title: 'Editar instituição',
          name: i.name,
          address: i.address,
        );
        if (data == null) return;
        await run(
          () =>
              _service.updateInstitution(i.id, name: data.$1, address: data.$2),
          'Instituição atualizada',
        );
      case 'unlink':
        await run(
          () => _service.linkRoute(i.id, null),
          'Instituição desvinculada',
        );
      case 'delete':
        // O backend recusa se houver aluno vinculado — a rota dele sai daqui.
        await run(
          () => _service.deleteInstitution(i.id),
          'Instituição removida',
        );
    }
  }

  /// Já nasce vinculada: instituição sem rota deixa os alunos dela sem lista.

  Future<void> _promptCreateInstitution(BuildContext context) async {
    final data = await _promptInstitutionForm(
      context,
      title: 'Nova instituição',
    );
    if (data == null) return;
    await run(
      () => _service.createInstitution(
        data.$1,
        address: data.$2,
        routeId: routeId,
      ),
      'Instituição cadastrada nesta rota',
    );
  }

  Future<(String, String)?> _promptInstitutionForm(
    BuildContext context, {
    required String title,
    String? name,
    String? address,
  }) async {
    final nameCtrl = TextEditingController(text: name ?? '');
    final addressCtrl = TextEditingController(text: address ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Endereço'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return null;
    return (nameCtrl.text.trim(), addressCtrl.text.trim());
  }

  /// Só mover e inserir esperam um toque no mapa.
  /// O toque no mapa muda de significado conforme o modo ativo.

  Future<void> _promptLinkInstitution(
    BuildContext context,
    List<InstitutionModel> options,
  ) async {
    final chosen = await showDialog<InstitutionModel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Vincular instituição'),
        children: [
          for (final institution in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, institution),
              child: Text(institution.name),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    await run(
      () => _service.linkRoute(chosen.id, routeId),
      'Instituição vinculada',
    );
  }
}
