import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/vehicle_model.dart';
import '../services/route_service.dart';
import '../../../core/text/plural.dart';
import '../../../core/widgets/app_list_group.dart';

/// Frota que atende a rota. Capacidade é informação do transporte, não teto de
/// inscrição — quem decide o veículo é o total de confirmados no fechamento.
class RouteVehiclesCard extends StatelessWidget {
  final String routeId;
  final List<VehicleModel> vehicles;
  final Future<void> Function(Future<void> Function(), String) run;

  const RouteVehiclesCard({
    super.key,
    required this.routeId,
    required this.vehicles,
    required this.run,
  });

  RouteService get _service => RouteService();

  @override
  Widget build(BuildContext context) => _card(context);

  Widget _card(BuildContext context) {
    return AppListGroup(
      dividerIndent: 68,
      children: [
        for (final vehicle in vehicles)
          AppListItem(
            leading: const Icon(
              Icons.directions_bus_outlined,
              color: AppColors.deepTeal,
            ),
            title: vehicle.label,
            subtitle: contagem(vehicle.capacity, 'lugar', 'lugares'),
            menu: [
              destructiveMenuItem(
                label: 'Remover veículo',
                icon: Icons.delete_outline,
                onSelected: () => run(
                  () => _service.deleteVehicle(routeId, vehicle.id),
                  'Veículo removido',
                ),
              ),
            ],
          ),
        AppListItem(
          leading: const Icon(Icons.add, color: AppColors.deepTeal),
          title: 'Adicionar veículo',
          onTap: () => _promptAddVehicle(context),
        ),
      ],
    );
  }

  Future<void> _promptAddVehicle(BuildContext context) async {
    final labelCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo veículo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Identificação'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacidade'),
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
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    final capacity = int.tryParse(capacityCtrl.text.trim());
    if (ok != true || labelCtrl.text.trim().isEmpty || capacity == null) return;
    await run(
      () => _service.addVehicle(routeId, labelCtrl.text.trim(), capacity),
      'Veículo adicionado',
    );
  }
}
