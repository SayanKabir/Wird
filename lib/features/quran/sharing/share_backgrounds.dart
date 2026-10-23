import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/prayer_service.dart' show PrayerPeriod;

/// What sits in the sky behind the text.
enum ShareGlow { none, sun, moon }

/// Base sky for the verse share image: one of the app's prayer-period
/// gradients. A [ShareWeather] is layered on top.
class ShareBackground {
  final PrayerPeriod period;
  final String label;
  final List<Color> colors;

  /// Header and ornament color; gold except where gold washes out.
  final Color accent;
  final ShareGlow glow;
  final bool stars;

  /// Darkening laid over the sky so white text stays readable on the
  /// brighter gradients.
  final double scrim;

  const ShareBackground({
    required this.period,
    required this.label,
    required this.colors,
    this.accent = AppColors.spiritualGold,
    this.glow = ShareGlow.none,
    this.stars = false,
    this.scrim = 0.15,
  });

  bool get isNight => glow == ShareGlow.moon || period == PrayerPeriod.fajr;

  static ShareBackground forPeriod(PrayerPeriod period) => all.firstWhere((b) => b.period == period);

  static const List<ShareBackground> all = [
    ShareBackground(
      period: PrayerPeriod.tahajjud,
      label: 'Tahajjud',
      colors: AppColors.tahajjudGradient,
      glow: ShareGlow.moon,
      stars: true,
      scrim: 0,
    ),
    ShareBackground(
      period: PrayerPeriod.fajr,
      label: 'Fajr',
      colors: AppColors.fajrGradient,
      glow: ShareGlow.sun,
      stars: true,
      scrim: 0.32,
    ),
    ShareBackground(
      period: PrayerPeriod.sunrise,
      label: 'Sunrise',
      colors: AppColors.sunriseGradient,
      accent: Color(0xFFFFF3C4),
      glow: ShareGlow.sun,
      scrim: 0.28,
    ),
    ShareBackground(
      period: PrayerPeriod.dhuhr,
      label: 'Dhuhr',
      colors: AppColors.dhuhrGradient,
      glow: ShareGlow.sun,
      scrim: 0.2,
    ),
    ShareBackground(
      period: PrayerPeriod.asr,
      label: 'Asr',
      colors: AppColors.asrGradient,
      accent: Color(0xFFFFF3C4),
      glow: ShareGlow.sun,
      scrim: 0.22,
    ),
    ShareBackground(
      period: PrayerPeriod.maghrib,
      label: 'Maghrib',
      colors: AppColors.maghribGradient,
      accent: Color(0xFFFFE8A3),
      glow: ShareGlow.sun,
      scrim: 0.22,
    ),
    ShareBackground(
      period: PrayerPeriod.isha,
      label: 'Isha',
      colors: AppColors.ishaGradient,
      glow: ShareGlow.moon,
      stars: true,
      scrim: 0,
    ),
  ];
}

/// Weather layered over the time-of-day sky, drawn like the dashboard's
/// weather effects but still, so the preview and exported image match.
enum ShareWeather {
  clear('Clear', Icons.wb_sunny_outlined),
  cloudy('Cloudy', Icons.cloud_outlined),
  rain('Rain', Icons.water_drop_outlined),
  snow('Snow', Icons.ac_unit_rounded),
  mist('Mist', Icons.blur_on_rounded);

  final String label;
  final IconData icon;

  const ShareWeather(this.label, this.icon);

  /// Overcast skies hide the stars and dim the sun or moon.
  bool get overcast => this != ShareWeather.clear;

  double get glowStrength => switch (this) {
        ShareWeather.clear => 1,
        ShareWeather.cloudy || ShareWeather.mist => 0.45,
        ShareWeather.snow => 0.3,
        ShareWeather.rain => 0,
      };
}

/// Draws the sky: gradient, stars, glow, weather and the legibility scrim.
class ShareSky extends StatelessWidget {
  final ShareBackground background;
  final ShareWeather weather;

  const ShareSky({super.key, required this.background, required this.weather});

  @override
  Widget build(BuildContext context) {
    final glowColor = background.glow == ShareGlow.sun ? const Color(0xFFFFD27A) : const Color(0xFFE8EEFF);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: background.colors,
            ),
          ),
        ),
        if (background.stars && !weather.overcast) const CustomPaint(painter: _StarsPainter()),
        if (background.glow != ShareGlow.none && weather.glowStrength > 0)
          Positioned(
            top: -70,
            right: -60,
            width: 220,
            height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  glowColor.withValues(alpha: 0.45 * weather.glowStrength),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ..._weatherLayers(),
        // Legibility scrim, heavier toward the bottom where the text sits.
        if (_scrim > 0)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: _scrim * 0.6),
                  Colors.black.withValues(alpha: _scrim * 1.4),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Weather adds its own haze, so bright skies need a little more scrim
  /// under snow and mist to keep white text readable.
  double get _scrim => switch (weather) {
        ShareWeather.snow => background.scrim + 0.08,
        ShareWeather.mist => background.scrim + 0.12,
        _ => background.scrim,
      };

  List<Widget> _weatherLayers() {
    final night = background.isNight;
    switch (weather) {
      case ShareWeather.clear:
        return const [];
      case ShareWeather.cloudy:
        return [
          _Tint(const Color(0xFF64748B), 0.16),
          CustomPaint(painter: _CloudsPainter(opacity: night ? 0.12 : 0.2)),
        ];
      case ShareWeather.rain:
        return [
          _Tint(const Color(0xFF334155), 0.32),
          CustomPaint(painter: _CloudsPainter(opacity: night ? 0.1 : 0.16)),
          const _AwayFromText(child: CustomPaint(painter: _RainPainter(drops: 110, opacity: 0.24))),
        ];
      case ShareWeather.snow:
        return [
          _Tint(const Color(0xFFCBD5E1), night ? 0.08 : 0.14),
          CustomPaint(painter: _CloudsPainter(opacity: night ? 0.1 : 0.18)),
          const _AwayFromText(child: CustomPaint(painter: _SnowPainter())),
        ];
      case ShareWeather.mist:
        final mist = night ? const Color(0xFFC7D2FE) : Colors.white;
        return [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  mist.withValues(alpha: 0.06),
                  mist.withValues(alpha: 0.2),
                  mist.withValues(alpha: 0.3),
                  mist.withValues(alpha: 0.2),
                  mist.withValues(alpha: 0.1),
                ],
                stops: const [0.0, 0.3, 0.5, 0.75, 1.0],
              ),
            ),
          ),
          const CustomPaint(painter: _MistBandsPainter()),
        ];
    }
  }
}

/// Fades falling particles out behind the text column so rain and snow
/// gather at the edges and top instead of breaking up words.
class _AwayFromText extends StatelessWidget {
  final Widget child;

  const _AwayFromText({required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        colors: [Colors.white, Color(0x40FFFFFF), Color(0x40FFFFFF), Colors.white],
        stops: [0.0, 0.22, 0.78, 1.0],
      ).createShader(rect),
      child: child,
    );
  }
}

class _Tint extends StatelessWidget {
  final Color color;
  final double alpha;

  const _Tint(this.color, this.alpha);

  @override
  Widget build(BuildContext context) => ColoredBox(color: color.withValues(alpha: alpha));
}

/// Fixed star field for the night skies.
class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  static const List<(double, double, double)> _stars = [
    (0.08, 0.04, 1.1), (0.22, 0.09, 0.7), (0.37, 0.03, 0.9), (0.55, 0.07, 0.6),
    (0.71, 0.12, 1.0), (0.9, 0.05, 0.8), (0.03, 0.18, 0.6), (0.46, 0.012, 1.2),
    (0.83, 0.2, 0.7), (0.05, 0.31, 0.8), (0.95, 0.33, 0.6), (0.3, 0.26, 0.5),
    (0.64, 0.24, 0.8), (0.12, 0.48, 0.5), (0.9, 0.5, 0.9), (0.04, 0.66, 0.7),
    (0.96, 0.72, 0.5), (0.2, 0.86, 0.6), (0.78, 0.9, 0.7), (0.5, 0.95, 0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (final (x, y, r) in _stars) {
      canvas.drawCircle(Offset(x * size.width, y * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft clouds along the top, built from overlapping blurred ovals like the
/// dashboard's cloud layer.
class _CloudsPainter extends CustomPainter {
  final double opacity;
  const _CloudsPainter({required this.opacity});

  // (x, y, width) as fractions of the card.
  static const List<(double, double, double)> _clouds = [
    (0.12, 0.05, 0.62), (0.72, 0.02, 0.7), (0.42, 0.13, 0.55), (0.95, 0.16, 0.5),
    (0.05, 0.22, 0.45),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const base = Colors.white;
    for (var i = 0; i < _clouds.length; i++) {
      final (x, y, w) = _clouds[i];
      final width = w * size.width;
      final height = width * 0.35;
      final paint = Paint()
        ..color = base.withValues(alpha: opacity * (i.isEven ? 1 : 0.75))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      final cx = x * size.width;
      final cy = y * size.height;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: width * 0.6, height: height * 0.7), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - width * 0.2, cy + height * 0.1), width: width * 0.5, height: height * 0.6), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + width * 0.2, cy + height * 0.05), width: width * 0.55, height: height * 0.65), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + width * 0.05, cy - height * 0.2), width: width * 0.45, height: height * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

/// Thin streaks with a slight wind angle, as on the dashboard.
class _RainPainter extends CustomPainter {
  final int drops;
  final double opacity;

  const _RainPainter({required this.drops, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(99);
    final paint = Paint()
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < drops; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final length = 10.0 + random.nextDouble() * 16.0;
      paint.color = Colors.white.withValues(alpha: opacity * (0.5 + random.nextDouble() * 0.5));
      canvas.drawLine(Offset(x, y), Offset(x + length * 0.12, y + length), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      oldDelegate.drops != drops || oldDelegate.opacity != opacity;
}

class _SnowPainter extends CustomPainter {
  const _SnowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(77);
    for (var i = 0; i < 70; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1.4 + random.nextDouble() * 2.4;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.55 + random.nextDouble() * 0.35)
        ..maskFilter = radius > 2.6 ? const MaskFilter.blur(BlurStyle.normal, 1.0) : null;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Low drifting bands that give mist some body.
class _MistBandsPainter extends CustomPainter {
  const _MistBandsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (final (y, h, a) in const [(0.12, 0.08, 0.14), (0.38, 0.1, 0.14), (0.62, 0.14, 0.16), (0.88, 0.12, 0.16)]) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.5, size.height * y), width: size.width * 1.4, height: size.height * h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
