import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/device_profile.dart';
import '../../models/prayer.dart';

/// A small version of the app icon for one prayer: that prayer's sky seen
/// through the gold arch, with the sun or moon where it stands at that time.
/// The five fard skies match the home screen icons (assets/icon/gen_icons.py);
/// Tahajjud, Ishraq, Duha and Jumuah get skies of their own in the same style.
///
/// Pass [animate] for the current prayer: the sun climbs or sinks a little,
/// its glow breathes and stars twinkle, in a slow loop that never runs when
/// the system's "Remove animations" is on. Everything else draws one frame.
class PrayerWindow extends StatefulWidget {
  final Prayer prayer;

  /// Used to swap Dhuhr for Jumuah on Fridays. Null means "not Friday".
  final DateTime? date;
  final double size;
  final bool animate;

  const PrayerWindow({
    super.key,
    required this.prayer,
    this.date,
    this.size = 48,
    this.animate = false,
  });

  @override
  State<PrayerWindow> createState() => _PrayerWindowState();
}

class _PrayerWindowState extends State<PrayerWindow> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PrayerWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _sync();
  }

  void _sync() {
    if (widget.animate && !motionStill()) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
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
    final friday = widget.date?.weekday == DateTime.friday;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _WindowPainter(
          scene: _Scene.of(widget.prayer, friday: friday),
          t: _loop,
        ),
      ),
    );
  }
}

enum _Body { dawn, sun, moon, stars }

/// One prayer's sky, in the 1024-unit space the app icon is drawn in.
class _Scene {
  final List<Color> sky;
  final List<double> stops;
  final Color hillFar;
  final Color hillNear;
  final _Body body;

  /// Sun or moon centre and radius.
  final Offset at;
  final double r;

  /// Units the sun moves over the loop: negative climbs, positive sinks.
  final double drift;
  final bool mosque;

  const _Scene({
    required this.sky,
    required this.stops,
    required this.hillFar,
    required this.hillNear,
    required this.body,
    this.at = const Offset(512, 470),
    this.r = 60,
    this.drift = 0,
    this.mosque = false,
  });

  static _Scene of(Prayer prayer, {required bool friday}) => switch (prayer) {
        Prayer.tahajjud => const _Scene(
            sky: [Color(0xFF05060F), Color(0xFF0B1028), Color(0xFF1A1F4A)],
            stops: [0, .6, 1],
            hillFar: Color(0xFF0A0F26),
            hillNear: Color(0xFF05081A),
            body: _Body.stars,
            at: Offset(470, 470),
            r: 64,
          ),
        Prayer.fajr => const _Scene(
            sky: [Color(0xFF2E1A47), Color(0xFF4A2C6A), Color(0xFFFFB88C), Color(0xFFFFD8B0)],
            stops: [0, .45, .82, 1],
            hillFar: Color(0xFF3A2452),
            hillNear: Color(0xFF24163A),
            body: _Body.dawn,
          ),
        Prayer.ishraq => const _Scene(
            sky: [Color(0xFF3B2E6E), Color(0xFFC96A8A), Color(0xFFF6A766), Color(0xFFFFE0A8)],
            stops: [0, .5, .8, 1],
            hillFar: Color(0xFF4A2D55),
            hillNear: Color(0xFF2E1C3B),
            body: _Body.sun,
            at: Offset(512, 690),
            r: 62,
            drift: -40,
          ),
        Prayer.duha => const _Scene(
            sky: [Color(0xFF2E6FB7), Color(0xFF64AEE0), Color(0xFFCDEBF5)],
            stops: [0, .6, 1],
            hillFar: Color(0xFF2D5E8C),
            hillNear: Color(0xFF1D4468),
            body: _Body.sun,
            at: Offset(440, 520),
            r: 52,
            drift: -30,
          ),
        Prayer.dhuhr => _Scene(
            sky: const [Color(0xFF1E5799), Color(0xFF2980B9), Color(0xFF3498B8), Color(0xFF9ED8EA)],
            stops: const [0, .5, .82, 1],
            hillFar: const Color(0xFF1C4A7A),
            hillNear: const Color(0xFF123358),
            body: _Body.sun,
            at: const Offset(512, 400),
            r: 54,
            drift: -20,
            mosque: friday,
          ),
        Prayer.asr => const _Scene(
            sky: [Color(0xFF92400E), Color(0xFFC2410C), Color(0xFFD97706), Color(0xFFF8B54C)],
            stops: [0, .45, .8, 1],
            hillFar: Color(0xFF7A3410),
            hillNear: Color(0xFF56240A),
            body: _Body.sun,
            at: Offset(612, 560),
            r: 48,
            drift: 30,
          ),
        Prayer.maghrib => const _Scene(
            sky: [Color(0xFF2C3E50), Color(0xFF8E44AD), Color(0xFFEE5A24), Color(0xFFFF8A5C)],
            stops: [0, .38, .74, 1],
            hillFar: Color(0xFF5A2A5E),
            hillNear: Color(0xFF3A1B42),
            body: _Body.sun,
            at: Offset(512, 748),
            r: 70,
            drift: 40,
          ),
        Prayer.isha => const _Scene(
            sky: [Color(0xFF10122C), Color(0xFF16213E), Color(0xFF0F3460)],
            stops: [0, .6, 1],
            hillFar: Color(0xFF0E1A38),
            hillNear: Color(0xFF070F24),
            body: _Body.moon,
            at: Offset(512, 470),
            r: 80,
          ),
      };
}

class _WindowPainter extends CustomPainter {
  final _Scene scene;
  final Animation<double> t;

  _WindowPainter({required this.scene, required this.t}) : super(repaint: t);

  /// 0..1..0 over the loop, smooth at the seam.
  double get _wave => 0.5 - 0.5 * math.cos(2 * math.pi * t.value);

  double _waveAt(double phase) => 0.5 - 0.5 * math.cos(2 * math.pi * (t.value + phase));

  // The arch from the app icon, in its 1024-unit space.
  static final Path _arch = Path()
    ..moveTo(292, 862)
    ..lineTo(292, 486)
    ..cubicTo(292, 346, 410, 294, 462, 248)
    ..cubicTo(492, 221, 512, 188, 512, 136)
    ..cubicTo(512, 188, 532, 221, 562, 248)
    ..cubicTo(614, 294, 732, 346, 732, 486)
    ..lineTo(732, 862)
    ..close();

  static final Path _farHills = Path()
    ..moveTo(-40, 772)
    ..cubicTo(162, 676, 383, 682, 573, 744)
    ..cubicTo(740, 798, 903, 750, 1064, 722)
    ..lineTo(1064, 1124)
    ..lineTo(-40, 1124)
    ..close();

  static final Path _nearHills = Path()
    ..moveTo(-40, 818)
    ..cubicTo(122, 774, 285, 766, 448, 798)
    ..cubicTo(657, 834, 865, 774, 1064, 790)
    ..lineTo(1064, 1124)
    ..lineTo(-40, 1124)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 1024;
    final tile = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.23));
    canvas.save();
    canvas.clipRRect(tile);
    canvas.scale(k);

    const full = Rect.fromLTWH(0, 0, 1024, 1024);
    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: scene.sky,
          stops: scene.stops,
        ).createShader(full),
    );

    _paintBody(canvas);
    canvas.drawPath(_farHills, Paint()..color = scene.hillFar);
    if (scene.mosque) _paintMosque(canvas);
    canvas.drawPath(_nearHills, Paint()..color = scene.hillNear);

    // Dim the sky outside the arch so the window reads first.
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(full), _arch),
      Paint()..color = const Color(0xFF05040F).withValues(alpha: 0.22),
    );
    // The gold frame, with a soft glow behind it. Thicker than the home
    // screen icon's, so it still reads at list size.
    canvas.drawPath(
      _arch,
      Paint()
        ..color = const Color(0xFFF2C46D).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 56
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawPath(
      _arch,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEBB5), Color(0xFFEAB65A), Color(0xFFB9772A)],
        ).createShader(const Rect.fromLTRB(292, 136, 732, 862))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  void _paintBody(Canvas canvas) {
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    switch (scene.body) {
      case _Body.sun:
        final c = scene.at + Offset(0, scene.drift * _wave);
        canvas.drawCircle(
          c,
          scene.r * 2.4,
          glow..color = const Color(0xFFFFE2B0).withValues(alpha: 0.35 + 0.2 * _wave),
        );
        canvas.drawCircle(c, scene.r, Paint()..color = const Color(0xFFFFF4DA));
      case _Body.dawn:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(512, 800), width: 440, height: 240),
          glow..color = const Color(0xFFFFE9C8).withValues(alpha: 0.55 + 0.25 * _wave),
        );
        _sparkle(canvas, const Offset(560, 420), 22, 0.4 + 0.6 * _waveAt(0.2));
      case _Body.moon:
        canvas.drawCircle(scene.at, 150, glow..color = const Color(0xFF9DB4FF).withValues(alpha: 0.18));
        _crescent(canvas, scene.at, scene.r, (_wave - 0.5) * 0.15);
        _sparkle(canvas, const Offset(400, 350), 18, 0.3 + 0.7 * _waveAt(0.1));
        _sparkle(canvas, const Offset(620, 600), 13, 0.3 + 0.7 * _waveAt(0.45));
      case _Body.stars:
        _crescent(canvas, scene.at, scene.r, (_wave - 0.5) * 0.15);
        _sparkle(canvas, const Offset(600, 360), 20, 0.3 + 0.7 * _waveAt(0.0));
        _sparkle(canvas, const Offset(620, 600), 14, 0.3 + 0.7 * _waveAt(0.33));
        _sparkle(canvas, const Offset(390, 620), 11, 0.3 + 0.7 * _waveAt(0.66));
        _sparkle(canvas, const Offset(660, 470), 9, 0.3 + 0.7 * _waveAt(0.5));
    }
  }

  /// A crescent opening to the upper right, rocking by [tilt] radians.
  void _crescent(Canvas canvas, Offset c, double r, double tilt) {
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(center: c + Offset(r * 0.45, -r * 0.38), radius: r * 0.88));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(tilt);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      Paint()..color = const Color(0xFFFFF4D6),
    );
    canvas.restore();
  }

  /// A four-pointed star.
  void _sparkle(Canvas canvas, Offset c, double r, double opacity) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFBE3A4).withValues(alpha: opacity));
  }

  /// Jumuah: a small domed mosque on the far hills, in their shade.
  void _paintMosque(Canvas canvas) {
    final paint = Paint()..color = scene.hillNear;
    canvas.drawRect(const Rect.fromLTRB(420, 740, 604, 820), paint);
    canvas.drawCircle(const Offset(512, 742), 72, paint);
    canvas.drawRect(const Rect.fromLTRB(392, 660, 412, 820), paint);
    canvas.drawRect(const Rect.fromLTRB(612, 660, 632, 820), paint);
    canvas.drawRect(const Rect.fromLTRB(508, 640, 516, 672), paint);
  }

  @override
  bool shouldRepaint(covariant _WindowPainter old) => old.scene != scene || old.t != t;
}
