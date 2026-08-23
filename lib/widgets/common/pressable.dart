import 'package:flutter/material.dart';

import '../../core/constants/durations.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/storage_service.dart';

/// Wraps a tappable element so it responds to touch instead of sitting inert:
/// it scales down slightly while held and springs back on release, and fires the
/// app's (softened) haptic.
///
/// Use this in place of a bare [GestureDetector]/[InkWell] for buttons, icons,
/// cards and list rows. Keeping the behaviour in one widget means the whole app
/// shares a single press feel, and it can be retuned centrally.
///
/// Honours `AppSettings.reduceMotion` — when the user has asked for less motion
/// the scale is skipped entirely and the child is returned with plain tap
/// handling, so nothing moves but everything still works.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// How far to shrink while held. Smaller elements need a deeper press to read
  /// as movement; large cards need very little.
  final double pressedScale;

  /// Which haptic level to fire on tap. Null fires none — useful when the
  /// callback itself already triggers feedback.
  final PressableHaptic haptic;

  /// Expands the hit area to the full bounds of the child, including any
  /// transparent padding.
  final HitTestBehavior behavior;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.94,
    this.haptic = PressableHaptic.light,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

enum PressableHaptic { none, selection, light, medium, heavy }

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _reduceMotion {
    try {
      return StorageService().getSettings().reduceMotion;
    } catch (_) {
      return false;
    }
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    switch (widget.haptic) {
      case PressableHaptic.none:
        break;
      case PressableHaptic.selection:
        HapticService().selection();
      case PressableHaptic.light:
        HapticService().light();
      case PressableHaptic.medium:
        HapticService().medium();
      case PressableHaptic.heavy:
        HapticService().heavy();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;

    return GestureDetector(
      behavior: widget.behavior,
      onTap: enabled ? _handleTap : null,
      onLongPress: widget.onLongPress,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: _reduceMotion
          ? widget.child
          : AnimatedScale(
              scale: _pressed ? widget.pressedScale : 1.0,
              duration: AppDurations.press,
              // Ease out on the way down, spring slightly on the way back so the
              // release feels responsive rather than mushy.
              curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
              child: widget.child,
            ),
    );
  }
}
