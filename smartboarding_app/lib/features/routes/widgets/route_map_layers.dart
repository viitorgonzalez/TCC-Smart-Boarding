import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../models/map_stop.dart';
import 'stop_pin.dart';

TileLayer osmTiles() => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.smartboarding.smartboarding_app',
);

PolylineLayer routePolyline(List<MapStop> stops, List<LatLng>? roadPath) {
  return PolylineLayer(
    polylines: [
      Polyline(
        points:
            roadPath ??
            [for (final s in stops) LatLng(s.latitude, s.longitude)],
        strokeWidth: 5,
        color: AppColors.deepTeal,
        pattern: roadPath == null
            ? const StrokePattern.dotted()
            : const StrokePattern.solid(),
      ),
    ],
  );
}

MarkerLayer stopMarkers(
  List<MapStop> stops,
  void Function(MapStop)? onTapStop,
) {
  return MarkerLayer(
    markers: [
      for (var i = 0; i < stops.length; i++)
        Marker(
          point: LatLng(stops[i].latitude, stops[i].longitude),
          width: 40,
          height: 48,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: onTapStop == null ? null : () => onTapStop(stops[i]),
            child: StopPin(
              stop: stops[i],
              isFirst: i == 0,
              isLast: i == stops.length - 1,
            ),
          ),
        ),
    ],
  );
}
