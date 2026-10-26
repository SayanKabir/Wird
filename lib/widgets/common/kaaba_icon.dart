import 'package:flutter/material.dart';

/// The Kaaba, drawn instead of the 🕋 emoji (which looks different on every
/// platform and has no Material icon): a dark cube seen slightly from the
/// side, with the gold band of the kiswah and the door.
///
/// Sized like an [Icon]; works from badge size (12) up to the Qibla marker.
class KaabaIcon extends StatelessWidget {
  final double size;

  const KaabaIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: const _KaabaPainter());
  }
}

class _KaabaPainter extends CustomPainter {
  const _KaabaPainter();

  static const _gold = Color(0xFFE9B95A);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);

    // Faces: front (left), side (right) and the roof, each a shade apart.
    final front = poly([p(0.08, 0.3), p(0.6, 0.38), p(0.6, 0.92), p(0.08, 0.84)]);
    final side = poly([p(0.6, 0.38), p(0.92, 0.28), p(0.92, 0.82), p(0.6, 0.92)]);
    final roof = poly([p(0.08, 0.3), p(0.42, 0.2), p(0.92, 0.28), p(0.6, 0.38)]);
    canvas.drawPath(front, Paint()..color = const Color(0xFF26262E));
    canvas.drawPath(side, Paint()..color = const Color(0xFF16161C));
    canvas.drawPath(roof, Paint()..color = const Color(0xFF3A3A44));

    // The gold band, following each face's slope.
    final band = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075;
    canvas.drawLine(p(0.08, 0.43), p(0.6, 0.51), band);
    canvas.drawLine(p(0.6, 0.51), p(0.92, 0.41), band..color = _gold.withValues(alpha: 0.75));

    // The door, on the front face.
    canvas.drawPath(
      poly([p(0.4, 0.62), p(0.5, 0.635), p(0.5, 0.86), p(0.4, 0.845)]),
      Paint()..color = _gold.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _KaabaPainter old) => false;
}
