import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/text/plural.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../institutions/providers/institution_provider.dart';
import '../../notifications/widgets/scheduled_notifications_section.dart';
import '../../users/models/user_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/vehicle_model.dart';
import '../providers/route_provider.dart';
import '../screens/invite_codes_screen.dart';
import '../screens/route_section_screen.dart';
import 'route_institutions_card.dart';
import 'route_stops_editor.dart';
import 'route_students_card.dart';
import 'route_vehicles_card.dart';

/// Card "Configuração da rota": cada linha abre uma seção empilhada.
class RouteConfigCard extends StatelessWidget {
  final RouteModel route;
  final List<StopModel> stops;
  final List<VehicleModel> vehicles;
  final List<UserModel> students;
  final bool admitsNoInstitution;
  final Future<void> Function(Future<void> Function() action, String success)
  run;
  final Future<void> Function(bool valor) onAdmitsNoInstitutionChanged;
  final Future<void> Function() onSectionClosed;

  const RouteConfigCard({
    super.key,
    required this.route,
    required this.stops,
    required this.vehicles,
    required this.students,
    required this.admitsNoInstitution,
    required this.run,
    required this.onAdmitsNoInstitutionChanged,
    required this.onSectionClosed,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _linha(
            context,
            chave: 'section_codes',
            icone: Icons.vpn_key_outlined,
            titulo: 'Códigos de acesso',
            detalhe: 'Quem pode entrar nesta rota',
            abre: () => InviteCodesScreen(routes: [route]),
            telaPropria: true,
          ),
          _linha(
            context,
            chave: 'section_stops',
            icone: Icons.route_outlined,
            titulo: 'Trajeto',
            detalhe: contagem(stops.length, 'parada', 'paradas'),
            abre: () => RouteStopsEditor(
              routeId: route.id,
              stops: stops,
              run: run,
              institutions: context.read<InstitutionProvider>().servedBy(
                route.id,
              ),
            ),
          ),
          _linha(
            context,
            chave: 'section_vehicles',
            icone: Icons.directions_bus_outlined,
            titulo: 'Frota',
            detalhe: contagem(vehicles.length, 'veículo', 'veículos'),
            abre: () => RouteVehiclesCard(
              routeId: route.id,
              vehicles: vehicles,
              run: run,
            ),
          ),
          _linha(
            context,
            chave: 'section_institutions',
            icone: Icons.school_outlined,
            titulo: 'Instituições atendidas',
            detalhe: 'Quais escolas usam esta rota',
            abre: () => RouteInstitutionsCard(
              routeId: route.id,
              admitsNoInstitution: admitsNoInstitution,
              onAdmitsNoInstitutionChanged: onAdmitsNoInstitutionChanged,
            ),
          ),
          _linha(
            context,
            chave: 'section_notices',
            icone: Icons.notifications_outlined,
            titulo: 'Avisos automáticos',
            detalhe: 'Mensagens que saem sozinhas',
            abre: () => ScheduledNotificationsSection(routeId: route.id),
          ),
          _linha(
            context,
            chave: 'section_students',
            icone: Icons.people_outline,
            titulo: 'Alunos',
            detalhe: 'Quem está nesta rota',
            abre: () => RouteStudentsCard(
              students: students,
              routeId: route.id,
              routeName: route.name,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linha(
    BuildContext context, {
    required String chave,
    required IconData icone,
    required String titulo,
    required String detalhe,
    required Widget Function() abre,
    bool telaPropria = false,
  }) {
    return ListTile(
      key: Key(chave),
      leading: Icon(icone, color: AppColors.deepTeal),
      title: Text(titulo),
      subtitle: Text(detalhe),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _abrirSecao(context, titulo, abre, telaPropria: telaPropria),
    );
  }

  Future<void> _abrirSecao(
    BuildContext context,
    String titulo,
    Widget Function() constroi, {
    required bool telaPropria,
  }) async {
    // A rota empilhada não herda o escopo de providers do detalhe — sem
    // reprovê-los aqui, a seção aberta não acha InstitutionProvider.
    final institutionProvider = context.read<InstitutionProvider>();
    final routeProvider = context.read<RouteProvider>();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: institutionProvider),
            ChangeNotifierProvider.value(value: routeProvider),
          ],
          child: telaPropria
              ? constroi()
              : RouteSectionScreen(title: titulo, child: constroi()),
        ),
      ),
    );
    if (context.mounted) await onSectionClosed();
  }
}
