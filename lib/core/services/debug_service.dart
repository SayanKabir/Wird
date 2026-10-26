import 'package:flutter/foundation.dart';
import '../../models/prayer.dart';
import '../utils/moon_phase_utils.dart';
import 'prayer_service.dart';
import 'weather_service.dart';

/// Service to handle debug overrides for visual testing.
/// Singleton instance.
class DebugService {
  static final DebugService _instance = DebugService._internal();

  factory DebugService() {
    return _instance;
  }

  DebugService._internal();

  // ValueNotifiers for reactive updates
  final ValueNotifier<WeatherCondition?> overriddenWeather = ValueNotifier(null);
  final ValueNotifier<MoonPhase?> overriddenMoonPhase = ValueNotifier(null);

  /// The time the sky shows instead of now, for scrubbing through a day.
  final ValueNotifier<DateTime?> skyTime = ValueNotifier(null);

  /// Wind in km/h to blow with an overridden weather; null keeps the default.
  final ValueNotifier<double?> overriddenWind = ValueNotifier(null);

  /// Now, or the scrubbed sky time.
  DateTime now() => skyTime.value ?? DateTime.now();

  /// The prayer period at the scrubbed sky time, so the sky's prayer moments
  /// follow the slider; [actual] when nothing is scrubbed. [prayerTimes] are
  /// today's, used for any day scrubbed to, which is close enough to look at.
  PrayerPeriod periodAt(Map<Prayer, PrayerTimeData> prayerTimes, PrayerPeriod actual) {
    final time = skyTime.value;
    if (time == null) return actual;
    final shift = DateTime(time.year, time.month, time.day)
        .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    final today = time.subtract(shift);
    // Today's Tahajjud is tonight's; before Fajr the last third began the
    // night before.
    final tahajjud = prayerTimes[Prayer.tahajjud];
    final fajr = prayerTimes[Prayer.fajr];
    if (tahajjud != null && fajr != null && today.isBefore(fajr.startTime) &&
        today.isAfter(tahajjud.startTime.subtract(const Duration(days: 1)))) {
      return PrayerPeriod.tahajjud;
    }
    return PrayerService().getCurrentPrayerPeriod(prayerTimes, today);
  }

  /// Set a forced weather condition. Null to use real weather.
  void setWeather(WeatherCondition? condition) {
    overriddenWeather.value = condition;
  }

  /// Set a forced moon phase. Null to use real moon phase.
  void setMoonPhase(MoonPhase? phase) {
    overriddenMoonPhase.value = phase;
  }

  /// Reset all overrides
  void reset() {
    overriddenWeather.value = null;
    overriddenMoonPhase.value = null;
    skyTime.value = null;
    overriddenWind.value = null;
  }
}
