import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/option_sheet.dart';
import '../../../core/widgets/text_prompt_dialog.dart';
import '../../institutions/models/institution_model.dart';
import '../models/map_stop.dart';
import '../models/stop_model.dart';
import '../services/road_route_service.dart';
import '../services/route_service.dart';
import 'route_map.dart';
import 'stop_action_sheet.dart';

class RouteStopsEditor extends StatefulWidget {
  final String routeId;
  final List<StopModel> stops;

  final Future<void> Function(Future<void> Function(), String) run;

  final List<InstitutionModel> institutions;

  final RouteService? service;
  final RoadRouteService? roadService;

  const RouteStopsEditor({
    super.key,
    required this.routeId,
    required this.stops,
    required this.run,
    this.institutions = const [],
    this.service,
    this.roadService,
  });

  @override
  RouteStopsEditorState createState() => RouteStopsEditorState();
}

@visibleForTesting
class RouteStopsEditorState extends State<RouteStopsEditor> {
  late final RouteService _service = widget.service ?? RouteService();
  late final RoadRouteService _road = widget.roadService ?? RoadRouteService();

  StopModel? _pendingStop;
  StopAction? _pendingAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RouteMap(
          stops: [
            for (final s in widget.stops)
              if (s.hasCoordinates)
                MapStop(
                  id: s.id,
                  name: s.name,
                  latitude: s.latitude!,
                  longitude: s.longitude!,
                  sequence: s.sequence,
                ),
          ],
          onTapPoint: _onMapPoint,
          onTapStop: _onTapStop,
          modeLabel: _modeLabel,
          onCancelMode: _pendingAction == null
              ? null
              : () => setState(() {
                  _pendingAction = null;
                  _pendingStop = null;
                }),
        ),
        const SizedBox(height: 12),
        _stopsList(),
      ],
    );
  }

  Widget _stopsList() {
    if (widget.stops.isEmpty) {
      return const AppCard(
        child: Text('Nenhuma parada. Toque no mapa para adicionar.'),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (final stop in widget.stops)
            ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.ashGrey,
                child: Text(
                  '${stop.sequence}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkSlate,
                  ),
                ),
              ),
              title: Text(stop.name),
              subtitle: stop.hasCoordinates
                  ? Text(
                      '${stop.latitude!.toStringAsFixed(4)}, '
                      '${stop.longitude!.toStringAsFixed(4)}',
                    )
                  : const Text('sem coordenada'),
              trailing: const Icon(
                Icons.more_horiz,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  String? get _modeLabel => switch (_pendingAction) {
    StopAction.move => 'Toque no novo local de "${_pendingStop!.name}"',
    StopAction.insertAfter =>
      'Toque onde entra a parada depois de "${_pendingStop!.name}"',
    _ => null,
  };

  @visibleForTesting
  Future<void> onMapPoint(LatLng point) => _onMapPoint(point);

  Future<void> _onMapPoint(LatLng tocado) async {
    final point = await _road.snapToRoad(tocado) ?? tocado;
    if (!mounted) return;
    final action = _pendingAction;
    final target = _pendingStop;
    if (action == null) {
      await _promptAddStop(point);
      return;
    }
    setState(() {
      _pendingAction = null;
      _pendingStop = null;
    });

    if (action == StopAction.move) {
      await widget.run(
        () => _service.updateStop(
          widget.routeId,
          target!.id,
          latitude: point.latitude,
          longitude: point.longitude,
        ),
        'Parada movida',
      );
      return;
    }

    final name = await promptText(
      context,
      title: 'Parada depois de "${target!.name}"',
      hint: 'Ex.: Posto de saúde',
      helper:
          '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
    );
    if (name == null) return;
    await widget.run(
      () => _service.addStop(
        widget.routeId,
        name,
        latitude: point.latitude,
        longitude: point.longitude,
        sequence: target.sequence + 1,
      ),
      'Parada inserida',
    );
  }

  @visibleForTesting
  Future<void> onTapStop(MapStop tapped) => _onTapStop(tapped);

  Future<void> _onTapStop(MapStop tapped) async {
    final stop = widget.stops.firstWhere((s) => s.id == tapped.id);
    final action = await escolherAcaoDaParada(
      context,
      stop,
      podeVincularInstituicao: widget.institutions.isNotEmpty,
      instituicaoAtual: _nomeDaInstituicao(stop),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case StopAction.move:
      case StopAction.insertAfter:
        setState(() {
          _pendingAction = action;
          _pendingStop = stop;
        });
      case StopAction.rename:
        final name = await promptText(
          context,
          title: 'Renomear parada',
          hint: stop.name,
        );
        if (name == null) return;
        await widget.run(
          () => _service.updateStop(widget.routeId, stop.id, name: name),
          'Parada renomeada',
        );
      case StopAction.linkInstitution:
        await _escolherInstituicao(stop);
      case StopAction.remove:
        await widget.run(
          () => _service.deleteStop(widget.routeId, stop.id),
          'Parada removida',
        );
    }
  }

  String? _nomeDaInstituicao(StopModel stop) {
    if (stop.institutionId == null) return null;
    for (final i in widget.institutions) {
      if (i.id == stop.institutionId) return i.name;
    }
    return 'Instituição';
  }

  Future<void> _escolherInstituicao(StopModel stop) async {
    final escolha = await escolherOpcao<String>(
      context,
      'Esta parada serve qual instituição?',
      [
        ('Nenhuma — parada comum', 'a parada deixa de aceitar checkpoint', ''),
        for (final i in widget.institutions) (i.name, '', i.id),
      ],
      keyOf: (id) =>
          id.isEmpty ? const Key('stop_institution_none') : Key('inst_$id'),
    );
    if (escolha == null) return;
    await widget.run(
      () => _service.setStopInstitution(
        widget.routeId,
        stop.id,
        institutionId: escolha.isEmpty ? null : escolha,
      ),
      escolha.isEmpty ? 'Vínculo removido' : 'Instituição vinculada',
    );
  }

  Future<void> _promptAddStop(LatLng point) async {
    final name = await promptText(
      context,
      title: 'Nova parada',
      hint: 'Ex.: Rodoviária',
      helper:
          '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
    );
    if (name == null) return;
    await widget.run(
      () => _service.addStop(
        widget.routeId,
        name,
        latitude: point.latitude,
        longitude: point.longitude,
      ),
      'Parada adicionada',
    );
  }
}
