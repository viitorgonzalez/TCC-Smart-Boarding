import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/map_stop.dart';

/// Pino da parada: verde na origem, bandeira no destino, numerado no meio.
class StopPin extends StatelessWidget {
  final MapStop stop;
  final bool isFirst;
  final bool isLast;

  const StopPin({
    super.key,
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
              painter: PinTip(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class PinTip extends CustomPainter {
  final Color color;
  const PinTip({required this.color});

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
  bool shouldRepaint(covariant PinTip oldDelegate) =>
      oldDelegate.color != color;
}
