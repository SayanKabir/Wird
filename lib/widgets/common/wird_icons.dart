import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

/// The Hijri calendar: a calendar page across which the moon waxes, from a
/// thin crescent through half to full, since its months follow the moon.
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
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round;
    // Page, with a filled header band and two binding rings.
    final page = RRect.fromLTRBR(s * 0.08, s * 0.16, s * 0.92, s * 0.9, Radius.circular(s * 0.14));
    canvas.drawRRect(page, line);
    canvas.save();
    canvas.clipRRect(page);
    canvas.drawRect(Rect.fromLTRB(0, 0, s, s * 0.36), Paint()..color = color.withValues(alpha: 0.35));
    canvas.restore();
    canvas.drawLine(Offset(s * 0.32, s * 0.06), Offset(s * 0.32, s * 0.24), line);
    canvas.drawLine(Offset(s * 0.68, s * 0.06), Offset(s * 0.68, s * 0.24), line);

    // Three phases across the page: crescent, half, full. The unlit part
    // of each moon is a faint disc rather than an outline, so they stay
    // legible at list size.
    final r = s * 0.125;
    final y = s * 0.63;
    final lit = Paint()..color = color;
    final dark = Paint()..color = color.withValues(alpha: 0.28);
    for (final (i, x) in [s * 0.235, s * 0.5, s * 0.765].indexed) {
      final c = Offset(x, y);
      final disc = Path()..addOval(Rect.fromCircle(center: c, radius: r));
      canvas.drawPath(disc, dark);
      final shape = switch (i) {
        // Waxing crescent: the disc minus a circle shifted left.
        0 => Path.combine(PathOperation.difference, disc,
            Path()..addOval(Rect.fromCircle(center: c - Offset(r * 0.6, 0), radius: r))),
        // First quarter: the right half.
        1 => Path.combine(PathOperation.intersect, disc, Path()..addRect(Rect.fromLTRB(x, y - r, x + r, y + r))),
        _ => disc,
      };
      canvas.drawPath(shape, lit);
    }
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

/// One icon per concept, used everywhere that concept appears: the tab bar,
/// settings groups, stats cards, achievements, onboarding. A screen never
/// picks its own symbol for the Quran or the Sunnah, so an icon can't come
/// to mean two things.
///
/// Drawn on a 24-unit grid in one line weight, from the app's own motifs:
/// the icon's arch, the khatim star, the sun's path through the day.
enum WirdGlyph {
  /// The arch from the app icon.
  home,

  /// An open mushaf on its rahl.
  quran,

  /// The sun's arc over the horizon, a point for each prayer.
  schedule,

  /// Footsteps: following the Prophet's way.
  sunnah,

  /// A compass needle pointing at the Kaaba.
  qibla,

  /// Rising bars topped with small arches.
  stats,

  /// A gear made from the eight-pointed star.
  settings,

  /// Prayer beads, for dhikr and azkar. Drawn by [TasbihIcon].
  tasbih,
}

/// Draws a [WirdGlyph] like an [Icon].
class WirdGlyphIcon extends StatelessWidget {
  final WirdGlyph glyph;
  final double size;
  final Color? color;

  const WirdGlyphIcon(this.glyph, {super.key, this.size = 24, this.color});

  static const _stroke =
      'stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"';
  static const _fill = 'fill="#fff"';
  static const _arch =
      'M7 21V11.5c0-3.2 2.6-4.6 3.8-5.7C11.6 5 12 4.1 12 3c0 1.1.4 2 1.2 2.8C14.4 6.9 17 8.3 17 11.5V21';

  static String _svg(String body) => '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">$body</svg>';

  static final Map<WirdGlyph, String> _art = {
    WirdGlyph.home: _svg('<path d="$_arch" $_stroke/><path d="M4 21h16" $_stroke/>'),
    WirdGlyph.quran: _svg(
      '<path d="M3.5 6.5c3-1.2 5.8-.9 8.5 1 2.7-1.9 5.5-2.2 8.5-1V15c-3-1.1-5.8-.8-8.5 1-2.7-1.8-5.5-2.1-8.5-1z" $_stroke/>'
      '<path d="M12 7.5V16" $_stroke/><path d="M6.5 16.5 17.5 21.5M17.5 16.5 6.5 21.5" $_stroke/>',
    ),
    WirdGlyph.schedule: _svg(
      '<path d="M3 18h18" $_stroke/>'
      // A faint solid arc: dashes this fine vanish at tab-bar size.
      '<path d="M4.5 18a7.5 7.5 0 0 1 15 0" $_stroke stroke-width="1.2" stroke-opacity=".55"/>'
      '<circle cx="4.95" cy="15.43" r="1.6" $_fill/><circle cx="8.25" cy="11.5" r="1.6" $_fill/>'
      '<circle cx="12" cy="10.5" r="2.3" $_fill/><circle cx="16.82" cy="12.25" r="1.6" $_fill/>'
      '<circle cx="19.05" cy="15.43" r="1.6" $_fill/>',
    ),
    WirdGlyph.sunnah: _svg(
      '<path d="M8.4 15.6c-2 .2-3.4-1.6-3.4-4.3S6.4 6 8.4 6s3 2 2.8 4.7c-.2 2.7-.9 4.7-2.8 4.9z" $_stroke/>'
      '<path d="M6.3 18.2c.6 1.4 2.3 1.7 3.1.6" $_stroke/>'
      '<path d="M15.6 12.6c2 .2 3.4-1.6 3.4-4.3S17.6 3 15.6 3s-3 2-2.8 4.7c.2 2.7.9 4.7 2.8 4.9z" $_stroke/>'
      '<path d="M17.7 15.2c-.6 1.4-2.3 1.7-3.1.6" $_stroke/>',
    ),
    WirdGlyph.qibla: _svg(
      '<circle cx="12" cy="12" r="8.5" $_stroke/><path d="M12 12 14.6 8.2" $_stroke/>'
      '<rect x="13.9" y="3.6" width="5" height="5" rx=".6" $_fill/>'
      '<circle cx="12" cy="12" r="1.4" $_fill/>',
    ),
    WirdGlyph.stats: _svg(
      '<path d="M4 21h16" $_stroke/>'
      '<path d="M4.2 21v-4.5c0-1 .9-1.5 1.8-2.4.9.9 1.8 1.4 1.8 2.4V21" $_stroke/>'
      '<path d="M10.2 21v-8.5c0-1 .9-1.5 1.8-2.4.9.9 1.8 1.4 1.8 2.4V21" $_stroke/>'
      '<path d="M16.2 21V7.5c0-1 .9-1.5 1.8-2.4.9.9 1.8 1.4 1.8 2.4V21" $_stroke/>',
    ),
    WirdGlyph.settings: _svg(
      '<rect x="5.7" y="5.7" width="12.6" height="12.6" rx="1" $_stroke/>'
      '<rect x="5.7" y="5.7" width="12.6" height="12.6" rx="1" $_stroke transform="rotate(45 12 12)"/>'
      '<circle cx="12" cy="12" r="2.6" $_stroke/>',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final c = _iconColor(context, color);
    if (glyph == WirdGlyph.tasbih) return TasbihIcon(size: size, color: c);
    return SvgPicture.string(
      _art[glyph]!,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}
