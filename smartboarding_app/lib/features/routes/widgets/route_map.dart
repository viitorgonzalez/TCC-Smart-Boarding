import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/theme/app_theme.dart';
import '../services/road_route_service.dart';
import 'map_button.dart';
import '../models/map_stop.dart';
import 'route_map_layers.dart';

class RouteMap extends StatefulWidget {
  final List<MapStop> stops;
  final void Function(LatLng point)? onTapPoint;

  final bool compact;

  final VoidCallback? onTap;

  final void Function(MapStop stop)? onTapStop;

  final String? modeLabel;

  final VoidCallback? onCancelMode;

  /// Injetável só para teste: o padrão fala com o OSRM de verdade.
  final RoadRouteService? roadRoute;

  const RouteMap({
    super.key,
    required this.stops,
    this.onTapPoint,
    this.compact = false,
    this.onTap,
    this.onTapStop,
    this.modeLabel,
    this.onCancelMode,
    this.roadRoute,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final _controller = MapController();
  late final RoadRouteService _roadRoute;
  bool _addMode = false;
  List<LatLng>? _roadPath;
  bool _loadingPath = false;

  static const _formiga = LatLng(-20.4644, -45.4269);

  @override
  void initState() {
    super.initState();
    _roadRoute = widget.roadRoute ?? RoadRouteService();
    _loadRoadPath();
  }

  @override
  void didUpdateWidget(covariant RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stops.length != widget.stops.length) {
      _loadRoadPath();
    }
  }

  Future<void> _loadRoadPath() async {
    final points = _located
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();
    if (points.length < 2) {
      setState(() => _roadPath = null);
      return;
    }
    setState(() => _loadingPath = true);
    final path = await _roadRoute.pathThrough(points);
    if (!mounted) return;
    setState(() {
      _roadPath = path;
      _loadingPath = false;
    });
  }

  List<MapStop> get _located => widget.stops;

  LatLng get _center {
    final located = _located;
    if (located.isEmpty) return _formiga;
    return LatLng(located.first.latitude, located.first.longitude);
  }

  CameraFit? get _fitAllStops {
    final points = _located
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();
    if (points.length < 2) return null;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: const EdgeInsets.all(28),
    );
  }

  void _zoom(double delta) {
    final camera = _controller.camera;
    _controller.move(camera.center, (camera.zoom + delta).clamp(3.0, 18.0));
  }

  @override
  Widget build(BuildContext context) {
    final located = _located;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            height: widget.compact ? 190 : 320,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 13,
                    initialCameraFit: widget.compact ? _fitAllStops : null,
                    interactionOptions: InteractionOptions(
                      flags: widget.compact
                          ? InteractiveFlag.none
                          : InteractiveFlag.all,
                    ),
                    onTap: (_, point) {
                      if (widget.modeLabel != null) {
                        widget.onTapPoint?.call(point);
                        return;
                      }
                      if (!_addMode) return;
                      setState(() => _addMode = false);
                      widget.onTapPoint?.call(point);
                    },
                  ),
                  children: [
                    osmTiles(),
                    if (located.length > 1) routePolyline(located, _roadPath),
                    stopMarkers(located, widget.onTapStop),
                  ],
                ),
                if (widget.compact && widget.onTap != null)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: widget.onTap),
                    ),
                  ),
                if (!widget.compact)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Column(
                      children: [
                        MapButton(
                          icon: Icons.add,
                          tooltip: 'Aproximar',
                          onPressed: () => _zoom(1),
                        ),
                        const SizedBox(height: 6),
                        MapButton(
                          icon: Icons.remove,
                          tooltip: 'Afastar',
                          onPressed: () => _zoom(-1),
                        ),
                        const SizedBox(height: 6),
                        MapButton(
                          icon: Icons.my_location,
                          tooltip: 'Centralizar no trajeto',
                          onPressed: () {
                            final fit = _fitAllStops;
                            if (fit == null) {
                              _controller.move(_center, 13);
                            } else {
                              _controller.fitCamera(fit);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                if (_loadingPath)
                  const Positioned(
                    left: 10,
                    bottom: 10,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (_addMode || widget.modeLabel != null)
                  Positioned(
                    left: 10,
                    right: 62,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepTeal,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.modeLabel ?? 'Toque no ponto da parada',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (widget.onCancelMode != null)
                            GestureDetector(
                              onTap: widget.onCancelMode,
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.onTapPoint != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _addMode
                    ? OutlinedButton.icon(
                        onPressed: () => setState(() => _addMode = false),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                      )
                    : FilledButton.icon(
                        onPressed: () => setState(() => _addMode = true),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Adicionar parada'),
                      ),
              ),
            ],
          ),
        ],
        if (!widget.compact) ...[
          const SizedBox(height: 6),
          Text(
            'Arraste pra mover · roda do mouse pra aproximar',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
