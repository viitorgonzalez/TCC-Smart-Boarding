import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/route_model.dart';

/// Filtro por rota. Só aparece com mais de uma rota — com uma só, o filtro não
/// filtra nada e vira ruído.
class FiltroDeRota extends StatelessWidget {
  final List<RouteModel> routes;
  final String? selecionado;
  final ValueChanged<String?> onChanged;

  const FiltroDeRota({
    super.key,
    required this.routes,
    required this.selecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todas'),
            selected: selecionado == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final r in routes) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(r.name),
              selected: selecionado == r.id,
              onSelected: (_) => onChanged(r.id),
            ),
          ],
        ],
      ),
    );
  }
}

/// Há códigos, mas nenhum da rota filtrada. Diferente de não haver nenhum: aqui
/// o caminho é tirar o filtro, não gerar código.
class SemCodigosNaRota extends StatelessWidget {
  const SemCodigosNaRota({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'Nenhum código desta rota',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  );
}

class SemCodigoNenhum extends StatelessWidget {
  const SemCodigoNenhum({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.vpn_key_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum código criado',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Gere um código e mande pra turma — quem tiver ele entra na rota.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
