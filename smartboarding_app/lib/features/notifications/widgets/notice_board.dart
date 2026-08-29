import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Quadro de avisos: a metáfora do mural, desenhada com os tokens do app.
///
/// O painel recuado em [AppColors.ashGrey] é a mesma superfície das telas de
/// autenticação, e os bilhetes são cartões do design system — o que muda em
/// relação a uma lista comum é a malha de pontos do mural e o alfinete, não a
/// paleta.
class NoticeBoard extends StatelessWidget {
  final List<Widget> notes;
  final Future<void> Function()? onRefresh;

  const NoticeBoard({super.key, required this.notes, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final board = Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.ashGrey,
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        border: Border.all(color: AppColors.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _PegboardPainter(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
          children: notes,
        ),
      ),
    );

    return onRefresh == null
        ? board
        : RefreshIndicator(onRefresh: onRefresh!, child: board);
  }
}

/// Malha de furos do mural. Regular de propósito: é o que separa "quadro" de
/// "fundo colorido" sem apelar pra textura.
class _PegboardPainter extends CustomPainter {
  static const _spacing = 22.0;
  static const _radius = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = AppColors.stroke.withValues(alpha: 0.85);
    for (var y = _spacing; y < size.height; y += _spacing) {
      for (var x = _spacing; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _radius, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bilhete preso no mural. A inclinação vem do [seed] (id do aviso) pra o mesmo
/// bilhete cair sempre no mesmo ângulo entre rebuilds — sutil, só o bastante
/// pra ler como papel preso e não como cartão desalinhado.
class NoticeNote extends StatelessWidget {
  final String seed;
  final Widget child;
  final bool faded;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Cor do alfinete. Nulo usa a primária (ou o cinza de apoio, se [faded]).
  final Color? accent;

  /// Marcado na seleção múltipla do admin.
  final bool selected;

  const NoticeNote({
    super.key,
    required this.seed,
    required this.child,
    this.faded = false,
    this.onTap,
    this.onLongPress,
    this.accent,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final random = math.Random(seed.hashCode);
    final angle = (random.nextDouble() * 2 - 1) * 0.008;
    final pin = faded
        ? AppColors.textSecondary
        : (accent ?? AppColors.deepTeal);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Transform.rotate(
        angle: angle,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              // Folga no topo pro alfinete não encostar no texto.
              margin: const EdgeInsets.only(top: 7),
              decoration: BoxDecoration(
                color: faded ? AppColors.background : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: selected ? AppColors.deepTeal : AppColors.stroke,
                  width: selected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                    child: child,
                  ),
                ),
              ),
            ),
            Positioned(top: 0, child: _Pin(color: pin)),
          ],
        ),
      ),
    );
  }
}

/// Alfinete: disco cheio com anel claro em volta, no mesmo vocabulário dos
/// outros indicadores do app — sem brilho nem volume falso.
class _Pin extends StatelessWidget {
  final Color color;
  const _Pin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 3),
      ),
    );
  }
}
