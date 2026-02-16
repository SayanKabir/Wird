import 'package:flutter/foundation.dart';
import '../utils/moon_phase_utils.dart';
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
  }
}
