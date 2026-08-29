import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// latlong2 exporta uma classe Path própria, que sombreia a de dart:ui usada
// no desenho do pino.
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/theme/app_theme.dart';
import '../services/road_route_service.dart';

/// Desacopla o mapa dos modelos de parada de cada feature.
class MapStop {
  final String? id;
  final String name;
  final double latitude;
  final double longitude;
  final int sequence;

  const MapStop({
    required this.name,
    this.id,
    required this.latitude,
    required this.longitude,
    required this.sequence,
  });
}

/// Pensado também pra mouse: sem pinça, o zoom depende da roda ou dos botões,
/// e o clique só cria parada em modo de adição — senão arrastar viraria diálogo.
class RouteMap extends StatefulWidget {
  final List<MapStop> stops;
  final void Function(LatLng point)? onTapPoint;

  /// No card o mapa é ilustração, não ferramenta: menor e sem controles.
  final bool compact;

  final VoidCallback? onTap;

  final void Function(MapStop stop)? onTapStop;

  final String? modeLabel;

  final VoidCallback? onCancelMode;

  /// Nulo deixa o mapa somente leitura (visão do aluno).
  const RouteMap({
    super.key,
    required this.stops,
    this.onTapPoint,
    this.compact = false,
    this.onTap,
    this.onTapStop,
    this.modeLabel,
    this.onCancelMode,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final _controller = MapController();
  final _roadRoute = RoadRouteService();
  bool _addMode = false;
  List<LatLng>? _roadPath;
  bool _loadingPath = false;

  static const _formiga = LatLng(-20.4644, -45.4269);

  @override
  void initState() {
    super.initState();
    _loadRoadPath();
  }

  @override
  void didUpdateWidget(covariant RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stops.length != widget.stops.length) {
      _loadRoadPath();
    }
  }

  /// Caminho por ruas entre as paradas. Se o serviço não responder, o mapa
  /// segue mostrando a ligação reta — melhor que trajeto nenhum.
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

  /// Centralizar na primeira parada com zoom fixo escondia o resto do trajeto.
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
                    // Só no card: a tela cheia abre centrada e o usuário navega.
                    initialCameraFit: widget.compact ? _fitAllStops : null,
                    // Explícito pra garantir zoom pela roda do mouse, que é o
                    // único gesto de zoom disponível sem tela sensível. No card
                    // o mapa é ilustração: gesto ali deve rolar a página.
                    interactionOptions: InteractionOptions(
                      flags: widget.compact
                          ? InteractiveFlag.none
                          : InteractiveFlag.all,
                    ),
                    onTap: (_, point) {
                      // Modo vindo de fora (mover/inserir) tem prioridade: o
                      // toque é a colocação daquele ponto.
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
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.smartboarding.smartboarding_app',
                    ),
                    if (located.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points:
                                _roadPath ??
                                [
                                  for (final s in located)
                                    LatLng(s.latitude, s.longitude),
                                ],
                            strokeWidth: 5,
                            color: AppColors.deepTeal,
                            // Reta pontilhada deixa claro que é ligação direta,
                            // não o caminho real por ruas.
                            pattern: _roadPath == null
                                ? const StrokePattern.dotted()
                                : const StrokePattern.solid(),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        for (var i = 0; i < located.length; i++)
                          Marker(
                            point: LatLng(
                              located[i].latitude,
                              located[i].longitude,
                            ),
                            width: 40,
                            height: 48,
                            // Ancora a ponta do pino no ponto, não o centro.
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onTap: widget.onTapStop == null
                                  ? null
                                  : () => widget.onTapStop!(located[i]),
                              child: _StopPin(
                                stop: located[i],
                                isFirst: i == 0,
                                isLast: i == located.length - 1,
                              ),
                            ),
                          ),
                      ],
                    ),
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
                        _MapButton(
                          icon: Icons.add,
                          tooltip: 'Aproximar',
                          onPressed: () => _zoom(1),
                        ),
                        const SizedBox(height: 6),
                        _MapButton(
                          icon: Icons.remove,
                          tooltip: 'Afastar',
                          onPressed: () => _zoom(-1),
                        ),
                        const SizedBox(height: 6),
                        _MapButton(
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

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.control),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: AppColors.charcoal),
          ),
        ),
      ),
    );
  }
}

/// Origem e destino ganham cor própria: num trajeto é o que se lê primeiro.
class _StopPin extends StatelessWidget {
  final MapStop stop;
  final bool isFirst;
  final bool isLast;

  const _StopPin({
    required this.stop,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch ((isFirst, isLast)) {
      (true, _) => (AppColors.positiveFg, Icons.trip_origin),
      (_, true) => (AppColors.charcoal, Icons.flag),
      _ => (AppColors.deepTeal, null),
    };

    return Tooltip(
      message: stop.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, size: 15, color: Colors.white)
                : Text(
                    '${stop.sequence}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
          Transform.translate(
            offset: const Offset(0, -3),
            child: CustomPaint(
              size: const Size(12, 10),
              painter: _PinTip(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTip extends CustomPainter {
  final Color color;
  const _PinTip({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      Path()
        ..moveTo(2, 0)
        ..lineTo(size.width / 2, size.height - 3)
        ..lineTo(size.width - 2, 0)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _PinTip oldDelegate) =>
      oldDelegate.color != color;
}
