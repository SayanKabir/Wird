import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'storage_service.dart';

/// What the device can comfortably do, read once at startup (and again when
/// the app returns to the foreground, since Battery Saver can change).
///
/// Until the user flips Reduce motion themselves, the app turns it on for
/// genuinely weak hardware and whenever the system asks apps to calm down.
class DeviceProfile with WidgetsBindingObserver {
  DeviceProfile._();
  static final DeviceProfile instance = DeviceProfile._();

  static const _channel = MethodChannel('com.SayanKabir.wird2/device');

  /// Thresholds for "seriously underpowered": the system's own low-RAM flag,
  /// 3 GB of RAM or less, or four CPU cores or fewer.
  static const int _lowRamMb = 3 * 1024;
  static const int _lowCores = 4;

  bool _lowEndHardware = false;
  bool _powerSave = false;
  bool _animationsOff = false;
  bool _initialised = false;

  /// Bumps whenever the profile changes after startup, so screens that care
  /// can rebuild (e.g. Battery Saver turned on while the app was away).
  final ValueNotifier<int> changes = ValueNotifier(0);

  bool get lowEndHardware => _lowEndHardware;
  bool get powerSave => _powerSave;
  bool get animationsOff => _animationsOff;

  /// Build with `--dart-define=WIRD_FORCE_LIGHT_VISUALS=true` to preview the
  /// lighter visuals on a capable phone.
  static const bool _forceLight = bool.fromEnvironment('WIRD_FORCE_LIGHT_VISUALS');

  /// Whether the app should default to its lighter visuals here.
  bool get prefersLightVisuals => _forceLight || _lowEndHardware || _powerSave;

  /// Why the lighter visuals are on by default, for the caption under the
  /// setting. Null when nothing applies.
  String? get reason {
    if (_powerSave) return 'On while Battery Saver is on';
    if (_lowEndHardware || _forceLight) return 'On by default for this device';
    return null;
  }

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    await _read();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    final before = (_lowEndHardware, _powerSave, _animationsOff);
    await _read();
    if (before != (_lowEndHardware, _powerSave, _animationsOff)) changes.value++;
  }

  Future<void> _read() async {
    try {
      final raw = await _channel
          .invokeMapMethod<String, dynamic>('deviceProfile')
          .timeout(const Duration(seconds: 2));
      if (raw == null) return;
      final ramMb = raw['totalRamMb'] as int? ?? 0;
      final cores = raw['cpuCores'] as int? ?? 8;
      _lowEndHardware = raw['isLowRamDevice'] == true ||
          (ramMb > 0 && ramMb <= _lowRamMb) ||
          cores <= _lowCores;
      _powerSave = raw['powerSave'] == true;
      _animationsOff = raw['animationsOff'] == true;
      debugPrint('[DeviceProfile] ram=${ramMb}MB cores=$cores lowRam=${raw['isLowRamDevice']} '
          'powerSave=$_powerSave animationsOff=$_animationsOff -> light=$prefersLightVisuals');
    } on MissingPluginException {
      // No native side (iOS, desktop, tests): assume a capable device.
    } catch (e) {
      debugPrint('[DeviceProfile] read failed: $e');
    }
  }
}

/// How much motion the app should use.
enum MotionMode {
  /// Everything: live blur, per-word folds, glows, the full-rate sky.
  full,

  /// Cheap animations only. Fades, slides, scales, ripples and the ring all
  /// stay, so nothing feels choppy; the GPU-heavy effects (live blur,
  /// offscreen layers per word, blurred glows and shadows) are swapped for
  /// flat equivalents, and the sky steps at a lower rate. The default on weak
  /// devices and under Battery Saver, or when the user turns the setting on.
  lite,

  /// Android's "Remove animations" is on: fades only, nothing moves.
  still,
}

MotionMode motionMode() {
  final profile = DeviceProfile.instance;
  if (profile.animationsOff) return MotionMode.still;
  try {
    final settings = StorageService().getSettings();
    if (settings.reduceMotionUserSet) return settings.reduceMotion ? MotionMode.lite : MotionMode.full;
  } catch (_) {
    // Storage not ready; fall through to the device default.
  }
  return profile.prefersLightVisuals ? MotionMode.lite : MotionMode.full;
}

/// Whether the expensive effects should be swapped for cheap ones (lite or
/// still). This is what the Reduce motion setting shows.
bool lighterVisuals() => motionMode() != MotionMode.full;

/// Whether movement itself should stop (system "Remove animations").
bool motionStill() => motionMode() == MotionMode.still;
