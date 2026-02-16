import 'dart:math' as math;

/// Moon phase types
enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

/// Extension for display properties
extension MoonPhaseExtension on MoonPhase {
  String get displayName {
    switch (this) {
      case MoonPhase.newMoon:
        return 'New Moon';
      case MoonPhase.waxingCrescent:
        return 'Waxing Crescent';
      case MoonPhase.firstQuarter:
        return 'First Quarter';
      case MoonPhase.waxingGibbous:
        return 'Waxing Gibbous';
      case MoonPhase.fullMoon:
        return 'Full Moon';
      case MoonPhase.waningGibbous:
        return 'Waning Gibbous';
      case MoonPhase.lastQuarter:
        return 'Last Quarter';
      case MoonPhase.waningCrescent:
        return 'Waning Crescent';
    }
  }

  /// Illumination fraction (0.0 = new moon, 1.0 = full moon)
  double get illumination {
    switch (this) {
      case MoonPhase.newMoon:
        return 0.0;
      case MoonPhase.waxingCrescent:
        return 0.25;
      case MoonPhase.firstQuarter:
        return 0.5;
      case MoonPhase.waxingGibbous:
        return 0.75;
      case MoonPhase.fullMoon:
        return 1.0;
      case MoonPhase.waningGibbous:
        return 0.75;
      case MoonPhase.lastQuarter:
        return 0.5;
      case MoonPhase.waningCrescent:
        return 0.25;
    }
  }
}

/// Utility to calculate moon phase based on date
class MoonPhaseUtils {
  /// Average synodic month length in days
  static const double _synodicMonth = 29.53058770576;

  /// Reference new moon: January 6, 2000 18:14 UTC
  /// (well-established astronomical reference point)
  static final DateTime _referenceNewMoon = DateTime.utc(2000, 1, 6, 18, 14);

  /// Get the lunar age in days (0 = new moon, ~14.76 = full moon, ~29.53 = next new moon)
  static double getLunarAge(DateTime date) {
    final diff = date.toUtc().difference(_referenceNewMoon).inSeconds /
        (24 * 60 * 60); // days as double
    final age = diff % _synodicMonth;
    return age < 0 ? age + _synodicMonth : age;
  }

  /// Get the approximate moon tilt angle in radians for a given latitude
  /// This creates the "Boat Moon" effect near the equator.
  /// 
  /// Logic:
  /// - Equator (0°): Moon tilts ~90° (lit side down).
  /// - Poles (90°): Moon stands vertical (lit side side-ways).
  /// - Waxing (Evening): Lit side faces West (Sun). Tilt CW (+).
  /// - Waning (Morning): Lit side faces East (Sun). Tilt CCW (-).
  static double getMoonTilt(DateTime date, double latitude) {
    // 1. Determine base tilt magnitude (90 - abs(lat))
    // At equator (0), tilt is 90. At pole (90), tilt is 0.
    double tiltDegrees = 90 - latitude.abs();
    
    // Clamp to avoid extreme spins
    tiltDegrees = tiltDegrees.clamp(0.0, 90.0);

    // 2. Determine direction based on phase
    // Waxing (0-0.5) = Evening sky = Lit side points West (down-ish)
    // Waning (0.5-1.0) = Morning sky = Lit side points East (down-ish)
    final age = getLunarAge(date);
    final phaseVal = age / _synodicMonth;
    final isWaxing = phaseVal <= 0.5;

    // 3. Apply direction
    // Northern Hemisphere: Waxing rotates CW (+), Waning rotates CCW (-)
    // Southern Hemisphere: Logic flips because "Up" is celestial South?
    // Actually, "Boat Moon" is universal near equator.
    // Let's stick to a simple visual heuristic:
    // Waxing -> Tilt CW to point the "back" of the moon up/left, lit side down/right.
    
    double angle = tiltDegrees * (math.pi / 180);
    
    if (!isWaxing) {
      angle = -angle; // Waning tilts opposite
    }

    if (latitude < 0) {
       angle = -angle; // Flip for southern hemisphere
    }
    
    return angle;
  }

  /// Get the moon phase for a given date
  static MoonPhase getMoonPhase(DateTime date) {
    final age = getLunarAge(date);
    final phaseIndex = age / _synodicMonth; // 0.0 to 1.0

    // Adjusted thresholds to skip Quarter phases (User preference: too sharp)
    // 0.25 is First Quarter. 0.75 is Last Quarter.
    // We split the quarter range between Crescent and Gibbous.
    
    if (phaseIndex < 0.0625) return MoonPhase.newMoon;
    if (phaseIndex < 0.25) return MoonPhase.waxingCrescent;   // Extended to cover First Quarter
    if (phaseIndex < 0.4375) return MoonPhase.waxingGibbous;  // Starts after First Quarter
    if (phaseIndex < 0.5625) return MoonPhase.fullMoon;
    if (phaseIndex < 0.75) return MoonPhase.waningGibbous;    // Extended to cover Last Quarter
    if (phaseIndex < 0.9375) return MoonPhase.waningCrescent; // Starts after Last Quarter
    return MoonPhase.newMoon; // wraps around
  }

  /// Get the illumination fraction (0.0 to 1.0)
  /// More precise than the enum-based illumination
  static double getIllumination(DateTime date) {
    final age = getLunarAge(date);
    final phaseAngle = (age / _synodicMonth) * 2 * math.pi;
    return (1 - math.cos(phaseAngle)) / 2;
  }

  /// Get a phase value from 0.0 to 1.0 for rendering
  /// 0.0 = new moon, 0.5 = full moon, 1.0 = next new moon
  static double getPhaseValue(DateTime date) {
    final age = getLunarAge(date);
    return age / _synodicMonth;
  }
}
