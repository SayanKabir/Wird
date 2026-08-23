import 'package:flutter/services.dart';

import 'storage_service.dart';

/// Single entry point for tactile feedback.
///
/// Two reasons this exists rather than calling [HapticFeedback] directly:
///
/// 1. **It can be switched off.** Every call checks
///    `AppSettings.hapticsEnabled`, so the toggle in Settings silences the whole
///    app rather than each call site needing to remember to check.
/// 2. **It is deliberately softer than the platform defaults.** The app
///    previously fired `mediumImpact` and `heavyImpact` for routine taps, which
///    reads as buzzy over a long session. Each level here maps down one step —
///    see [_fire]. Call sites keep their original intent (light/medium/heavy);
///    the softening happens in one place and can be retuned in one place.
class HapticService {
  static HapticService? _instance;
  factory HapticService({StorageService? storageService}) {
    _instance ??= HapticService._internal(storageService ?? StorageService());
    return _instance!;
  }
  HapticService._internal(this._storageService);

  final StorageService _storageService;

  bool get _enabled {
    try {
      return _storageService.getSettings().hapticsEnabled;
    } catch (_) {
      // Storage not open yet (very early startup) — stay quiet rather than throw.
      return false;
    }
  }

  /// Lightest feedback: moving through a list, toggling a chip.
  void selection() => _fire(_Level.selection);

  /// A normal tap: buttons, tiles, navigation.
  void light() => _fire(_Level.light);

  /// A confirmation: saving, completing, committing a change.
  void medium() => _fire(_Level.medium);

  /// Reserved for genuinely significant moments — completing a dhikr cycle,
  /// finishing onboarding. Still softened relative to the platform default.
  void heavy() => _fire(_Level.heavy);

  void _fire(_Level level) {
    if (!_enabled) return;
    switch (level) {
      // Each case is one step gentler than its name suggests.
      case _Level.selection:
      case _Level.light:
        HapticFeedback.selectionClick();
      case _Level.medium:
        HapticFeedback.lightImpact();
      case _Level.heavy:
        HapticFeedback.mediumImpact();
    }
  }
}

enum _Level { selection, light, medium, heavy }
