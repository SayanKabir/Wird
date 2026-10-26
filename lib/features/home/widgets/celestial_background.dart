import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/durations.dart';
import 'package:wird2/core/constants/colors.dart';
import 'package:wird2/core/services/debug_service.dart';
import 'package:wird2/core/services/prayer_service.dart';
import 'package:wird2/core/utils/moon_phase_utils.dart';
import 'package:wird2/core/services/weather_service.dart';
import 'package:wird2/features/home/widgets/weather_overlay.dart';
import 'package:wird2/features/home/widgets/live_sky.dart';

/// Animated celestial background with realistic Horizon Arc physics
class CelestialBackground extends StatefulWidget {
  final PrayerPeriod prayerPeriod;
  final bool reduceMotion;

  /// Lighter visuals: the sky keeps moving but steps at a lower rate.
  final bool lite;

  /// How visible the sun or moon is (1 = full). Lets a screen dim it without
  /// rebuilding the whole background.
  final ValueListenable<double>? celestialOpacity;
  final Widget child;
  final WeatherCondition weatherCondition;
  final int cloudCoverage;

  /// km/h. With the live sky it sets how fast clouds drift and how the rain
  /// slants.
  final double windSpeed;

  /// When the current prayer's adhan was. Opened soon after it (from the
  /// adhan notification, say), the live sky greets the prayer with a swell
  /// of light, as it does when the time arrives on screen.
  final DateTime? adhanAt;
  final double latitude;

  /// With a longitude the sky follows the real sun and moon over this place
  /// (see [LiveSky]); without one it follows [prayerPeriod], which is how
  /// onboarding walks through a whole day in a few pages. In [lite] it always
  /// follows the period: a still sky that changes five times a day.
  final double? longitude;
  final MoonPhase? fixedMoonPhase;
  final bool showCelestialBody;

  /// How long the sky takes to move to a new period. The home screen keeps
  /// the slow default; onboarding walks through a whole day, so it's quicker.
  final Duration transitionDuration;

  const CelestialBackground({
    super.key,
    required this.prayerPeriod,
    required this.child,
    this.reduceMotion = false,
    this.lite = false,
    this.celestialOpacity,
    this.weatherCondition = WeatherCondition.clear,
    this.cloudCoverage = 0,
    this.windSpeed = 0,
    this.adhanAt,
    this.latitude = 0.0,
    this.longitude,
    this.fixedMoonPhase,
    this.showCelestialBody = true,
    this.transitionDuration = const Duration(milliseconds: 12000),
  });

  @override
  State<CelestialBackground> createState() => _CelestialBackgroundState();
}

class _CelestialBackgroundState extends State<CelestialBackground>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _animation;

  List<Color> _currentColors = AppColors.ishaGradient;
  List<Color> _targetColors = AppColors.ishaGradient;

  /// The real sky, refreshed by [_clock]. Null when following the period.
  LiveSky? _live;
  Timer? _clock;

  /// Isha's night turning into the last third's, over half a minute, when
  /// the Tahajjud period begins. Idle (and free) the rest of the time.
  late final AnimationController _lastThird = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
    value: _lastThirdTarget,
  );

  /// One swell of light from the horizon as a prayer's time comes.
  late final AnimationController _swell = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  /// Tahajjud's palette holds through Fajr too, so the dawn colours rise out
  /// of it rather than out of Isha's.
  double get _lastThirdTarget =>
      widget.prayerPeriod == PrayerPeriod.tahajjud || widget.prayerPeriod == PrayerPeriod.fajr ? 1 : 0;

  static const _adhanPeriods = {
    PrayerPeriod.fajr,
    PrayerPeriod.dhuhr,
    PrayerPeriod.asr,
    PrayerPeriod.maghrib,
    PrayerPeriod.isha,
  };

  /// How long after the adhan opening the app still greets the prayer.
  static const _swellWindow = Duration(minutes: 15);

  void _greetPrayer() {
    if (_live == null || widget.reduceMotion) return;
    if (!_adhanPeriods.contains(widget.prayerPeriod)) return;
    _swell.forward(from: 0);
  }

  /// The sun climbs about a quarter of a degree a minute, roughly 2 dp on
  /// screen, so every two minutes it steps about 5 dp: less than a tenth of
  /// its own width, too little to catch, and the colours shift less still.
  /// Each refresh repaints the sky and re-blurs the glass above it, which
  /// costs far more than the astronomy, so refreshes are kept rare.
  static const _clockStep = Duration(minutes: 2);

  /// The debug moon phase needs the period sky, where the moon always shows.
  /// Lighter visuals keep the period sky: no clock, no astronomy.
  bool get _followsRealSky =>
      widget.longitude != null && widget.fixedMoonPhase == null && !widget.lite;

  void _syncLiveSky() {
    if (_followsRealSky) {
      _live = LiveSky.at(DebugService().now(), widget.latitude, widget.longitude!);
      _clock ??= Timer.periodic(_clockStep, (_) {
        if (mounted) setState(_syncLiveSky);
      });
    } else {
      _live = null;
      _clock?.cancel();
      _clock = null;
    }
  }

  /// The debug time slider moved.
  void _onSkyTime() {
    if (mounted && _live != null) setState(_syncLiveSky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_live == null) return;
    if (state == AppLifecycleState.resumed) {
      // Back from the background the sky may be hours out of date.
      setState(_syncLiveSky);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // Nobody can see it; don't wake up to redraw it.
      _clock?.cancel();
      _clock = null;
    }
  }

  @override
  void initState() {
    super.initState();

    // 12s by default, for a very slow, majestic celestial transition
    _controller = AnimationController(
      duration: widget.reduceMotion
          ? Duration.zero
          : widget.transitionDuration,
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
    WidgetsBinding.instance.addObserver(this);
    _syncLiveSky();
    // Created now, so it starts from this period rather than the next one.
    _lastThird;
    DebugService().skyTime.addListener(_onSkyTime);

    final adhan = widget.adhanAt;
    if (adhan != null) {
      final since = DebugService().now().difference(adhan);
      if (!since.isNegative && since < _swellWindow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _greetPrayer();
        });
      }
    }
  }

  @override
  void didUpdateWidget(CelestialBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.longitude != widget.longitude ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.lite != widget.lite ||
        oldWidget.fixedMoonPhase != widget.fixedMoonPhase) {
      final wasLive = _live != null;
      _syncLiveSky();
      // Into the period sky (lighter visuals turned on): start from this
      // period's colours, not whatever the period sky last showed.
      if (wasLive && _live == null) {
        _targetColors = AppColors.getGradientForPeriod(widget.prayerPeriod);
        _currentColors = _targetColors;
      }
    }

    if (oldWidget.prayerPeriod != widget.prayerPeriod) {
      if (widget.reduceMotion) {
        _lastThird.value = _lastThirdTarget;
      } else {
        _lastThird.animateTo(_lastThirdTarget, curve: Curves.easeInOutSine);
      }
      _greetPrayer();
    }

    // The real sky moves on its own; only the period sky crossfades.
    if (_live == null && oldWidget.prayerPeriod != widget.prayerPeriod) {
      _currentColors = _getCurrentGradient();
      _targetColors = AppColors.getGradientForPeriod(widget.prayerPeriod);

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DebugService().skyTime.removeListener(_onSkyTime);
    _clock?.cancel();
    _lastThird.dispose();
    _swell.dispose();
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

  Widget _dimmable(Widget body) {
    final opacity = widget.celestialOpacity;
    if (opacity == null) return body;
    return ValueListenableBuilder<double>(
      valueListenable: opacity,
      child: body,
      builder: (context, value, child) => AnimatedOpacity(
        opacity: value,
        duration: AppDurations.tabFade,
        curve: AppCurves.emphasized,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = _live;
    if (live != null) {
      return AnimatedBuilder(
        animation: Listenable.merge([_lastThird, _swell]),
        builder: (context, _) => _buildLive(context, live),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final night = _isNightTime(widget.prayerPeriod);
        final alignment = _calculateCelestialAlignment(_animation.value);
        return _scene(
          context,
          colors: _getCurrentGradient(),
          isNight: night,
          moonAlignment: alignment,
          starDarkness: night ? 1 : 0,
          starBoost: 0,
          moonWash: night ? MoonPhaseUtils.getIllumination(DateTime.now()) : 0,
          light: null,
          bodies: [
            if (widget.showCelestialBody)
              Align(
                alignment: alignment,
                child: _dimmable(
                  _CelestialBody(
                    prayerPeriod: widget.fixedMoonPhase != null ? PrayerPeriod.isha : widget.prayerPeriod,
                    reduceMotion: widget.reduceMotion,
                    latitude: widget.latitude,
                    fixedMoonPhase: widget.fixedMoonPhase,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// The sky over the user right now: the sun and moon where they really
  /// are, the moon lit from the sun's side and pale by day.
  Widget _buildLive(BuildContext context, LiveSky live) {
    final size = MediaQuery.sizeOf(context);
    final sun = live.sunAlignment;
    final moon = live.moonAlignment;
    // The lit limb faces the sun. The painter lights the right side of a
    // waxing moon and the left of a waning one, so turn it toward the sun.
    final toSun = math.atan2(
      (sun.y - moon.y) * size.height,
      (sun.x - moon.x) * size.width,
    );
    final phase = live.ephemeris.moonPhase;

    // The young crescent of a new month, just after sunset.
    final hilal = phase > 0.012 && phase < 0.1 && live.sunAltitude < 0;

    return _scene(
      context,
      colors: live.gradient(lastThird: _lastThird.value),
      isNight: live.isNight,
      moonAlignment: moon,
      starDarkness: live.darkness,
      starBoost: _lastThird.value,
      moonWash: live.moonWash,
      light: SkyLight(
        sunColor: live.sunColor,
        sun: sun,
        sunAltitude: live.sunAltitude,
        moonlight: live.moonWash,
        windSpeed: widget.windSpeed,
      ),
      bodies: [
        Positioned.fill(
          child: CustomPaint(
            painter: _HorizonGlow(
              sunX: sun.x,
              sunAltitude: live.sunAltitude,
              sunColor: live.sunColor,
            ),
          ),
        ),
        if (_swell.isAnimating)
          Positioned.fill(
            child: CustomPaint(
              painter: _AdhanSwell(
                t: _swell.value,
                color: widget.prayerPeriod == PrayerPeriod.isha
                    ? const Color(0xFFCFD8FF)
                    : const Color(0xFFFFE2A0),
              ),
            ),
          ),
        if (widget.showCelestialBody && live.moonVisible && hilal)
          Align(
            alignment: moon,
            child: _dimmable(
              const SizedBox.square(dimension: 120, child: CustomPaint(painter: _HilalRing())),
            ),
          ),
        if (widget.showCelestialBody && live.moonVisible)
          Align(
            alignment: moon,
            child: _dimmable(
              Opacity(
                opacity: live.moonOpacity,
                child: SizedBox.square(
                  dimension: 70,
                  child: Transform.rotate(
                    angle: phase <= 0.5 ? toSun : toSun - math.pi,
                    child: CustomPaint(
                      painter: _MoonPainter(
                        phaseValue: phase,
                        moonColor: const Color(0xFFF8FAFC),
                        glowColor: Colors.white.withValues(
                          alpha: (0.4 + live.ephemeris.moonIllumination * 0.4) * live.darkness,
                        ),
                        earthshine: live.darkness,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (widget.showCelestialBody && live.sunVisible)
          Align(
            alignment: sun,
            child: _dimmable(
              _Sun(size: live.sunSize, color: live.sunColor, glow: live.sunGlow),
            ),
          ),
      ],
    );
  }

  /// Gradient, stars, sun and moon, weather and horizon haze, under the
  /// screen's own content.
  Widget _scene(
    BuildContext context, {
    required List<Color> colors,
    required bool isNight,
    required Alignment moonAlignment,
    required double starDarkness,
    required double starBoost,
    required double moonWash,
    required SkyLight? light,
    required List<Widget> bodies,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: _generateStops(colors.length),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Stars, behind everything else in the sky
          if (starDarkness > 0.01)
            Positioned.fill(
              child: RepaintBoundary(
                child: _StarField(
                  moonAlignment: moonAlignment,
                  darkness: starDarkness,
                  boost: starBoost,
                  moonWash: moonWash,
                ),
              ),
            ),

          // 2. The sun and moon
          ...bodies,

          // 3. Weather
          WeatherOverlay(
            condition: widget.weatherCondition,
            cloudCoverage: widget.cloudCoverage,
            reduceMotion: widget.reduceMotion,
            lite: widget.lite,
            isNight: isNight,
            light: light,
          ),

          // 4. Horizon haze. Fades the lower sky into its last colour, so a
          // sun or moon below about Y = 0.4 sinks into it as if behind the
          // horizon.
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
                      colors.last.withOpacity(0.0),
                      colors.last.withOpacity(0.9),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 5. The screen's content
          widget.child,
        ],
      ),
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
                  earthshine: 1,
                ),
              ),
            )
          : _Sun(size: size, color: isSunset ? sunsetColor : sunColor, glow: glowColor),
    );
  }

  bool _isNight(PrayerPeriod p) =>
      p == PrayerPeriod.isha || p == PrayerPeriod.tahajjud;
}

/// A swell of light rising from the horizon and settling again as a
/// prayer's time comes: [t] runs 0..1 over the swell.
class _AdhanSwell extends CustomPainter {
  final double t;
  final Color color;

  const _AdhanSwell({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Rises over the first third, then settles slowly.
    final strength = math.pow(math.sin(math.pi * math.pow(t, 0.6)), 1.5).toDouble();
    if (strength < 0.01) return;
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = size.height * (0.55 + 0.25 * t);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.34 * strength),
            color.withValues(alpha: 0.12 * strength),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _AdhanSwell old) => old.t != t || old.color != color;
}

/// A faint gold ring around the new crescent: the hilal that opens a
/// Hijri month.
class _HilalRing extends CustomPainter {
  const _HilalRing();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.spiritualGold.withValues(alpha: 0.4),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AppColors.spiritualGold.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _HilalRing old) => false;
}

/// Light along the horizon around sunrise and sunset: a warm glow where the
/// sun is, and on the opposite horizon the pink Belt of Venus, sunlight still
/// catching the upper air after the ground is in shade. Both fade out once
/// the sun is high or deep below the horizon.
class _HorizonGlow extends CustomPainter {
  /// The sun's screen alignment across, -1 left (west) .. 1 right (east).
  final double sunX;
  final double sunAltitude;
  final Color sunColor;

  const _HorizonGlow({required this.sunX, required this.sunAltitude, required this.sunColor});

  /// Where the haze begins, as a share of the height (Alignment y 0.4).
  static const _horizon = 0.7;

  static double _smooth(double a, double b, double v) {
    final k = ((v - a) / (b - a)).clamp(0.0, 1.0);
    return k * k * (3 - 2 * k);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * _horizon;

    // Glow under the sun: strongest as it crosses the horizon.
    final glow = _smooth(-12, -2, sunAltitude) * (1 - _smooth(4, 16, sunAltitude));
    if (glow > 0.01) {
      final center = Offset(size.width / 2 + sunX.clamp(-1.0, 1.0) * size.width / 2, horizonY);
      final radius = size.width * 1.1;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [sunColor.withValues(alpha: 0.5 * glow), sunColor.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Belt of Venus: a low pink band opposite the sun, in civil twilight.
    final belt = _smooth(-7, -3, sunAltitude) * (1 - _smooth(0, 4, sunAltitude));
    if (belt > 0.01) {
      final center = Offset(size.width / 2 - sunX.clamp(-1.0, 1.0) * size.width / 2, horizonY - size.height * 0.09);
      final radius = size.width * 0.95;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1, 0.16);
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFFF29BB5).withValues(alpha: 0.28 * belt), const Color(0x00F29BB5)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HorizonGlow old) =>
      old.sunX != sunX || old.sunAltitude != sunAltitude || old.sunColor != sunColor;
}

class _Sun extends StatelessWidget {
  final double size;
  final Color color;
  final Color glow;

  const _Sun({required this.size, required this.color, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: glow, blurRadius: 50, spreadRadius: 15)],
      ),
    );
  }
}

/// Moon phase painter — draws proper crescent/gibbous shape with matching glow
class _MoonPainter extends CustomPainter {
  final double phaseValue; // 0.0 = new, 0.5 = full, 1.0 = new
  final Color moonColor;
  final Color glowColor;

  /// 0..1: how dark the sky is. At night the unlit part of a crescent shows
  /// faintly by sunlight bounced off the Earth, and a halo spreads around the
  /// moon that grows with its phase.
  final double earthshine;

  _MoonPainter({
    required this.phaseValue,
    required this.moonColor,
    required this.glowColor,
    this.earthshine = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final illumination = (1 - math.cos(phaseValue * 2 * math.pi)) / 2;

    if (earthshine > 0) {
      final haloRadius = radius * (2.2 + illumination * 2.5);
      canvas.drawCircle(
        center,
        haloRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFDCE6FF).withValues(alpha: (0.03 + 0.07 * illumination) * earthshine),
              const Color(0x00DCE6FF),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: haloRadius)),
      );
      // Only a crescent shows earthshine; past the quarters the lit part
      // outshines it.
      final shine = (1 - illumination / 0.45).clamp(0.0, 1.0) * earthshine;
      if (shine > 0) {
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFF94A3C8).withValues(alpha: 0.16 * shine),
        );
      }
    }

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
      oldDelegate.phaseValue != phaseValue ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.earthshine != earthshine;
}

/// The stars, still: the faint ones vanish under a bright moon and in
/// twilight, and all of them shine a little brighter in the last third of
/// the night. Painted once per change, so they cost nothing between.
class _StarField extends StatelessWidget {
  final Alignment moonAlignment;

  /// 0..1: how dark the sky is.
  final double darkness;

  /// 0..1: how much moonlight is washing out the fainter stars.
  final double moonWash;

  /// 0..1: the last third of the night, when every star shines a little
  /// brighter.
  final double boost;

  const _StarField({
    required this.moonAlignment,
    required this.darkness,
    required this.moonWash,
    this.boost = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarPainter(
        moonAlignment: moonAlignment,
        darkness: darkness,
        moonWash: moonWash,
        boost: boost,
      ),
    );
  }
}

class _Star {
  final double x, y, radius;

  /// 0..1. Bright stars survive moonlight and twilight longest.
  final double brightness;
  final double rate, offset;

  const _Star(this.x, this.y, this.radius, this.brightness, this.rate, this.offset);

  /// Fixed seed, so the sky keeps its constellations between launches.
  static final List<_Star> sky = () {
    final random = math.Random(42);
    return List.generate(90, (_) {
      final brightness = math.pow(random.nextDouble(), 1.6).toDouble();
      return _Star(
        random.nextDouble(),
        random.nextDouble() * 0.7, // upper 70%, above the haze
        0.4 + brightness * 1.3,
        brightness,
        0.6 + random.nextDouble() * 1.8,
        random.nextDouble() * math.pi * 2,
      );
    });
  }();
}

class _StarPainter extends CustomPainter {
  final Alignment moonAlignment;
  final double darkness;
  final double moonWash;
  final double boost;

  _StarPainter({
    required this.moonAlignment,
    required this.darkness,
    required this.moonWash,
    this.boost = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final moonCenter = Offset(
      size.width / 2 + moonAlignment.x * size.width / 2,
      size.height / 2 + moonAlignment.y * size.height / 2,
    );

    for (final star in _Star.sky) {
      final position = Offset(star.x * size.width, star.y * size.height);
      // Keep clear of the moon and its glow
      if ((position - moonCenter).distance < 65) continue;

      var opacity = (0.2 + star.brightness * 0.65) * darkness;
      opacity *= 1 - moonWash * 0.85 * (1 - star.brightness);
      opacity = math.min(1.0, opacity * (1 + 0.25 * boost));
      if (opacity < 0.02) continue;

      canvas.drawCircle(position, star.radius, paint..color = Colors.white.withValues(alpha: opacity));
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.moonAlignment != moonAlignment ||
      oldDelegate.darkness != darkness ||
      oldDelegate.moonWash != moonWash ||
      oldDelegate.boost != boost;
}
