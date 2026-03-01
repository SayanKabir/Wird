import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wird2/core/constants/colors.dart';
import 'package:wird2/core/services/prayer_service.dart';
import 'package:wird2/core/utils/moon_phase_utils.dart';
import 'package:wird2/core/services/weather_service.dart';
import 'package:wird2/features/home/widgets/weather_overlay.dart';

/// Animated celestial background with realistic Horizon Arc physics
class CelestialBackground extends StatefulWidget {
  final PrayerPeriod prayerPeriod;
  final bool reduceMotion;
  final Widget child;
  final WeatherCondition weatherCondition;
  final int cloudCoverage;
  final double latitude;
  final MoonPhase? fixedMoonPhase;
  final bool showCelestialBody;

  const CelestialBackground({
    super.key,
    required this.prayerPeriod,
    required this.child,
    this.reduceMotion = false,
    this.weatherCondition = WeatherCondition.clear,
    this.cloudCoverage = 0,
    this.latitude = 0.0,
    this.fixedMoonPhase,
    this.showCelestialBody = true,
  });

  @override
  State<CelestialBackground> createState() => _CelestialBackgroundState();
}

class _CelestialBackgroundState extends State<CelestialBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  List<Color> _currentColors = AppColors.ishaGradient;
  List<Color> _targetColors = AppColors.ishaGradient;

  @override
  void initState() {
    super.initState();

    // 12s duration for a very slow, majestic celestial transition
    _controller = AnimationController(
      duration: widget.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 12000),
      vsync: this,
    );

    // Using easeInOutSine for a very natural, non-mechanical feel
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );

    _targetColors = AppColors.getGradientForPeriod(widget.prayerPeriod);
    _currentColors = _targetColors;

    _controller.forward();
  }

  @override
  void didUpdateWidget(CelestialBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.prayerPeriod != widget.prayerPeriod) {
      _currentColors = _getCurrentGradient();
      _targetColors = AppColors.getGradientForPeriod(widget.prayerPeriod);

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ==========================================
  // 1. GRADIENT LOGIC
  // ==========================================

  List<Color> _getCurrentGradient() {
    if (!_controller.isAnimating) return _targetColors;
    return _lerpColorList(_currentColors, _targetColors, _animation.value);
  }

  List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    final maxLength = math.max(a.length, b.length);
    final result = <Color>[];
    for (int i = 0; i < maxLength; i++) {
      final colorA = i < a.length ? a[i] : a.last;
      final colorB = i < b.length ? b[i] : b.last;
      result.add(Color.lerp(colorA, colorB, t)!);
    }
    return result;
  }

  // ==========================================
  // 2. CELESTIAL PHYSICS (The "Horizon Arc")
  // ==========================================

  Alignment _calculateCelestialAlignment(double t) {
    // SCREEN COORDINATES:
    // (0,0) is Center.
    // (-1.0, -1.0) is Top Left. (1.0, 1.0) is Bottom Right.
    // X: -1 (West/Left) <-> +1 (East/Right)
    // Y: -1 (Sky) <-> +1 (Ground)
    // Horizon Visual Line approx Y = 0.3

    Alignment start;
    Alignment end;

    switch (widget.prayerPeriod) {
      case PrayerPeriod.fajr:
      // SUN RISE PART 1: Deep East to Horizon
        start = const Alignment(1.2, 1.2); // Below bottom-right
        end = const Alignment(0.9, 0.4);   // Just touching horizon right
        break;

      case PrayerPeriod.sunrise:
      // SUN RISE PART 2: Horizon to Mid-Morning
        start = const Alignment(0.9, 0.4);
        end = const Alignment(0.6, -0.4);  // Mid-right sky
        break;

      case PrayerPeriod.dhuhr:
      // NOON: Mid-Morning to Zenith
        start = const Alignment(0.6, -0.4);
        end = const Alignment(0.0, -0.85); // High center
        break;

      case PrayerPeriod.asr:
      // AFTERNOON: Zenith to Late Afternoon
        start = const Alignment(0.0, -0.85);
        end = const Alignment(-0.6, -0.2); // Mid-left sky
        break;

      case PrayerPeriod.maghrib:
      // SUNSET: Late Afternoon to Below Horizon
        start = const Alignment(-0.6, -0.2);
        end = const Alignment(-1.1, 0.6); // Below horizon left
        break;

      case PrayerPeriod.isha:
      // MOON RISE: Rises from East (Right) just like sun!
      // Start below horizon right, move to high night sky
        start = const Alignment(1.2, 0.8);  // Below horizon right
        end = const Alignment(0.5, -0.6);   // High right-center sky
        break;

      case PrayerPeriod.tahajjud:
      // MOON SETTING: High Sky to West
        start = const Alignment(0.5, -0.6);
        end = const Alignment(-0.4, -0.5);  // Moves towards left
        break;

      default:
        start = Alignment.center;
        end = Alignment.center;
    }

    return Alignment.lerp(start, end, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentColors = _getCurrentGradient();
        final stops = _generateStops(currentColors.length);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: currentColors,
              stops: stops,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Stars (Deep Night Only - Background Layer)
              if (_isNightTime(widget.prayerPeriod))
                Positioned.fill(
                  child: _StarField(
                    moonAlignment: _calculateCelestialAlignment(_animation.value),
                  ),
                ),

              // 2. The Celestial Body (Sun/Moon)
              if (widget.showCelestialBody)
                Align(
                  alignment: _calculateCelestialAlignment(_animation.value),
                  child: _CelestialBody(
                    prayerPeriod: widget.fixedMoonPhase != null ? PrayerPeriod.isha : widget.prayerPeriod,
                    reduceMotion: widget.reduceMotion,
                    latitude: widget.latitude,
                    fixedMoonPhase: widget.fixedMoonPhase,
                  ),
                ),

              // 3. WEATHER OVERLAY
              WeatherOverlay(
                condition: widget.weatherCondition,
                cloudCoverage: widget.cloudCoverage,
                reduceMotion: widget.reduceMotion,
                isNight: _isNightTime(widget.prayerPeriod),
              ),

              // 4. HORIZON HAZE (Atmospheric Depth)
              // This overlay sits at the bottom to create the illusion of a "horizon line"
              // Objects at Y > 0.4 will appear "behind" or "in" this haze.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.of(context).size.height * 0.4,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          currentColors.last.withOpacity(0.0), // Transparent top
                          currentColors.last.withOpacity(0.9), // Solid bottom
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Main Content
              widget.child,
            ],
          ),
        );
      },
    );
  }

  List<double>? _generateStops(int length) {
    if (length <= 1) return null;
    return List.generate(length, (i) => i / (length - 1));
  }

  bool _isNightTime(PrayerPeriod period) {
    // If debug moon is set, treat as night to make it visible
    if (widget.fixedMoonPhase != null) return true;
    
    return period == PrayerPeriod.isha ||
        period == PrayerPeriod.tahajjud;
  }
}

/// Celestial body (Sun/Moon) widget
class _CelestialBody extends StatelessWidget {
  final PrayerPeriod prayerPeriod;
  final bool reduceMotion;
  final double latitude;
  final MoonPhase? fixedMoonPhase;

  const _CelestialBody({
    required this.prayerPeriod,
    required this.reduceMotion,
    required this.latitude,
    this.fixedMoonPhase,
  });

  @override
  Widget build(BuildContext context) {
    final isNight = _isNight(prayerPeriod);
    final isSunset = prayerPeriod == PrayerPeriod.maghrib;

    // Size varies slightly: Sun is bigger/brighter at noon
    final double size = (prayerPeriod == PrayerPeriod.dhuhr) ? 80 : 70;

    // Calculate moon phase and tilt
    double phaseValue = MoonPhaseUtils.getPhaseValue(DateTime.now());
    double illumination = MoonPhaseUtils.getIllumination(DateTime.now());
    
    // Override if fixed phase is provided
    if (fixedMoonPhase != null) {
      illumination = fixedMoonPhase!.illumination;
      // Map enum to approximate phase value for rendering
      switch (fixedMoonPhase!) {
        case MoonPhase.newMoon: phaseValue = 0.0; break;
        case MoonPhase.waxingCrescent: phaseValue = 0.125; break;
        case MoonPhase.firstQuarter: phaseValue = 0.25; break;
        case MoonPhase.waxingGibbous: phaseValue = 0.375; break;
        case MoonPhase.fullMoon: phaseValue = 0.5; break;
        case MoonPhase.waningGibbous: phaseValue = 0.625; break;
        case MoonPhase.lastQuarter: phaseValue = 0.75; break;
        case MoonPhase.waningCrescent: phaseValue = 0.875; break;
      }
    }

    final tiltAngle = MoonPhaseUtils.getMoonTilt(DateTime.now(), latitude);

    // Calculate glow/shadow colors based on state
    final Color moonColor = const Color(0xFFF8FAFC); // Crisp White
    final Color sunColor = const Color(0xFFFDB813); // Gold
    final Color sunsetColor = const Color(0xFFFF7E5F); // Red-Orange

    final Color glowColor = isNight
        ? Colors.white.withOpacity(0.4 + illumination * 0.4) // Brighter glow at full moon
        : isSunset
        ? const Color(0xFFFF4757).withOpacity(0.5)
        : const Color(0xFFFDB813).withOpacity(0.4);

    return SizedBox(
      width: size,
      height: size,
      child: isNight
          ? Transform.rotate(
              angle: tiltAngle,
              child: CustomPaint(
                painter: _MoonPainter(
                  phaseValue: phaseValue,
                  moonColor: moonColor,
                  glowColor: glowColor,
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSunset ? sunsetColor : sunColor,
                boxShadow: [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 50,
                    spreadRadius: 15,
                  ),
                ],
              ),
            ),
    );
  }

  bool _isNight(PrayerPeriod p) =>
      p == PrayerPeriod.isha || p == PrayerPeriod.tahajjud;
}

/// Moon phase painter — draws proper crescent/gibbous shape with matching glow
class _MoonPainter extends CustomPainter {
  final double phaseValue; // 0.0 = new, 0.5 = full, 1.0 = new
  final Color moonColor;
  final Color glowColor;

  _MoonPainter({
    required this.phaseValue,
    required this.moonColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 1. Calculate the Path of the lit portion
    final Path moonPath = _calculatePhasePath(center, radius);

    // 2. Draw Glow (behind the moon body) with a blur
    // We draw the same path but with a mask filter
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawPath(moonPath, glowPaint);

    // 3. Draw Moon Body
    final moonPaint = Paint()..color = moonColor;
    canvas.drawPath(moonPath, moonPaint);

    // 4. Draw Craters (Clipped to the lit area)
    canvas.save();
    canvas.clipPath(moonPath);
    
    final craterPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.3); // Slate-200

    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), radius * 0.25, craterPaint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.6), radius * 0.16, craterPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.25), radius * 0.12, craterPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.35), radius * 0.08, craterPaint);
    
    canvas.restore();
  }

  /// Calculates the visible moon path (crescent/gibbous)
  Path _calculatePhasePath(Offset center, double radius) {
    final path = Path();
    
    final double illumination = (1 - math.cos(phaseValue * 2 * math.pi)) / 2;
    final bool isWaxing = phaseValue <= 0.5;
    
    // Terminator offset: -1 (New) to +1 (Full)
    final double terminatorOffset = (illumination * 2) - 1;
    final double ellipseWidth = radius * terminatorOffset.abs();
    final bool isHalfMoon = ellipseWidth < 0.5;

    if (isWaxing) {
      // WAXING: Right Semicircle is the base (Top -> Right -> Bottom)
      path.addArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi);
      
      if (isHalfMoon) {
        path.lineTo(center.dx, center.dy - radius);
      } else {
        // Return trip from Bottom to Top via terminator
        path.arcTo(
          Rect.fromCenter(center: center, width: ellipseWidth * 2, height: radius * 2),
          math.pi / 2,
          terminatorOffset < 0 ? -math.pi : math.pi, // -pi for crescent, +pi for gibbous
          false
        );
      }
    } else {
      // WANING: Left Semicircle is the base (Bottom -> Left -> Top)
      path.addArc(Rect.fromCircle(center: center, radius: radius), math.pi / 2, math.pi);

      if (isHalfMoon) {
        path.lineTo(center.dx, center.dy + radius);
      } else {
        // Return trip from Top to Bottom ('-pi/2' start angle works for continuity)
        path.arcTo(
           Rect.fromCenter(center: center, width: ellipseWidth * 2, height: radius * 2),
           -math.pi / 2,
           terminatorOffset < 0 ? -math.pi : math.pi,
           false
        );
      }
    }
    
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) =>
      oldDelegate.phaseValue != phaseValue || oldDelegate.glowColor != glowColor;
}

/// Star field painter
class _StarField extends StatelessWidget {
  final Alignment moonAlignment;
  
  const _StarField({required this.moonAlignment});
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter(moonAlignment: moonAlignment));
  }
}

class _StarPainter extends CustomPainter {
  final Alignment moonAlignment;

  _StarPainter({required this.moonAlignment});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.4);
    final random = math.Random(42);
    
    // Calculate moon position in pixels
    final moonCenter = Offset(
      size.width / 2 + moonAlignment.x * size.width / 2,
      size.height / 2 + moonAlignment.y * size.height / 2,
    );

    // Draw more stars for a richer night sky
    for (int i = 0; i < 35; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height * 0.7; // Keep stars in upper 70%
      final double radius = random.nextDouble() * 1.5 + 0.5;

      // Twinkle variation opacity
      final double opacity = 0.2 + random.nextDouble() * 0.6;
      
      // Skip stars too close to the moon (radius ~40px + padding)
      if ((Offset(x, y) - moonCenter).distance < 65) {
        continue;
      }

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
     oldDelegate.moonAlignment != moonAlignment;
}