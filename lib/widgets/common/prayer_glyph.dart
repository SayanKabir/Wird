import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/device_profile.dart';
import '../../models/prayer.dart';

/// A hand-drawn icon for each prayer, following the sun and moon through the
/// day: stars over Tahajjud, the sun breaking the horizon at Fajr, rising at
/// Ishraq, climbing through Duha and Dhuhr, behind a cloud at Asr, setting at
/// Maghrib, and a crescent at Isha. Jumuah gets a mosque.
///
/// Drawn on a canvas in one colour, so it takes the card's tint like a normal
/// [Icon]; [PrayerGlyph.colored] draws the same scenes in the app icon's
/// colours, with a little more detail. Pass [animate] for the current prayer: the glyph then breathes in a
/// slow three-second loop (stars twinkle, rays turn, the sun rises or sinks a
/// little). Everything else draws a single still frame, and the loop never
/// runs when the system's "Remove animations" is on.
class PrayerGlyph extends StatefulWidget {
  final Prayer prayer;

  /// Used to swap Dhuhr for Jumuah on Fridays. Null means "not Friday".
  final DateTime? date;
  final double size;
  final Color color;
  final bool animate;

  /// Full colour instead of [color]; see [PrayerGlyph.colored].
  final bool colored;

  const PrayerGlyph({
    super.key,
    required this.prayer,
    this.date,
    this.size = 24,
    required this.color,
    this.animate = false,
  }) : colored = false;

  /// Gold suns, a blue-lit moon, a shaded cloud and soft hills, in the
  /// colours of the home screen icon. Sits well on a [prayerSky] disc.
  const PrayerGlyph.colored({
    super.key,
    required this.prayer,
    this.date,
    this.size = 24,
    this.animate = false,
  })  : color = Colors.white,
        colored = true;

  @override
  State<PrayerGlyph> createState() => _PrayerGlyphState();
}

enum _Glyph { tahajjud, fajr, ishraq, duha, dhuhr, jumuah, asr, maghrib, isha }

/// The prayer's sky, top to bottom, for the disc behind a colored glyph.
/// The fard prayers use the home screen icon's skies (gen_icons.py).
List<Color> prayerSky(Prayer prayer, [DateTime? date]) => switch (_glyphFor(prayer, date)) {
      _Glyph.tahajjud => const [Color(0xFF0B1028), Color(0xFF1A1F4A)],
      _Glyph.fajr => const [Color(0xFF4A2C6A), Color(0xFFFFB88C)],
      _Glyph.ishraq => const [Color(0xFFC96A8A), Color(0xFFFFD9A0)],
      _Glyph.duha => const [Color(0xFF2E6FB7), Color(0xFF9ED8EA)],
      _Glyph.dhuhr || _Glyph.jumuah => const [Color(0xFF1E5799), Color(0xFF3498B8)],
      _Glyph.asr => const [Color(0xFFC2410C), Color(0xFFF8B54C)],
      _Glyph.maghrib => const [Color(0xFF8E44AD), Color(0xFFFF8A5C)],
      _Glyph.isha => const [Color(0xFF10122C), Color(0xFF0F3460)],
    };

_Glyph _glyphFor(Prayer prayer, DateTime? date) {
  switch (prayer) {
    case Prayer.tahajjud:
      return _Glyph.tahajjud;
    case Prayer.fajr:
      return _Glyph.fajr;
    case Prayer.ishraq:
      return _Glyph.ishraq;
    case Prayer.duha:
      return _Glyph.duha;
    case Prayer.dhuhr:
      return date?.weekday == DateTime.friday ? _Glyph.jumuah : _Glyph.dhuhr;
    case Prayer.asr:
      return _Glyph.asr;
    case Prayer.maghrib:
      return _Glyph.maghrib;
    case Prayer.isha:
      return _Glyph.isha;
  }
}

class _PrayerGlyphState extends State<PrayerGlyph> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PrayerGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _sync();
  }

  void _sync() {
    if (widget.animate && !motionStill()) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
      // Rest on the frame that reads best as a still icon.
      _loop.value = 0.25;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: widget.colored
            ? _ColorGlyphPainter(glyph: _glyphFor(widget.prayer, widget.date), t: _loop)
            : _GlyphPainter(
                glyph: _glyphFor(widget.prayer, widget.date),
                color: widget.color,
                t: _loop,
              ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  final _Glyph glyph;
  final Color color;
  final Animation<double> t;

  _GlyphPainter({required this.glyph, required this.color, required this.t}) : super(repaint: t);

  /// 0..1..0 over the loop, smooth at the seam.
  double get _wave => 0.5 - 0.5 * math.cos(2 * math.pi * t.value);

  /// The same wave, a third of a loop later.
  double get _wave2 => 0.5 - 0.5 * math.cos(2 * math.pi * (t.value + 0.33));

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    Offset p(double x, double y) => Offset(x * s, y * s);

    switch (glyph) {
      case _Glyph.tahajjud:
        _crescent(canvas, p(0.42, 0.56), s * 0.3, fill);
        _sparkle(canvas, p(0.76, 0.26), s * (0.09 + 0.07 * _wave), fill, 0.2 + 0.8 * _wave);
        _sparkle(canvas, p(0.84, 0.62), s * (0.05 + 0.05 * _wave2), fill, 0.2 + 0.8 * _wave2);

      case _Glyph.fajr:
        const horizon = 0.72;
        final rise = 0.1 * _wave;
        // Half the sun shows above the horizon, with a gap at the line.
        final sun = p(0.5, horizon - 0.06 - rise);
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, 0, s, (horizon - 0.08) * s));
        canvas.drawCircle(sun, s * 0.2, stroke);
        canvas.restore();
        _rays(canvas, sun, s * 0.29, s * (0.03 + 0.09 * _wave), stroke,
            count: 5, from: -165, to: -15);
        canvas.drawLine(p(0.1, horizon), p(0.9, horizon), stroke);

      case _Glyph.ishraq:
        final lift = 0.08 * _wave;
        // Fully risen, clear of the horizon; rays only fan upward.
        canvas.drawCircle(p(0.5, 0.52 - lift), s * 0.16, stroke);
        _rays(canvas, p(0.5, 0.52 - lift), s * 0.25, s * (0.03 + 0.08 * _wave), stroke,
            count: 5, from: -180, to: 0);
        canvas.drawLine(p(0.14, 0.86), p(0.86, 0.86), stroke);

      case _Glyph.duha:
        canvas.drawCircle(p(0.5, 0.5), s * 0.17, stroke);
        _rays(canvas, p(0.5, 0.5), s * 0.27, s * (0.05 + 0.07 * _wave), stroke,
            count: 8, from: 0, to: 315, rotate: t.value * 45);

      case _Glyph.dhuhr:
        canvas.drawCircle(p(0.5, 0.5), s * 0.18, fill);
        _rays(canvas, p(0.5, 0.5), s * 0.28, s * (0.07 + 0.08 * _wave), stroke,
            count: 8, from: 0, to: 315, rotate: t.value * 45);

      case _Glyph.asr:
        // The cloud sits in front of the sun, so it is cut out of the sun
        // before its own outline is drawn: all inside one layer, so the cut
        // never punches through to the card behind.
        final drift = s * 0.16 * (_wave - 0.5);
        canvas.saveLayer(Offset.zero & size, Paint());
        canvas.drawCircle(p(0.62, 0.36), s * 0.15, stroke);
        _rays(canvas, p(0.62, 0.36), s * 0.24, s * 0.08, stroke, count: 5, from: -180, to: 0);
        final cloud = _cloud(Offset(s * 0.44 + drift, s * 0.84), s * 0.62);
        canvas.drawPath(
          cloud,
          Paint()
            ..blendMode = BlendMode.clear
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke.strokeWidth * 2.2,
        );
        canvas.drawPath(cloud, Paint()..blendMode = BlendMode.clear);
        canvas.drawPath(cloud, stroke);
        canvas.restore();

      case _Glyph.maghrib:
        const horizon = 0.6;
        final sink = 0.11 * _wave;
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, 0, s, (horizon - 0.08) * s));
        canvas.drawCircle(p(0.5, horizon - 0.1 + sink), s * 0.22, stroke);
        canvas.restore();
        canvas.drawLine(p(0.1, horizon), p(0.9, horizon), stroke);
        // Light on water, fading out as it goes down.
        canvas.drawLine(p(0.3, 0.75), p(0.7, 0.75), stroke..color = color.withValues(alpha: 0.7));
        canvas.drawLine(p(0.4, 0.88), p(0.6, 0.88), stroke..color = color.withValues(alpha: 0.4));

      case _Glyph.isha:
        // The crescent rocks gently while its star twinkles.
        canvas.save();
        canvas.translate(0.46 * s, 0.52 * s);
        canvas.rotate((_wave - 0.5) * 0.22);
        canvas.translate(-0.46 * s, -0.52 * s);
        _crescent(canvas, p(0.46, 0.52), s * 0.34, fill);
        canvas.restore();
        _sparkle(canvas, p(0.78, 0.3), s * (0.07 + 0.07 * _wave2), fill, 0.2 + 0.8 * _wave2);

      case _Glyph.jumuah:
        // Dome on a base, with a crescent finial that catches the light.
        final dome = Rect.fromCircle(center: p(0.5, 0.58), radius: s * 0.26);
        canvas.drawArc(dome, math.pi, math.pi, false, stroke);
        canvas.drawLine(p(0.2, 0.58), p(0.2, 0.86), stroke);
        canvas.drawLine(p(0.8, 0.58), p(0.8, 0.86), stroke);
        canvas.drawLine(p(0.14, 0.86), p(0.86, 0.86), stroke);
        canvas.drawLine(p(0.5, 0.32), p(0.5, 0.24), stroke);
        _crescent(canvas, p(0.5, 0.14), s * 0.08,
            Paint()..color = color.withValues(alpha: 0.3 + 0.7 * _wave));
        // Door.
        final door = Path()
          ..moveTo(0.42 * s, 0.86 * s)
          ..lineTo(0.42 * s, 0.73 * s)
          ..arcToPoint(p(0.58, 0.73), radius: Radius.circular(s * 0.08))
          ..lineTo(0.58 * s, 0.86 * s);
        canvas.drawPath(door, stroke);
    }
  }

  /// Short rays around [c], spread evenly between the angles (degrees, 0 is
  /// to the right, negative is up). [rotate] turns the whole set.
  void _rays(Canvas canvas, Offset c, double inner, double length, Paint paint,
      {required int count, required double from, required double to, double rotate = 0}) {
    for (var i = 0; i < count; i++) {
      final deg = from + (count == 1 ? 0 : (to - from) * i / (count - 1)) + rotate;
      final a = deg * math.pi / 180;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * inner, c + dir * (inner + length), paint);
    }
  }

  /// A crescent opening to the upper right.
  void _crescent(Canvas canvas, Offset c, double r, Paint paint) {
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(center: c + Offset(r * 0.45, -r * 0.35), radius: r * 0.85));
    canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), paint);
  }

  /// A four-pointed sparkle.
  void _sparkle(Canvas canvas, Offset c, double r, Paint paint, double opacity) {
    final w = r * 0.28;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + w * 0.4, c.dy - w * 0.4, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + w * 0.4, c.dy + w * 0.4, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - w * 0.4, c.dy + w * 0.4, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - w * 0.4, c.dy - w * 0.4, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = paint.color.withValues(alpha: paint.color.a * opacity));
  }

  /// A cloud [w] wide, its flat base centred on [base].
  Path _cloud(Offset base, double w) {
    final h = w * 0.55;
    final left = base.dx - w / 2;
    final top = base.dy - h;
    final circles = [
      Rect.fromCircle(center: Offset(left + w * 0.28, top + h * 0.62), radius: h * 0.38),
      Rect.fromCircle(center: Offset(left + w * 0.56, top + h * 0.42), radius: h * 0.5),
      Rect.fromCircle(center: Offset(left + w * 0.8, top + h * 0.68), radius: h * 0.32),
    ];
    var path = Path()
      ..addRRect(RRect.fromLTRBR(left + w * 0.06, top + h * 0.55, left + w * 0.98, base.dy, Radius.circular(h * 0.45)));
    for (final r in circles) {
      path = Path.combine(PathOperation.union, path, Path()..addOval(r));
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.glyph != glyph || old.color != color || old.t != t;
}

/// The same scenes as [_GlyphPainter], in colour: suns filled with a warm
/// gradient and a glow, gold rays, a cream horizon over soft hills, a
/// shaded cloud, a moon lit blue, and gold stars.
class _ColorGlyphPainter extends _GlyphPainter {
  _ColorGlyphPainter({required super.glyph, required super.t}) : super(color: Colors.white);

  static const _gold = Color(0xFFF6C964);
  static const _cream = Color(0xFFFFF4D6);
  static const _star = Color(0xFFFBE3A4);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    Paint line(Color c, [double w = 0.075]) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint glow(Color c, double alpha, [double blur = 0.1]) => Paint()
      ..color = c.withValues(alpha: alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * blur);
    // A sun with a hot centre fading to [edge].
    void sun(Offset c, double r, Color edge) => canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = RadialGradient(
              colors: [const Color(0xFFFFFDF2), edge],
              stops: const [0.25, 1],
            ).createShader(Rect.fromCircle(center: c, radius: r)),
        );
    void hill(double y, double peak, Color c) => canvas.drawPath(
          Path()
            ..moveTo(0.08 * s, (y + 0.06) * s)
            ..quadraticBezierTo(0.5 * s, (y - peak) * s, 0.92 * s, (y + 0.06) * s)
            ..close(),
          Paint()..color = c,
        );
    void crescent(Offset c, double r, double tilt) {
      canvas.drawCircle(c, r * 1.5, glow(const Color(0xFF9DB4FF), 0.35, 0.12));
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(tilt);
      canvas.translate(-c.dx, -c.dy);
      _crescent(canvas, c, r, Paint()..color = _cream);
      canvas.restore();
    }

    switch (glyph) {
      case _Glyph.tahajjud:
        crescent(p(0.42, 0.56), s * 0.29, (_wave - 0.5) * 0.15);
        _sparkle(canvas, p(0.76, 0.26), s * (0.09 + 0.06 * _wave), Paint()..color = _star, 0.35 + 0.65 * _wave);
        _sparkle(canvas, p(0.84, 0.62), s * (0.05 + 0.04 * _wave2), Paint()..color = _star, 0.35 + 0.65 * _wave2);
        canvas.drawCircle(p(0.2, 0.24), s * 0.022, Paint()..color = Colors.white.withValues(alpha: 0.7));
        canvas.drawCircle(p(0.68, 0.86), s * 0.018, Paint()..color = Colors.white.withValues(alpha: 0.5));

      case _Glyph.fajr:
        const horizon = 0.7;
        final rise = 0.08 * _wave;
        canvas.drawOval(Rect.fromCenter(center: p(0.5, horizon), width: s * 0.95, height: s * 0.4),
            glow(const Color(0xFFFFB88C), 0.55 + 0.25 * _wave));
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, 0, s, (horizon - 0.04) * s));
        sun(p(0.5, horizon - rise), s * 0.21, const Color(0xFFFF9E6B));
        canvas.restore();
        _rays(canvas, p(0.5, horizon - rise), s * 0.29, s * (0.04 + 0.07 * _wave),
            line(const Color(0xFFFFC48A), 0.065), count: 5, from: -165, to: -15);
        canvas.drawLine(p(0.08, horizon), p(0.92, horizon), line(_cream));
        canvas.drawLine(p(0.26, 0.84), p(0.74, 0.84), line(const Color(0xFFB19CD9), 0.06));

      case _Glyph.ishraq:
        final lift = 0.07 * _wave;
        final c = p(0.5, 0.5 - lift);
        canvas.drawCircle(c, s * 0.3, glow(const Color(0xFFFFD9A0), 0.5));
        sun(c, s * 0.17, const Color(0xFFFFB25C));
        _rays(canvas, c, s * 0.25, s * (0.04 + 0.06 * _wave), line(_gold, 0.065),
            count: 5, from: -180, to: 0);
        hill(0.8, 0.1, const Color(0xFFF6A766).withValues(alpha: 0.75));
        canvas.drawLine(p(0.12, 0.8), p(0.88, 0.8), line(_cream, 0.06));

      case _Glyph.duha:
        final c = p(0.56, 0.42);
        canvas.drawCircle(c, s * 0.3, glow(const Color(0xFFFFE7A0), 0.5));
        sun(c, s * 0.16, const Color(0xFFFFC94A));
        _rays(canvas, c, s * 0.24, s * (0.05 + 0.05 * _wave), line(_gold, 0.065),
            count: 8, from: 0, to: 315, rotate: t.value * 45);
        _paintCloud(canvas, Offset(s * 0.36, s * 0.86), s * 0.46);

      case _Glyph.dhuhr:
        final c = p(0.5, 0.5);
        canvas.drawCircle(c, s * 0.34, glow(const Color(0xFFFFE7A0), 0.45 + 0.2 * _wave));
        sun(c, s * 0.19, const Color(0xFFFFCF3F));
        // Long and short rays in turn.
        _rays(canvas, c, s * 0.27, s * (0.08 + 0.06 * _wave), line(_gold, 0.07),
            count: 4, from: 0, to: 270, rotate: t.value * 45);
        _rays(canvas, c, s * 0.27, s * (0.04 + 0.03 * _wave), line(_gold, 0.06),
            count: 4, from: 45, to: 315, rotate: t.value * 45);

      case _Glyph.jumuah:
        canvas.drawCircle(p(0.5, 0.56), s * 0.36, glow(const Color(0xFFFFE7A0), 0.35));
        final goldFill = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE7A8), Color(0xFFE2A23E)],
          ).createShader(Rect.fromLTRB(0, 0.3 * s, s, 0.88 * s));
        final mosque = Path()
          ..addArc(Rect.fromCircle(center: p(0.5, 0.6), radius: s * 0.24), math.pi, math.pi)
          ..addRect(Rect.fromLTRB(0.26 * s, 0.6 * s, 0.74 * s, 0.86 * s))
          ..addRect(Rect.fromLTRB(0.12 * s, 0.46 * s, 0.19 * s, 0.86 * s))
          ..addRect(Rect.fromLTRB(0.81 * s, 0.46 * s, 0.88 * s, 0.86 * s));
        final door = Path()
          ..moveTo(0.43 * s, 0.86 * s)
          ..lineTo(0.43 * s, 0.74 * s)
          ..arcToPoint(p(0.57, 0.74), radius: Radius.circular(s * 0.07))
          ..lineTo(0.57 * s, 0.86 * s)
          ..close();
        canvas.drawPath(Path.combine(PathOperation.difference, mosque, door), goldFill);
        canvas.drawLine(p(0.5, 0.36), p(0.5, 0.27), line(_gold, 0.05));
        _crescent(canvas, p(0.5, 0.18), s * 0.075,
            Paint()..color = _cream.withValues(alpha: 0.4 + 0.6 * _wave));

      case _Glyph.asr:
        final c = p(0.63, 0.36);
        canvas.drawCircle(c, s * 0.28, glow(const Color(0xFFFFB347), 0.5));
        sun(c, s * 0.16, const Color(0xFFF59E2B));
        _rays(canvas, c, s * 0.24, s * 0.07, line(const Color(0xFFFFB347), 0.065),
            count: 5, from: -180, to: 0);
        _paintCloud(canvas, Offset(s * 0.44 + s * 0.12 * (_wave - 0.5), s * 0.86), s * 0.64);

      case _Glyph.maghrib:
        const horizon = 0.6;
        final sink = 0.09 * _wave;
        canvas.drawOval(Rect.fromCenter(center: p(0.5, horizon), width: s * 0.95, height: s * 0.45),
            glow(const Color(0xFFFF8A5C), 0.5));
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, 0, s, (horizon - 0.04) * s));
        final c = p(0.5, horizon - 0.08 + sink);
        canvas.drawCircle(
          c,
          s * 0.23,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE2A8), Color(0xFFFF6B6B)],
            ).createShader(Rect.fromCircle(center: c, radius: s * 0.23)),
        );
        canvas.restore();
        canvas.drawLine(p(0.08, horizon), p(0.92, horizon), line(const Color(0xFFFFC9A0)));
        // Light on water, fading as it goes down.
        canvas.drawLine(p(0.28, 0.74), p(0.72, 0.74), line(const Color(0xFFFF8A5C).withValues(alpha: 0.85), 0.065));
        canvas.drawLine(p(0.38, 0.86), p(0.62, 0.86), line(const Color(0xFFE55D87).withValues(alpha: 0.6), 0.06));

      case _Glyph.isha:
        crescent(p(0.46, 0.52), s * 0.33, (_wave - 0.5) * 0.22);
        _sparkle(canvas, p(0.8, 0.28), s * (0.07 + 0.06 * _wave2), Paint()..color = _star, 0.35 + 0.65 * _wave2);
        canvas.drawCircle(p(0.22, 0.2), s * 0.02, Paint()..color = Colors.white.withValues(alpha: 0.6));
        canvas.drawCircle(p(0.82, 0.74), s * 0.018, Paint()..color = Colors.white.withValues(alpha: 0.45));
    }
  }

  /// A soft white cloud, shaded warm underneath.
  void _paintCloud(Canvas canvas, Offset base, double w) {
    final path = _cloud(base, w);
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF3DCC2)],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant _ColorGlyphPainter old) => old.glyph != glyph || old.t != t;
}
