import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/services/weather_service.dart';

/// Weather overlay that renders clouds, rain, or snow on top of the background
class WeatherOverlay extends StatelessWidget {
  final WeatherCondition condition;
  final int cloudCoverage; // 0-100
  final bool reduceMotion;

  const WeatherOverlay({
    super.key,
    required this.condition,
    this.cloudCoverage = 0,
    this.reduceMotion = false,
    this.isNight = false,
  });

  final bool isNight;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cloud layer
          if (_shouldShowClouds())
            _CloudOverlay(
              cloudCoverage: cloudCoverage,
              reduceMotion: reduceMotion,
            ),

          // Rain particles
          if (condition == WeatherCondition.rain ||
              condition == WeatherCondition.drizzle ||
              condition == WeatherCondition.thunderstorm)
            _RainOverlay(
              intensity: condition == WeatherCondition.drizzle ? 0.3 : 1.0,
              reduceMotion: reduceMotion,
              hasLightning: condition == WeatherCondition.thunderstorm,
            ),

          // Snow particles
          if (condition == WeatherCondition.snow)
            _SnowOverlay(reduceMotion: reduceMotion),

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

  const _CloudOverlay({
    required this.cloudCoverage,
    required this.reduceMotion,
  });

  @override
  State<_CloudOverlay> createState() => _CloudOverlayState();
}

class _CloudOverlayState extends State<_CloudOverlay>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0; // Time in seconds
      });
    });

    if (!widget.reduceMotion) {
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
    // Number of clouds based on coverage
    final int cloudCount = (widget.cloudCoverage / 25).clamp(1, 4).toInt();
    final double opacity = (widget.cloudCoverage / 100).clamp(0.15, 0.45); // Reduced max opacity for moon visibility

    return CustomPaint(
      painter: _CloudPainter(
        time: _time,
        cloudCount: cloudCount,
        opacity: opacity,
      ),
      size: Size.infinite,
    );
  }
}

class _CloudPainter extends CustomPainter {
  final double time;
  final int cloudCount;
  final double opacity;

  _CloudPainter({
    required this.time,
    required this.cloudCount,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Deterministic for consistent clouds

    for (int i = 0; i < cloudCount; i++) {
      final baseY = random.nextDouble() * size.height * 0.35; // Upper 35%
      final speed = 0.3 + random.nextDouble() * 0.4; // Speed variation
      final cloudWidth = size.width * (0.35 + random.nextDouble() * 0.3);
      final cloudHeight = cloudWidth * 0.35;

      // Drift position — wraps around seamlessly
      // Time-based movement: (time * speed + offset) % period
      // Period is 1.4 (screen width + buffer)
      final period = 1.4;
      final offset = i * 0.35;
      final rawX = ((time * speed * 0.1 + offset) % period); 
      // Shift so 0 is left edge, start slightly off-screen left (-0.2)
      final dx = (rawX - 0.2) * size.width;

      _drawCloud(
        canvas,
        Offset(dx, baseY),
        cloudWidth,
        cloudHeight,
        opacity * (0.6 + random.nextDouble() * 0.4),
      );
    }
  }

  void _drawCloud(
    Canvas canvas,
    Offset position,
    double width,
    double height,
    double cloudOpacity,
  ) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(cloudOpacity)
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
      oldDelegate.time != time;
}

// =============================================================
// RAIN OVERLAY
// =============================================================

class _RainOverlay extends StatefulWidget {
  final double intensity; // 0.0 - 1.0
  final bool reduceMotion;
  final bool hasLightning;

  const _RainOverlay({
    required this.intensity,
    required this.reduceMotion,
    this.hasLightning = false,
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

  void _scheduleLightning() {
    if (!mounted) return;
    // Random delay between 5 and 15 seconds
    final delay = Duration(seconds: 5 + math.Random().nextInt(10));
    _lightningTimer = Timer(delay, _triggerFlash);
  }

  void _triggerFlash() async {
    if (!mounted) return;
    
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
              ),
            );
          },
        ),
        
        // Lightning Flash
        if (_showFlash)
          Container(
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

  _RainPainter({required this.progress, required this.intensity});

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
      
      // Slight wind angle (5-10 degrees)
      final windOffset = length * 0.12;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + windOffset, y + length),
        paint,
      );
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
