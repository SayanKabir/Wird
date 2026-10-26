import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wird's own drawn icons, for the things Material has no good symbol for:
/// the Kaaba, prayer beads, the Hijri calendar and an eight-pointed star.
/// Each sizes like an [Icon] and, apart from the Kaaba, takes the ambient
/// [IconTheme] colour unless given one.

Color _iconColor(BuildContext context, Color? color) =>
    color ?? IconTheme.of(context).color ?? Colors.white;

/// The Kaaba seen from a corner: kiswah with a soft sheen, the gold band of
/// calligraphy around its upper third, the raised gold door and a shadow on
/// the mataf beneath. Full colour at every size.
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
  static const _goldLight = Color(0xFFFFE7A8);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);

    // Shadow on the floor.
    canvas.drawOval(
      Rect.fromCenter(center: p(0.52, 0.9), width: s * 0.92, height: s * 0.14),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
    );

    // Corners: top-left, top-front, top-right, top-back, and the base below.
    final tl = p(0.06, 0.3), tf = p(0.58, 0.4), tr = p(0.94, 0.27), tb = p(0.44, 0.18);
    final bl = p(0.06, 0.8), bf = p(0.58, 0.92), br = p(0.94, 0.78);

    final front = poly([tl, tf, bf, bl]);
    final side = poly([tf, tr, br, bf]);
    final roof = poly([tl, tb, tr, tf]);

    canvas.drawPath(
      front,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34343E), Color(0xFF1C1C24)],
        ).createShader(Rect.fromPoints(tl, bf)),
    );
    canvas.drawPath(
      side,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E26), Color(0xFF0E0E14)],
        ).createShader(Rect.fromPoints(tf, br)),
    );
    canvas.drawPath(roof, Paint()..color = const Color(0xFF4A4A56));

    // Band of calligraphy: a gold strip on each face, with darker marks
    // standing in for the script.
    Offset lerp(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;
    void band(Offset topL, Offset topR, Offset botL, Offset botR, double shade) {
      final a = lerp(topL, botL, 0.18), b = lerp(topR, botR, 0.18);
      final c = lerp(topR, botR, 0.28), d = lerp(topL, botL, 0.28);
      canvas.drawPath(poly([a, b, c, d]), Paint()..color = Color.lerp(_gold, Colors.black, shade)!);
      final marks = Paint()
        ..color = const Color(0xFF6B4A12).withValues(alpha: 0.75)
        ..strokeWidth = math.max(0.6, s * 0.018)
        ..strokeCap = StrokeCap.round;
      for (var i = 1; i < 6; i++) {
        final t = i / 6;
        final m1 = lerp(lerp(a, b, t), lerp(d, c, t), 0.3);
        final m2 = lerp(lerp(a, b, t + 0.06), lerp(d, c, t + 0.06), 0.7);
        canvas.drawLine(m1, m2, marks);
      }
    }

    band(tl, tf, bl, bf, 0);
    band(tf, tr, bf, br, 0.25);

    // The door, raised on the front face, with a light frame.
    final door = poly([
      lerp(lerp(tl, tf, 0.6), lerp(bl, bf, 0.6), 0.5),
      lerp(lerp(tl, tf, 0.82), lerp(bl, bf, 0.82), 0.5),
      lerp(lerp(tl, tf, 0.82), lerp(bl, bf, 0.82), 0.86),
      lerp(lerp(tl, tf, 0.6), lerp(bl, bf, 0.6), 0.86),
    ]);
    canvas.drawPath(
      door,
      Paint()
        ..shader = const LinearGradient(colors: [_goldLight, _gold]).createShader(door.getBounds()),
    );
    canvas.drawPath(
      door,
      Paint()
        ..color = const Color(0xFF6B4A12).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, s * 0.015),
    );

    // A thin highlight down the near corner.
    canvas.drawLine(
      tf,
      bf,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = math.max(0.5, s * 0.02),
    );
  }

  @override
  bool shouldRepaint(covariant _KaabaPainter old) => false;
}

/// Prayer beads: a loop of beads on a thread, the larger imam bead at the
/// bottom and a short tassel below it.
class TasbihIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const TasbihIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _TasbihPainter(_iconColor(context, color)));
  }
}

class _TasbihPainter extends CustomPainter {
  final Color color;

  const _TasbihPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final fill = Paint()..color = color;
    final thread = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035;

    // A teardrop loop, narrow at the bottom where it gathers at the imam bead.
    final c = Offset(s * 0.5, s * 0.4);
    const beads = 13;
    final points = <Offset>[];
    for (var i = 0; i < beads; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / beads;
      // Pull the lower half in towards the centre line.
      final squeeze = 1 - 0.35 * math.max(0, math.sin(a));
      points.add(c + Offset(math.cos(a) * s * 0.33 * squeeze, math.sin(a) * s * 0.3));
    }
    final imam = Offset(s * 0.5, s * 0.74);
    canvas.drawPath(Path()..addPolygon([...points], true), thread);
    for (final pt in points) {
      // Leave the bottom of the loop to the imam bead.
      if ((pt - imam).distance < s * 0.12) continue;
      canvas.drawCircle(pt, s * 0.06, fill);
    }
    canvas.drawCircle(imam, s * 0.085, fill);
    // Tassel.
    final tassel = Paint()
      ..color = color
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(imam + Offset(0, s * 0.08), Offset(s * 0.5, s * 0.92), tassel);
    canvas.drawLine(imam + Offset(0, s * 0.1), Offset(s * 0.42, s * 0.92), tassel..strokeWidth = s * 0.03);
    canvas.drawLine(imam + Offset(0, s * 0.1), Offset(s * 0.58, s * 0.92), tassel);
  }

  @override
  bool shouldRepaint(covariant _TasbihPainter old) => old.color != color;
}

/// A calendar page with a crescent and star on it: the Hijri calendar.
class HijriCalendarIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const HijriCalendarIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _HijriCalendarPainter(_iconColor(context, color)));
  }
}

class _HijriCalendarPainter extends CustomPainter {
  final Color color;

  const _HijriCalendarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round;
    final page = RRect.fromLTRBR(s * 0.12, s * 0.2, s * 0.88, s * 0.9, Radius.circular(s * 0.14));
    canvas.drawRRect(page, line);
    // Header rule and the two rings.
    canvas.drawLine(Offset(s * 0.14, s * 0.38), Offset(s * 0.86, s * 0.38), line..strokeWidth = s * 0.07);
    canvas.drawLine(Offset(s * 0.33, s * 0.1), Offset(s * 0.33, s * 0.27), line..strokeWidth = s * 0.08);
    canvas.drawLine(Offset(s * 0.67, s * 0.1), Offset(s * 0.67, s * 0.27), line);

    // Crescent and star on the page.
    final c = Offset(s * 0.45, s * 0.64);
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.17)),
      Path()..addOval(Rect.fromCircle(center: c + Offset(s * 0.08, -s * 0.05), radius: s * 0.14)),
    );
    canvas.drawPath(moon, Paint()..color = color);
    _fourPoint(canvas, Offset(s * 0.66, s * 0.57), s * 0.075, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HijriCalendarPainter old) => old.color != color;
}

/// An eight-pointed star (khatim), the motif of Islamic tilework. Used where
/// a touch of distinction is wanted, in place of a generic sparkle.
class KhatimIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const KhatimIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _KhatimPainter(_iconColor(context, color)));
  }
}

class _KhatimPainter extends CustomPainter {
  final Color color;

  const _KhatimPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = size.center(Offset.zero);
    // A square of half-width r around the centre, turned by [turn].
    Path square(double r, double turn) => (Path()
          ..addRect(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2)))
        .transform((Matrix4.identity()
              ..translateByDouble(c.dx, c.dy, 0, 1)
              ..rotateZ(turn))
            .storage);
    Path star(double r) => Path.combine(PathOperation.union, square(r, 0), square(r, math.pi / 4));

    // An outlined star with a solid star set inside it.
    canvas.drawPath(
      star(s * 0.32),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.07
        ..strokeJoin = StrokeJoin.miter,
    );
    canvas.drawPath(star(s * 0.15), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _KhatimPainter old) => old.color != color;
}

/// A small four-pointed star.
void _fourPoint(Canvas canvas, Offset c, double r, Paint paint) {
  final w = r * 0.3;
  canvas.drawPath(
    Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
      ..close(),
    paint,
  );
}
