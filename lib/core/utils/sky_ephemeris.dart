import 'dart:math' as math;

/// Where the sun and moon are in the sky at a moment and place.
///
/// Low-precision formulas (the Astronomical Almanac's for the sun, the
/// largest few terms of Meeus ch. 47 for the moon): good to about a degree
/// for the sun and two for the moon, far finer than a sky drawn on a phone
/// can show, and cheap enough to run on every repaint.
class SkyEphemeris {
  /// Sun altitude above the horizon and azimuth from north toward east,
  /// both in degrees.
  final double sunAltitude;
  final double sunAzimuth;
  final double moonAltitude;
  final double moonAzimuth;

  /// 0 = new moon, 0.5 = full, 1 = the next new moon; from the moon's real
  /// elongation, so it agrees with where the moon is drawn.
  final double moonPhase;

  /// The sun's hour angle in degrees, -180..180: negative before solar noon,
  /// positive after. Tells a rising sun from a setting one at equal height.
  final double sunHourAngle;

  /// How high the sun gets today (upper culmination), in degrees.
  final double sunPeakAltitude;

  const SkyEphemeris._({
    required this.sunAltitude,
    required this.sunAzimuth,
    required this.moonAltitude,
    required this.moonAzimuth,
    required this.moonPhase,
    required this.sunHourAngle,
    required this.sunPeakAltitude,
  });

  /// Lit fraction of the moon's disc, 0..1.
  double get moonIllumination => (1 - math.cos(moonPhase * 2 * math.pi)) / 2;

  bool get morning => sunHourAngle < 0;

  factory SkyEphemeris.at(DateTime time, double latitude, double longitude) {
    // Days since J2000.0 (2000-01-01 12:00 TT; UT is close enough here).
    final d = time.toUtc().difference(_j2000).inMilliseconds / 86400000.0;
    final obliquity = 23.439 - 0.0000004 * d;

    // Sun: mean longitude and anomaly, then the equation of centre.
    final g = _rad(357.529 + 0.98560028 * d);
    final q = 280.459 + 0.98564736 * d;
    final sunLon = q + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g);
    final sun = _equatorial(sunLon, 0, obliquity);

    // Moon: mean elements, then the biggest periodic terms.
    final lMoon = 218.316 + 13.176396 * d;
    final mMoon = _rad(134.963 + 13.064993 * d);
    final fMoon = _rad(93.272 + 13.229350 * d);
    final elong = _rad(297.850 + 12.190749 * d);
    final moonLon = lMoon +
        6.289 * math.sin(mMoon) +
        1.274 * math.sin(2 * elong - mMoon) +
        0.658 * math.sin(2 * elong) +
        0.214 * math.sin(2 * mMoon) -
        0.186 * math.sin(g);
    final moonLat = 5.128 * math.sin(fMoon);
    final moon = _equatorial(moonLon, moonLat, obliquity);

    // Local sidereal time turns right ascension into an hour angle.
    final lst = 280.46061837 + 360.98564736629 * d + longitude;
    final sunH = _wrap180(lst - sun.$1);
    final moonH = _wrap180(lst - moon.$1);

    final (sunAlt, sunAz) = _horizontal(sunH, sun.$2, latitude);
    var (moonAlt, moonAz) = _horizontal(moonH, moon.$2, latitude);
    // The moon is close enough for parallax to lower it by up to a degree.
    moonAlt -= 0.95 * math.cos(_rad(moonAlt));

    return SkyEphemeris._(
      sunAltitude: sunAlt,
      sunAzimuth: sunAz,
      moonAltitude: moonAlt,
      moonAzimuth: moonAz,
      moonPhase: ((moonLon - sunLon) % 360 + 360) % 360 / 360,
      sunHourAngle: sunH,
      sunPeakAltitude: 90 - (latitude - sun.$2).abs(),
    );
  }

  static final DateTime _j2000 = DateTime.utc(2000, 1, 1, 12);

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
  static double _wrap180(double deg) => ((deg + 180) % 360 + 360) % 360 - 180;

  /// Ecliptic longitude/latitude to (right ascension, declination), degrees.
  static (double, double) _equatorial(double lon, double lat, double obliquity) {
    final l = _rad(lon), b = _rad(lat), e = _rad(obliquity);
    final ra = math.atan2(math.sin(l) * math.cos(e) - math.tan(b) * math.sin(e), math.cos(l));
    final dec = math.asin(math.sin(b) * math.cos(e) + math.cos(b) * math.sin(e) * math.sin(l));
    return (_deg(ra), _deg(dec));
  }

  /// Hour angle and declination to (altitude, azimuth from north), degrees.
  static (double, double) _horizontal(double hourAngle, double dec, double latitude) {
    final h = _rad(hourAngle), d = _rad(dec), phi = _rad(latitude);
    final alt = math.asin(math.sin(phi) * math.sin(d) + math.cos(phi) * math.cos(d) * math.cos(h));
    final az = math.atan2(
      -math.cos(d) * math.sin(h),
      math.sin(d) * math.cos(phi) - math.cos(d) * math.cos(h) * math.sin(phi),
    );
    return (_deg(alt), (_deg(az) + 360) % 360);
  }
}
