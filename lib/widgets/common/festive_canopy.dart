import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/services/device_profile.dart';

/// Which light the lanterns give off.
enum CanopyMood {
  /// Eid and Arafah: amber, teal and rose glass.
  celebration,

  /// Ramadan nights: moonlit blue, lavender and a little gold.
  night,
}

/// A festive canopy for the top of a screen on the year's great days: two
/// gold garlands of eight-pointed stars, and five lanterns (fanous) hanging
/// at different lengths, swaying a little, their glass glowing and the flame
/// inside flickering.
///
/// Size it with a [Positioned] or [SizedBox]; it never takes touches. With
/// "Remove animations" on it draws one still frame.
class FestiveCanopy extends StatefulWidget {
  final CanopyMood mood;

  /// Where the canopy starts, as a share of the width. Above a page header,
  /// pass about a third so the back button and title stay clear; the
  /// lanterns then hang shorter too.
  final double start;

  /// Draw the two garlands. The app-wide sky leaves them out and lets the
  /// lanterns hang on their own.
  final bool garlands;

  /// Stars scattered across the whole area, twinkling. The sky uses these.
  final int skyStars;

  /// Gold bursts going off in the upper sky, for Eid and Arafah.
  final bool bursts;

  /// Height the lantern cords are measured against. Defaults to the
  /// widget's own height; the full-screen sky sets it to its top band.
  final double? dropHeight;

  /// How much attention the canopy takes, 0 to 1. At 1 it spans the width
  /// with garlands and long cords; towards 0 it shrinks into small, short
  /// lanterns from [start] onward, garlands fading out. Follow a page
  /// position with it to move smoothly between the two. Null keeps the
  /// canopy as configured.
  final ValueListenable<double>? focus;

  const FestiveCanopy({
    super.key,
    this.mood = CanopyMood.celebration,
    this.start = 0,
    this.garlands = true,
    this.skyStars = 0,
    this.bursts = false,
    this.dropHeight,
    this.focus,
  });

  @override
  State<FestiveCanopy> createState() => _FestiveCanopyState();
}

class _FestiveCanopyState extends State<FestiveCanopy> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void initState() {
    super.initState();
    if (motionStill()) {
      _loop.value = 0.2;
    } else {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CanopyPainter(
            mood: widget.mood,
            start: widget.start,
            garlands: widget.garlands,
            skyStars: widget.skyStars,
            bursts: widget.bursts,
            dropHeight: widget.dropHeight,
            focus: widget.focus,
            t: _loop,
          ),
        ),
      ),
    );
  }
}

class _Lantern {
  /// Across the width, 0..1.
  final double x;

  /// Cord length as a share of the canopy's height.
  final double drop;
  final double scale;
  final double phase;

  const _Lantern(this.x, this.drop, this.scale, this.phase);
}

class _CanopyPainter extends CustomPainter {
  final CanopyMood mood;
  final double start;
  final bool garlands;
  final int skyStars;
  final bool bursts;
  final double? dropHeight;
  final ValueListenable<double>? focus;
  final Animation<double> t;

  _CanopyPainter({
    required this.mood,
    required this.start,
    required this.garlands,
    required this.skyStars,
    required this.bursts,
    required this.dropHeight,
    this.focus,
    required this.t,
  }) : super(repaint: focus == null ? t : Listenable.merge([t, focus]));

  static const _gold = Color(0xFFE9B95A);
  static const _goldLight = Color(0xFFFFE7A8);

  static const _lanterns = [
    _Lantern(0.1, 0.36, 0.78, 0.0),
    _Lantern(0.29, 0.6, 0.9, 0.35),
    _Lantern(0.5, 0.8, 1.12, 0.7),
    _Lantern(0.71, 0.56, 0.9, 0.2),
    _Lantern(0.9, 0.34, 0.78, 0.55),
  ];

  List<Color> get _glass => switch (mood) {
        CanopyMood.celebration => const [Color(0xFFFFB347), Color(0xFF4FD1C5), Color(0xFFFF7A90)],
        CanopyMood.night => const [Color(0xFF9DB4FF), Color(0xFFFFD27D), Color(0xFFB19CD9)],
      };

  double _wave(double phase, [double speed = 1]) => math.sin(2 * math.pi * (t.value * speed + phase));

  @override
  void paint(Canvas canvas, Size size) {
    if (skyStars > 0) _starField(canvas, size);
    if (bursts) _bursts(canvas, size);

    // Full canopy at focus 1, compact beside the titles at 0.
    final f = focus == null ? null : Curves.easeInOut.transform(focus!.value.clamp(0.0, 1.0));
    final from = f == null ? start : start * (1 - f);
    final left = from * size.width;
    final w = size.width - left;
    final h = dropHeight ?? size.height;
    // Shorter drops and smaller lanterns when tucked beside a header.
    final reach = f == null ? (start > 0 ? 0.55 : 1.0) : 0.45 + 0.55 * f;
    final shrink = f == null ? (start > 0 ? 0.85 : 1.0) : 0.7 + 0.3 * f;
    final garlandAlpha = f ?? 1.0;

    canvas.save();
    canvas.translate(left, 0);
    // Garlands sit behind the lanterns.
    if (garlands && garlandAlpha > 0.02) {
      final fading = garlandAlpha < 0.98;
      if (fading) {
        canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: garlandAlpha));
      }
      _garland(canvas, w, h, top: h * 0.02, sag: h * 0.36 * reach, stars: 9, phase: 0, fromEdge: from == 0);
      _garland(canvas, w, h, top: -h * 0.04, sag: h * 0.58 * reach, stars: 11, phase: 0.5, fromEdge: from == 0);
      if (fading) canvas.restore();
    }

    final unit = math.min(size.width * 0.065, h * 0.2) * shrink;
    for (var i = 0; i < _lanterns.length; i++) {
      final l = _lanterns[i];
      _lantern(canvas, Offset(l.x * w, 0), l.drop * h * reach, unit * l.scale, _glass[i % _glass.length],
          l.phase, crowned: i == 2);
    }
    canvas.restore();
  }

  /// Small gold stars scattered over the whole area, each on its own
  /// twinkle. Positions come from a fixed seed so they never jump.
  void _starField(Canvas canvas, Size size) {
    final rng = math.Random(7);
    for (var i = 0; i < skyStars; i++) {
      final p = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height * 0.75);
      final r = 1.6 + rng.nextDouble() * 2.2;
      final twinkle = 0.5 + 0.5 * _wave(rng.nextDouble(), 1 + rng.nextInt(2).toDouble());
      if (r > 3) {
        _khatim(canvas, p, r * (0.8 + 0.3 * twinkle),
            Paint()..color = _goldLight.withValues(alpha: 0.25 + 0.6 * twinkle));
      } else {
        canvas.drawCircle(p, r * 0.5, Paint()..color = Colors.white.withValues(alpha: 0.2 + 0.6 * twinkle));
      }
    }
  }

  /// Three gold bursts taking turns in the upper sky: rays fly out from a
  /// point, sparks at their tips, and fade.
  void _bursts(Canvas canvas, Size size) {
    // Up among the lanterns and out to the sides, clear of centred text.
    const spots = [Offset(0.84, 0.25), Offset(0.15, 0.3), Offset(0.68, 0.1)];
    for (var i = 0; i < spots.length; i++) {
      // Each burst lives for the first 40% of its own third of the loop.
      final local = (t.value * 1.5 + i / spots.length) % 1.0;
      if (local > 0.4) continue;
      final k = local / 0.4;
      final ease = 1 - math.pow(1 - k, 3).toDouble();
      final fade = (1 - k).clamp(0.0, 1.0);
      final c = Offset(spots[i].dx * size.width, spots[i].dy * size.height);
      final radius = size.width * 0.13 * ease;
      canvas.drawCircle(
        c,
        radius * 1.2,
        Paint()
          ..color = _goldLight.withValues(alpha: 0.12 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      const rays = 14;
      for (var r = 0; r < rays; r++) {
        final a = 2 * math.pi * r / rays + i;
        final dir = Offset(math.cos(a), math.sin(a));
        final tip = c + dir * radius + Offset(0, 6 * k * k);
        canvas.drawLine(
          c + dir * radius * 0.55,
          tip,
          Paint()
            ..color = Color.lerp(_goldLight, _gold, k)!.withValues(alpha: 0.85 * fade)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(tip, 1.8 * fade + 0.4, Paint()..color = _goldLight.withValues(alpha: fade));
      }
    }
  }

  /// A gold cord hanging between the edges, strung with stars and beads.
  void _garland(Canvas canvas, double w, double h,
      {required double top,
      required double sag,
      required int stars,
      required double phase,
      bool fromEdge = true}) {
    // Off the screen's edge, or tied to a point when the canopy starts inset.
    final startX = fromEdge ? -12.0 : 0.0;
    final endX = w + 12;
    Offset at(double u) {
      final x = startX + (endX - startX) * u;
      final y = (1 - u) * (1 - u) * top + 2 * (1 - u) * u * (top + sag * 2) + u * u * top;
      return Offset(x, y);
    }

    final cord = Path()..moveTo(startX, top);
    cord.quadraticBezierTo((startX + endX) / 2, top + sag * 2, endX, top);
    canvas.drawPath(
      cord,
      Paint()
        ..color = _gold.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    for (var i = 1; i < stars * 2; i++) {
      final u = i / (stars * 2);
      final p = at(u);
      if (i.isOdd) {
        // Beads between the stars.
        canvas.drawCircle(p, 1.4, Paint()..color = _goldLight.withValues(alpha: 0.7));
        continue;
      }
      final twinkle = 0.5 + 0.5 * _wave(phase + i * 0.17, 2);
      final r = 3.6 + 1.2 * twinkle;
      canvas.drawCircle(
        p,
        r * 2.6,
        Paint()
          ..color = _goldLight.withValues(alpha: 0.18 + 0.25 * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      _khatim(canvas, p, r, Paint()..color = Color.lerp(_gold, _goldLight, twinkle)!);
    }
  }

  /// An eight-pointed star: two squares, one turned 45 degrees.
  void _khatim(Canvas canvas, Offset c, double r, Paint paint) {
    for (final turn in const [0.0, math.pi / 4]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(turn);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 1.42, height: r * 1.42), paint);
      canvas.restore();
    }
  }

  /// A fanous on a cord from [anchor], [drop] long, about [u] wide.
  void _lantern(Canvas canvas, Offset anchor, double drop, double u, Color glass, double phase,
      {bool crowned = false}) {
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    // Swing from the anchor like a pendulum.
    canvas.rotate(0.05 * _wave(phase));

    canvas.drawLine(
      Offset.zero,
      Offset(0, drop),
      Paint()
        ..color = _gold.withValues(alpha: 0.6)
        ..strokeWidth = 1,
    );
    canvas.translate(0, drop);

    final flicker = 0.75 + 0.25 * (0.5 + 0.5 * _wave(phase * 3 + 0.1, 5) * _wave(phase + 0.4, 3));
    final bodyTop = u * 0.55;
    final bodyBottom = u * 2.05;
    final mid = (bodyTop + bodyBottom) / 2;

    // Light thrown around the lantern.
    canvas.drawCircle(
      Offset(0, mid),
      u * 1.9,
      Paint()
        ..color = glass.withValues(alpha: 0.28 * flicker)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.9),
    );

    final goldFill = Paint()
      ..shader = const LinearGradient(colors: [_goldLight, _gold, Color(0xFFB9772A)])
          .createShader(Rect.fromLTRB(-u * 0.6, 0, u * 0.6, u * 2.6));

    // Hanging ring, then the domed cap.
    canvas.drawCircle(
      Offset(0, u * 0.06),
      u * 0.09,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.05,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-u * 0.36, bodyTop)
        ..quadraticBezierTo(-u * 0.32, u * 0.18, 0, u * 0.14)
        ..quadraticBezierTo(u * 0.32, u * 0.18, u * 0.36, bodyTop)
        ..close(),
      goldFill,
    );
    if (crowned) {
      // A small crescent above the middle lantern.
      final c = Offset(0, -u * 0.25);
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: u * 0.2)),
        Path()..addOval(Rect.fromCircle(center: c + Offset(u * 0.09, -u * 0.06), radius: u * 0.17)),
      );
      canvas.drawPath(moon, Paint()..color = _goldLight);
    }

    // The glass body: narrow at the ends, full in the middle.
    final body = Path()
      ..moveTo(-u * 0.32, bodyTop)
      ..quadraticBezierTo(-u * 0.62, mid, -u * 0.32, bodyBottom)
      ..lineTo(u * 0.32, bodyBottom)
      ..quadraticBezierTo(u * 0.62, mid, u * 0.32, bodyTop)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(Colors.white, glass, 0.35)!.withValues(alpha: 0.95),
            glass.withValues(alpha: 0.85),
            Color.lerp(glass, Colors.black, 0.45)!.withValues(alpha: 0.9),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: Offset(0, mid), radius: u * 0.75)),
    );
    // The flame.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, mid + u * 0.08), width: u * 0.16, height: u * 0.32 * flicker),
      Paint()
        ..color = const Color(0xFFFFF4D6).withValues(alpha: 0.9 * flicker)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.05),
    );

    // Gold frame: outline and two ribs.
    final frame = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.06
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(body, frame);
    for (final x in [-0.17, 0.17]) {
      canvas.drawPath(
        Path()
          ..moveTo(x * u, bodyTop)
          ..quadraticBezierTo(x * u * 1.7, mid, x * u, bodyBottom),
        frame..strokeWidth = u * 0.035,
      );
    }
    // A band round the waist.
    canvas.drawLine(Offset(-u * 0.47, mid), Offset(u * 0.47, mid), frame..strokeWidth = u * 0.045);

    // Base plate and a teardrop finial.
    canvas.drawPath(
      Path()
        ..moveTo(-u * 0.36, bodyBottom)
        ..lineTo(u * 0.36, bodyBottom)
        ..lineTo(u * 0.16, bodyBottom + u * 0.2)
        ..lineTo(-u * 0.16, bodyBottom + u * 0.2)
        ..close(),
      goldFill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, bodyBottom + u * 0.2)
        ..quadraticBezierTo(u * 0.1, bodyBottom + u * 0.33, 0, bodyBottom + u * 0.45)
        ..quadraticBezierTo(-u * 0.1, bodyBottom + u * 0.33, 0, bodyBottom + u * 0.2),
      goldFill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CanopyPainter old) =>
      old.mood != mood ||
      old.start != start ||
      old.garlands != garlands ||
      old.skyStars != skyStars ||
      old.bursts != bursts ||
      old.dropHeight != dropHeight ||
      old.focus != focus ||
      old.t != t;
}

/// One lantern on a short cord, swaying, for the festive greeting.
class FestiveLantern extends StatefulWidget {
  final Color glass;
  final double size;
  final double phase;

  const FestiveLantern({super.key, required this.glass, this.size = 40, this.phase = 0});

  @override
  State<FestiveLantern> createState() => _FestiveLanternState();
}

class _FestiveLanternState extends State<FestiveLantern> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void initState() {
    super.initState();
    if (motionStill()) {
      _loop.value = 0.2;
    } else {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.size, widget.size * 2.9),
      painter: _OneLanternPainter(glass: widget.glass, phase: widget.phase, t: _loop),
    );
  }
}

class _OneLanternPainter extends _CanopyPainter {
  final Color glass;
  final double phase;

  _OneLanternPainter({required this.glass, required this.phase, required super.t})
      : super(
          mood: CanopyMood.celebration,
          start: 0,
          garlands: false,
          skyStars: 0,
          bursts: false,
          dropHeight: null,
        );

  @override
  void paint(Canvas canvas, Size size) {
    _lantern(canvas, Offset(size.width / 2, 0), size.width * 0.3, size.width, glass, phase);
  }

  @override
  bool shouldRepaint(covariant _OneLanternPainter old) => old.glass != glass || old.t != t;
}

/// A faint lattice of eight-pointed stars, tiled. Used as a quiet festive
/// texture, e.g. inside the tab bar.
class GirihPattern extends StatelessWidget {
  final Color color;
  final double tile;

  const GirihPattern({super.key, this.color = const Color(0x2EE9B95A), this.tile = 22});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(size: Size.infinite, painter: _GirihPainter(color: color, tile: tile)),
    );
  }
}

class _GirihPainter extends CustomPainter {
  final Color color;
  final double tile;

  const _GirihPainter({required this.color, required this.tile});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final r = tile * 0.3;
    for (var y = tile / 2; y < size.height + tile; y += tile) {
      for (var x = tile / 2; x < size.width + tile; x += tile) {
        final c = Offset(x, y);
        for (final turn in const [0.0, math.pi / 4]) {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(turn);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2), paint);
          canvas.restore();
        }
        // Tie each star to its right-hand neighbour.
        canvas.drawLine(c + Offset(r * 1.4, 0), c + Offset(tile - r * 1.4, 0), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GirihPainter old) => old.color != color || old.tile != tile;
}
