import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/sky_ephemeris.dart';

/// The sky at a real moment and place: its colours, and where the sun and
/// moon sit on screen.
///
/// The app's seven prayer palettes stay the look of the sky, but instead of
/// one per prayer period, each is pinned to a height of the sun (Fajr's to
/// dawn twilight, Maghrib's to just after sunset, and so on) and the sky
/// blends between them as the sun moves, so 12:10 and 15:20 no longer look
/// the same. Morning and evening use different palettes at equal heights.
class LiveSky {
  final SkyEphemeris ephemeris;

  LiveSky(this.ephemeris);

  factory LiveSky.at(DateTime time, double latitude, double longitude) =>
      LiveSky(SkyEphemeris.at(time, latitude, longitude));

  double get sunAltitude => ephemeris.sunAltitude;
  double get moonAltitude => ephemeris.moonAltitude;

  /// The deep night, a little richer than Isha's and Tahajjud's period
  /// palettes: those start from a grey slate that looks washed out once the
  /// sky sits on them for hours. Onboarding keeps the originals.
  static const _ishaNight = [Color(0xFF1F2E52), Color(0xFF171A3A), Color(0xFF121B3D)];
  static const _tahajjudNight = [Color(0xFF15163A), Color(0xFF111B44), Color(0xFF0C2A63)];

  /// Every palette is resampled to this many stops so any two blend evenly.
  static const _stops = 5;

  /// Height of the sun as a share of today's peak, 0 at or below the horizon.
  double get _dayFraction {
    final peak = ephemeris.sunPeakAltitude;
    if (peak <= 1) return 0;
    return (sunAltitude / peak).clamp(0.0, 1.0);
  }

  /// Top-to-bottom gradient colours, [_stops] of them.
  ///
  /// [lastThird] is 0..1: how far the deep night has turned from Isha's
  /// palette to Tahajjud's, which marks the last third of the night. It is 1
  /// from the start of the last third until the dawn palettes take over.
  List<Color> gradient({required double lastThird}) {
    final alt = sunAltitude;
    final f = _dayFraction;

    var c = _mix(
      _sample(_ishaNight),
      _sample(_tahajjudNight),
      lastThird,
    );

    if (ephemeris.morning) {
      c = _mix(c, _sample(AppColors.fajrGradient), _smooth(-18, -12, alt));
      c = _mix(c, _sample(AppColors.sunriseGradient), _smooth(-1, 4, alt));
      c = _mix(c, _sample(AppColors.dhuhrGradient), _smooth(0.35, 0.75, f));
    } else {
      c = _mix(c, _sample(AppColors.maghribGradient), _smooth(-17, -7, alt));
      c = _mix(c, _sample(AppColors.asrGradient), _smooth(-0.5, 6, alt));
      c = _mix(c, _sample(AppColors.dhuhrGradient), _smooth(0.55, 0.85, f));
    }
    return c;
  }

  /// 1 once the sky is dark enough for stars, 0 by civil twilight.
  double get darkness => 1 - _smooth(-15, -7, sunAltitude);

  /// How much the moon's light hides the fainter stars.
  double get moonWash =>
      ephemeris.moonIllumination * _smooth(-4, 10, moonAltitude);

  /// Weather drawn for night: darker clouds, moonlit fog.
  bool get isNight => sunAltitude < -6;

  bool get sunVisible => sunAltitude > -3;

  /// Below this the moon has sunk into the horizon haze.
  bool get moonVisible =>
      moonAltitude > -4 && ephemeris.moonIllumination > 0.02;

  /// The moon by day is a pale ghost of itself.
  double get moonOpacity => 1 - 0.6 * _smooth(-4, 8, sunAltitude);

  /// Gold overhead, red-orange as it nears the horizon.
  Color get sunColor => Color.lerp(
        const Color(0xFFFF7E5F),
        const Color(0xFFFDB813),
        _smooth(0, 14, sunAltitude),
      )!;

  Color get sunGlow => Color.lerp(
        const Color(0xFFFF4757).withValues(alpha: 0.5),
        const Color(0xFFFDB813).withValues(alpha: 0.4),
        _smooth(0, 14, sunAltitude),
      )!;

  /// A little larger and brighter near noon, as before.
  double get sunSize => 70 + 10 * _smooth(0.6, 1, _dayFraction);

  Alignment get sunAlignment =>
      _place(sunAltitude, ephemeris.sunAzimuth);
  Alignment get moonAlignment =>
      _place(moonAltitude, ephemeris.moonAzimuth);

  /// Sky position to screen, as if looking up at a dome: things rise on the
  /// right and set on the left, as the sky has always been drawn here, and
  /// travel a smooth arc between. Across, sin(azimuth) gives east +1 and west
  /// -1 in both hemispheres, narrowed by cos(altitude) so a body high in the
  /// sky comes in toward the middle instead of racing sideways. Up, the
  /// height is measured against today's sun so a low winter sun still climbs
  /// well up, and eases off near the top so nothing runs flat along it or
  /// behind the header. The horizon sits where the haze begins.
  Alignment _place(double altitude, double azimuth) {
    final rad = math.pi / 180;
    final x = math.sin(azimuth * rad) * math.cos(altitude * rad) * 0.9;
    final reach = math.sin(math.max(ephemeris.sunPeakAltitude, 50.0) * rad);
    final f = math.sin(math.max(altitude, -30.0) * rad) / reach;
    // Linear up to 0.8 of the way, then a soft shoulder that never quite
    // reaches 1.
    final lift = f < 0.8 ? f : 0.8 + 0.2 * _tanh((f - 0.8) / 0.2);
    return Alignment(x, 0.4 - lift * 0.95);
  }

  static double _tanh(double v) {
    final e = math.exp(2 * v);
    return (e - 1) / (e + 1);
  }

  static double _smooth(double a, double b, double v) {
    final k = ((v - a) / (b - a)).clamp(0.0, 1.0);
    return k * k * (3 - 2 * k);
  }

  /// [colors] as an evenly spread gradient, read back at [_stops] points.
  static List<Color> _sample(List<Color> colors) {
    return List.generate(_stops, (i) {
      final p = i / (_stops - 1) * (colors.length - 1);
      final lo = p.floor().clamp(0, colors.length - 1);
      final hi = math.min(lo + 1, colors.length - 1);
      return Color.lerp(colors[lo], colors[hi], p - lo)!;
    });
  }

  static List<Color> _mix(List<Color> a, List<Color> b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    return [for (var i = 0; i < a.length; i++) _blend(a[i], b[i], t)];
  }

  /// Blends two colours in Oklab, a colour space laid out the way eyes see
  /// colour. A straight line there goes from one colour to the other without
  /// sweeping through other hues (no rainbow bands) and without the grey dip
  /// of mixing RGB numbers directly.
  static Color _blend(Color a, Color b, double t) {
    final la = _toOklab(a), lb = _toOklab(b);
    return _fromOklab([for (var k = 0; k < 3; k++) la[k] + (lb[k] - la[k]) * t], a.a + (b.a - a.a) * t);
  }

  static double _toLinear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  static double _toSrgb(double c) {
    final v = c <= 0.0031308 ? c * 12.92 : 1.055 * math.pow(c, 1 / 2.4) - 0.055;
    return v.clamp(0.0, 1.0);
  }

  static double _cbrt(double v) => v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();

  static List<double> _toOklab(Color c) {
    final r = _toLinear(c.r), g = _toLinear(c.g), b = _toLinear(c.b);
    final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return [
      0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    ];
  }

  static Color _fromOklab(List<double> lab, double alpha) {
    final l = math.pow(lab[0] + 0.3963377774 * lab[1] + 0.2158037573 * lab[2], 3).toDouble();
    final m = math.pow(lab[0] - 0.1055613458 * lab[1] - 0.0638541728 * lab[2], 3).toDouble();
    final s = math.pow(lab[0] - 0.0894841775 * lab[1] - 1.2914855480 * lab[2], 3).toDouble();
    return Color.from(
      alpha: alpha,
      red: _toSrgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
      green: _toSrgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
      blue: _toSrgb(-0.0041960863 * l - 0.0703418340 * m + 1.7076956419 * s),
    );
  }
}
