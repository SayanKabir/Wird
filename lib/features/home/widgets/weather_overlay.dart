import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/constants/durations.dart';
import '../../../core/services/weather_service.dart';

/// What the real sky tells the weather: where the light comes from and how
/// hard the wind blows. Given only with the live sky, in full visuals; without
/// it the weather draws as it always has.
class SkyLight {
  /// The sun's colour and place on screen, and its height in degrees.
  final Color sunColor;
  final Alignment sun;
  final double sunAltitude;

  /// 0..1: how much moonlight there is.
  final double moonlight;

  /// km/h, from Open-Meteo.
  final double windSpeed;

  const SkyLight({
    required this.sunColor,
    required this.sun,
    required this.sunAltitude,
    required this.moonlight,
    required this.windSpeed,
  });

  /// Clouds drift with the wind: about as before in a light breeze, up to
  /// three times faster in a gale.
  double get drift => (0.5 + windSpeed / 12).clamp(0.5, 3.0);

  /// Rain slants with the wind, horizontal travel per unit of fall.
  double get slant => (0.04 + windSpeed / 70).clamp(0.04, 0.6);

  /// 0..1: how strongly a low sun colours the clouds, strongest just after
  /// sunrise and before sunset, gone by mid-morning or deep twilight.
  double get goldenHour =>
      _smooth(-7, -1, sunAltitude) * (1 - _smooth(5, 16, sunAltitude));

  /// The body colour of a cloud: white by day, slate at night, silvered by
  /// the moon.
  Color get cloudColor {
    // Indigo rather than grey, so night clouds deepen the sky instead of
    // greying it; the moon silvers them only a little.
    final night = Color.lerp(const Color(0xFF343E66), const Color(0xFFAEB8DA), moonlight * 0.45)!;
    final day = Color.lerp(Colors.white, sunColor, goldenHour * 0.35)!;
    return Color.lerp(night, day, _smooth(-8, 4, sunAltitude))!;
  }

  static double _smooth(double a, double b, double v) {
    final k = ((v - a) / (b - a)).clamp(0.0, 1.0);
    return k * k * (3 - 2 * k);
  }
}

/// Weather overlay that renders clouds, rain, or snow on top of the background
class WeatherOverlay extends StatelessWidget {
  final WeatherCondition condition;
  final int cloudCoverage; // 0-100
  final bool reduceMotion;

  /// Lighter visuals: clouds step at a lower rate.
  final bool lite;

  /// The live sky's light and wind; null draws the plain weather.
  final SkyLight? light;

  const WeatherOverlay({
    super.key,
    required this.condition,
    this.cloudCoverage = 0,
    this.reduceMotion = false,
    this.lite = false,
    this.isNight = false,
    this.light,
  });

  final bool isNight;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Each animated layer gets its own RepaintBoundary so its repaints stay
      // in a separate compositing layer. Without these, a cloud or raindrop
      // moving invalidated the layer shared with everything drawn above it,
      // forcing the dashboard's BackdropFilters to re-blur on every tick.
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cloud layer. Fades in and out as the weather turns cloudy or
          // clears, rather than appearing all at once.
          AnimatedSwitcher(
            duration: AppDurations.weatherFade * 4,
            // Fill the screen like the other layers, also mid-fade.
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, if (current != null) current],
            ),
            child: _shouldShowClouds()
                ? RepaintBoundary(
                    key: const ValueKey('clouds'),
                    child: _CloudOverlay(
                      cloudCoverage: cloudCoverage,
                      reduceMotion: reduceMotion,
                      lite: lite,
                      light: light,
                    ),
                  )
                : const SizedBox.expand(),
          ),

          // Rain particles
          if (condition == WeatherCondition.rain ||
              condition == WeatherCondition.drizzle ||
              condition == WeatherCondition.thunderstorm)
            RepaintBoundary(
              child: _RainOverlay(
                intensity: condition == WeatherCondition.drizzle ? 0.3 : 1.0,
                reduceMotion: reduceMotion,
                hasLightning: condition == WeatherCondition.thunderstorm,
                light: light,
              ),
            ),

          // Snow particles
          if (condition == WeatherCondition.snow)
            RepaintBoundary(child: _SnowOverlay(reduceMotion: reduceMotion)),

          // Fog overlay
          if (condition == WeatherCondition.fog)
            _FogOverlay(isNight: isNight),
        ],
      ),
    );
  }

  bool _shouldShowClouds() {
    return condition == WeatherCondition.cloudy ||
        condition == WeatherCondition.rain ||
        condition == WeatherCondition.drizzle ||
        condition == WeatherCondition.thunderstorm ||
        condition == WeatherCondition.snow ||
        cloudCoverage > 30;
  }
}

// =============================================================
// CLOUD OVERLAY
// =============================================================

class _CloudOverlay extends StatefulWidget {
  final int cloudCoverage;
  final bool reduceMotion;
  final bool lite;
  final SkyLight? light;

  const _CloudOverlay({
    required this.cloudCoverage,
    required this.reduceMotion,
    this.lite = false,
    this.light,
  });

  @override
  State<_CloudOverlay> createState() => _CloudOverlayState();
}

class _CloudOverlayState extends State<_CloudOverlay>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _time = 0.0;

  /// How many clouds are showing, eased toward [_targetCount] so a change in
  /// cover fades a cloud in or out instead of adding or removing it at once.
  /// Fractional: the last cloud is partly faded.
  late double _shown = _targetCount;
  late double _opacity = _targetOpacity;

  double get _targetCount => (widget.cloudCoverage / 25).clamp(1, 4).toInt().toDouble();

  // Reduced max opacity for moon visibility
  double get _targetOpacity => (widget.cloudCoverage / 100).clamp(0.15, 0.45);

  /// Share of the way to the target covered per second.
  static const double _easePerSecond = 0.4;

  /// The clouds drift at `time * speed * 0.1`, so one traverse of the screen
  /// takes roughly 47 seconds — about 0.27 logical pixels per frame at 120Hz.
  /// Repainting for that is pure waste: each paint issues up to 16 oval draws,
  /// every one carrying a `MaskFilter.blur`, across the full screen. Because
  /// this sits underneath the dashboard's BackdropFilters, every one of those
  /// repaints also forced the blurs above it to re-rasterise, which is what
  /// stopped the app from ever going idle.
  ///
  /// Stepping at ~20fps moves a cloud ~1.6px per update — still perfectly
  /// smooth for a soft-edged blurred shape — while cutting the paint rate by 6x.
  static const double _stepSeconds = 1 / 20;

  /// In lighter visuals there are no blurs above to re-rasterise, and ~10fps
  /// still reads as a slow drift for these soft shapes.
  static const double _liteStepSeconds = 1 / 10;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final next = elapsed.inMilliseconds / 1000.0;
      if (next - _time < (widget.lite ? _liteStepSeconds : _stepSeconds)) return;
      final step = ((next - _time) * _easePerSecond).clamp(0.0, 1.0);
      setState(() {
        _time = next;
        _shown += (_targetCount - _shown) * step;
        _opacity += (_targetOpacity - _opacity) * step;
      });
    });

    if (!widget.reduceMotion) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant _CloudOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Previously the ticker state was decided once in initState, so toggling
    // Reduce Motion left the clouds animating until the widget was recreated.
    if (widget.reduceMotion && _ticker.isActive) {
      _ticker.stop();
    } else if (!widget.reduceMotion && !_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Still clouds have nothing to ease them; show the target directly.
    if (!_ticker.isActive) {
      _shown = _targetCount;
      _opacity = _targetOpacity;
    }

    return CustomPaint(
      painter: _CloudPainter(
        time: _time,
        cloudCount: _shown,
        opacity: _opacity,
        light: widget.light,
      ),
      size: Size.infinite,
    );
  }
}

class _CloudPainter extends CustomPainter {
  final double time;

  /// Clouds to draw; the fraction past a whole number is how far the last
  /// one has faded in.
  final double cloudCount;
  final double opacity;
  final SkyLight? light;

  _CloudPainter({
    required this.time,
    required this.cloudCount,
    required this.opacity,
    this.light,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Deterministic for consistent clouds

    for (int i = 0; i < cloudCount.ceil(); i++) {
      final baseY = random.nextDouble() * size.height * 0.35; // Upper 35%
      final speed = 0.3 + random.nextDouble() * 0.4; // Speed variation
      final cloudWidth = size.width * (0.35 + random.nextDouble() * 0.3);
      final cloudHeight = cloudWidth * 0.35;

      // Drift left to right and wrap. The loop starts with the whole cloud
      // (and its blur) past the left edge and ends with it past the right,
      // so a cloud never vanishes or appears while still on screen.
      final margin = cloudWidth * 0.5 + 40;
      final span = size.width + margin * 2;
      final offset = i * 0.35;
      final travelled = (time * speed * 0.1 * (light?.drift ?? 1) + offset) * size.width;
      final dx = travelled % span - margin;

      final fade = (cloudCount - i).clamp(0.0, 1.0);
      final cloudOpacity = opacity * (0.6 + random.nextDouble() * 0.4) * fade;
      _drawCloud(canvas, Offset(dx, baseY), cloudWidth, cloudHeight, cloudOpacity);
      _lightCloud(canvas, size, Offset(dx, baseY), cloudWidth, cloudHeight, cloudOpacity);
    }
  }

  /// Near sunrise and sunset, the side of a cloud facing the sun and its
  /// underside catch the low light. Two more soft ovals, only then.
  void _lightCloud(Canvas canvas, Size size, Offset position, double width, double height, double cloudOpacity) {
    final light = this.light;
    if (light == null || light.goldenHour < 0.02) return;
    final sunX = size.width / 2 + light.sun.x * size.width / 2;
    final towardSun = ((sunX - position.dx) / size.width).clamp(-1.0, 1.0);
    final paint = Paint()
      ..color = light.sunColor.withValues(alpha: cloudOpacity * light.goldenHour * 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: position + Offset(towardSun * width * 0.18, height * 0.28),
        width: width * 0.62,
        height: height * 0.32,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: position + Offset(towardSun * width * 0.3, height * 0.05),
        width: width * 0.3,
        height: height * 0.45,
      ),
      paint,
    );
  }

  void _drawCloud(
    Canvas canvas,
    Offset position,
    double width,
    double height,
    double cloudOpacity,
  ) {
    final paint = Paint()
      ..color = (light?.cloudColor ?? Colors.white).withOpacity(cloudOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final cx = position.dx;
    final cy = position.dy;

    // Cloud shape: overlapping circles
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: width * 0.6,
        height: height * 0.7,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - width * 0.2, cy + height * 0.1),
        width: width * 0.5,
        height: height * 0.6,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + width * 0.2, cy + height * 0.05),
        width: width * 0.55,
        height: height * 0.65,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + width * 0.05, cy - height * 0.2),
        width: width * 0.45,
        height: height * 0.5,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.light != light;
}

// =============================================================
// RAIN OVERLAY
// =============================================================

class _RainOverlay extends StatefulWidget {
  final double intensity; // 0.0 - 1.0
  final bool reduceMotion;
  final bool hasLightning;
  final SkyLight? light;

  const _RainOverlay({
    required this.intensity,
    required this.reduceMotion,
    this.hasLightning = false,
    this.light,
  });

  @override
  State<_RainOverlay> createState() => _RainOverlayState();
}

class _RainOverlayState extends State<_RainOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    if (!widget.reduceMotion) {
      _controller.repeat();
    }
    
    if (widget.hasLightning) {
      _scheduleLightning();
    }
  }

  Timer? _lightningTimer;
  bool _showFlash = false;

  /// Where the strike lights the clouds from, as a share of the screen.
  Offset _flashAt = const Offset(0.5, 0.2);

  void _scheduleLightning() {
    if (!mounted) return;
    // Random delay between 5 and 15 seconds
    final delay = Duration(seconds: 5 + math.Random().nextInt(10));
    _lightningTimer = Timer(delay, _triggerFlash);
  }

  void _triggerFlash() async {
    if (!mounted) return;
    final random = math.Random();
    _flashAt = Offset(0.2 + random.nextDouble() * 0.6, 0.12 + random.nextDouble() * 0.2);

    // Flash on
    setState(() => _showFlash = true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    
    // Flash off
    setState(() => _showFlash = false);
    
    // 30% chance of double flash
    if (math.Random().nextDouble() < 0.3) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() => _showFlash = true);
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _showFlash = false);
    }
    
    _scheduleLightning();
  }

  @override
  void dispose() {
    _controller.dispose();
    _lightningTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Rain Drops
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _RainPainter(
                progress: _controller.value,
                intensity: widget.intensity,
                slant: widget.light?.slant,
              ),
            );
          },
        ),
        
        // Lightning Flash. With the live sky it glows out of the clouds
        // from where it struck; otherwise the whole screen flashes.
        if (_showFlash)
          widget.light != null
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(_flashAt.dx * 2 - 1, _flashAt.dy * 2 - 1),
                      radius: 0.95,
                      colors: [
                        const Color(0xFFE4E8FF).withValues(alpha: 0.55),
                        const Color(0xFFC9D0FF).withValues(alpha: 0.18),
                        const Color(0x00C9D0FF),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                )
              : Container(
                  color: Colors.white.withOpacity(0.3),
                  width: double.infinity,
                  height: double.infinity,
                ),
      ],
    );
  }
}

class _RainPainter extends CustomPainter {
  final double progress;
  final double intensity;

  /// Horizontal travel per unit of fall, from the wind. Null keeps the old
  /// fixed lean.
  final double? slant;

  _RainPainter({required this.progress, required this.intensity, this.slant});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(99);
    final dropCount = (100 * intensity).toInt();

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < dropCount; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble();
      final speed = 0.8 + random.nextDouble() * 0.4;
      final length = 12.0 + random.nextDouble() * 18.0;

      // Each drop falls continuously
      final y = ((baseY + progress * speed) % 1.2) * size.height;

      final lean = slant;
      if (lean == null) {
        // Slight wind angle (5-10 degrees)
        final windOffset = length * 0.12;
        canvas.drawLine(Offset(x, y), Offset(x + windOffset, y + length), paint);
      } else {
        // Blown along its slant as it falls, wrapping at the edges.
        final drifted = (x + y * lean) % size.width;
        canvas.drawLine(Offset(drifted, y), Offset(drifted + length * lean, y + length), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// =============================================================
// SNOW OVERLAY
// =============================================================

class _SnowOverlay extends StatefulWidget {
  final bool reduceMotion;

  const _SnowOverlay({required this.reduceMotion});

  @override
  State<_SnowOverlay> createState() => _SnowOverlayState();
}

class _SnowOverlayState extends State<_SnowOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    if (!widget.reduceMotion) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SnowPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _SnowPainter extends CustomPainter {
  final double progress;

  _SnowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(77);
    final paint = Paint()..color = Colors.white.withOpacity(0.5);

    for (int i = 0; i < 60; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble();
      final speed = 0.3 + random.nextDouble() * 0.4;
      final radius = 1.5 + random.nextDouble() * 2.5;

      // Gentle drift with sine wave for floating effect
      final y = ((baseY + progress * speed) % 1.15) * size.height;
      final xDrift = math.sin(progress * math.pi * 2 + i * 0.5) * 15;

      canvas.drawCircle(
        Offset(baseX + xDrift, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// =============================================================
// FOG OVERLAY
// =============================================================

class _FogOverlay extends StatelessWidget {
  final bool isNight;

  const _FogOverlay({super.key, required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Use screen blend mode at night to add luminosity rather than grayness (pollution look)
        backgroundBlendMode: isNight ? BlendMode.screen : BlendMode.srcOver,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isNight
              ? [
                  const Color(0xFFC7D2FE).withOpacity(0.0), // Light indigo tint
                  const Color(0xFFC7D2FE).withOpacity(0.1),
                  const Color(0xFFC7D2FE).withOpacity(0.2), // Glowing mist center
                  const Color(0xFFC7D2FE).withOpacity(0.1),
                  const Color(0xFFC7D2FE).withOpacity(0.0),
                ]
              : [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.0),
                ],
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        ),
      ),
    );
  }
}
