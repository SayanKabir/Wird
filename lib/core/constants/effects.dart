import '../../models/settings.dart';
import '../services/device_profile.dart';
import '../services/storage_service.dart';

/// What the current visuals level allows the UI to do.
///
/// The level itself comes from [motionMode], which weighs the device profile,
/// Reduce motion and the Performance choice in Settings. This adds the one
/// distinction motionMode doesn't make: Balanced keeps the full effects but
/// skips entrance motion.
///
/// | Level            | Frosted glass | Living sky | Entrance motion |
/// |------------------|---------------|------------|-----------------|
/// | Lite (or still)  | no            | no         | no              |
/// | Balanced         | yes           | yes        | no              |
/// | Smooth / Auto*   | yes           | yes        | yes             |
///
/// *Auto behaves as Lite on weak devices and under Battery Saver.
class AppEffects {
  AppEffects._();

  static PerformanceMode get mode {
    try {
      return PerformanceMode.fromKey(StorageService().getSettings().performanceMode);
    } catch (_) {
      return PerformanceMode.auto;
    }
  }

  /// Whether surfaces may use a live BackdropFilter.
  static bool get blur => !lighterVisuals();

  /// Whether the sky, weather particles and other ambient loops may animate.
  static bool get ambientMotion => !lighterVisuals();

  /// Whether content may fade and slide in as a page opens.
  static bool get entranceMotion =>
      !lighterVisuals() && mode != PerformanceMode.balanced;
}
