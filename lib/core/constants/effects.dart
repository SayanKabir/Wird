import '../../models/settings.dart';
import '../services/storage_service.dart';

/// What the current [PerformanceMode] allows the UI to do.
///
/// Widgets ask here rather than reading the setting themselves, so what "Lite"
/// means is decided in one place:
///
/// | Mode     | Frosted glass | Living sky | Entrance motion |
/// |----------|---------------|------------|-----------------|
/// | Lite     | no            | no         | no              |
/// | Balanced | yes           | yes        | no              |
/// | Smooth   | yes           | yes        | yes             |
///
/// The separate Reduce Motion switch is an accessibility preference and also
/// stills the sky and entrance motion, whatever the mode.
class AppEffects {
  AppEffects._();

  static AppSettings get _settings {
    try {
      return StorageService().getSettings();
    } catch (_) {
      return const AppSettings();
    }
  }

  static PerformanceMode get mode =>
      PerformanceMode.fromKey(_settings.performanceMode);

  /// Whether surfaces may use a [BackdropFilter]. Each one costs an offscreen
  /// gaussian pass per frame, which is what makes older phones stutter.
  static bool get blur => mode != PerformanceMode.lite;

  /// Whether the sky, weather particles and other ambient loops may animate.
  static bool get ambientMotion =>
      mode != PerformanceMode.lite && !_settings.reduceMotion;

  /// Whether content may fade and slide in as a page opens.
  static bool get entranceMotion =>
      mode == PerformanceMode.smooth && !_settings.reduceMotion;
}
