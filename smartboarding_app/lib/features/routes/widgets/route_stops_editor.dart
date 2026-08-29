import 'package:flutter/material.dart';
// latlong2 exporta uma classe Path própria, que sombreia a de dart:ui usada
// no desenho do pino.
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/text_prompt_dialog.dart';
import '../models/map_stop.dart';
import '../models/stop_model.dart';
import '../services/route_service.dart';
import 'route_map.dart';

/// Trajeto da rota: mapa mais lista, com mover parada e inserir entre duas.
///
/// O modo pendente (o que o próximo toque no mapa significa) é estado só desta
/// interação — fica aqui, não na tela da rota.
class RouteStopsEditor extends StatefulWidget {
  final String routeId;
  final List<StopModel> stops;

  /// Executa a chamada ao backend e recarrega a rota. Vem da tela porque o
  /// recarregamento é compartilhado com as outras seções.
  final Future<void> Function(Future<void> Function(), String) run;

  const RouteStopsEditor({
    super.key,
    required this.routeId,
    required this.stops,
    required this.run,
  });

  @override
  State<RouteStopsEditor> createState() => _RouteStopsEditorState();
}

class _RouteStopsEditorState extends State<RouteStopsEditor> {
  final _service = RouteService();

  /// Parada sendo reposicionada, ou depois da qual a próxima será inserida.
  StopModel? _pendingStop;
  _StopAction? _pendingAction;

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
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => widget.run(
                  () => _service.deleteStop(widget.routeId, stop.id),
                  'Parada removida',
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? get _modeLabel => switch (_pendingAction) {
    _StopAction.move => 'Toque no novo local de "${_pendingStop!.name}"',
    _StopAction.insertAfter =>
      'Toque onde entra a parada depois de "${_pendingStop!.name}"',
    _ => null,
  };

  /// O toque no mapa muda de significado conforme o modo ativo.

  Future<void> _onMapPoint(LatLng point) async {
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

    if (action == _StopAction.move) {
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

  Future<void> _onTapStop(MapStop tapped) async {
    final stop = widget.stops.firstWhere((s) => s.id == tapped.id);
    final action = await showModalBottomSheet<_StopAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                stop.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('Parada ${stop.sequence}'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.open_with, color: AppColors.deepTeal),
              title: const Text('Mover para outro local'),
              onTap: () => Navigator.pop(context, _StopAction.move),
            ),
            ListTile(
              leading: const Icon(
                Icons.add_location_alt_outlined,
                color: AppColors.deepTeal,
              ),
              title: const Text('Inserir parada depois desta'),
              onTap: () => Navigator.pop(context, _StopAction.insertAfter),
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.deepTeal,
              ),
              title: const Text('Renomear'),
              onTap: () => Navigator.pop(context, _StopAction.rename),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text('Remover'),
              onTap: () => Navigator.pop(context, _StopAction.remove),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _StopAction.move:
      case _StopAction.insertAfter:
        setState(() {
          _pendingAction = action;
          _pendingStop = stop;
        });
      case _StopAction.rename:
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
      case _StopAction.remove:
        await widget.run(
          () => _service.deleteStop(widget.routeId, stop.id),
          'Parada removida',
        );
    }
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

enum _StopAction { move, insertAfter, rename, remove }
