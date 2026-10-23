import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/haptic_service.dart';
import '../../../widgets/common/pressable.dart';

/// The "done today" circle. Tapping it again undoes the tick, so the circle
/// itself is the only feedback: it fills gold with a small pop, and a light
/// haptic lands on the way in (a softer one on the way out).
class SunnahCheck extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;
  final double size;
  final String? semanticLabel;

  const SunnahCheck({
    super.key,
    required this.done,
    required this.onTap,
    this.size = 26,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: done,
      label: semanticLabel ?? 'Done today',
      child: Pressable(
        pressedScale: 0.85,
        haptic: PressableHaptic.none,
        onTap: () {
          done ? HapticService().selection() : HapticService().light();
          onTap();
        },
        // Pad out to a comfortable hit area without growing the circle.
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.spiritualGold : Colors.transparent,
              border: Border.all(
                color: done
                    ? AppColors.spiritualGold
                    : Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: done
                  ? Icon(
                      Icons.check_rounded,
                      key: const ValueKey('done'),
                      size: size * 0.62,
                      color: const Color(0xFF3D2E00),
                    )
                  : const SizedBox.shrink(key: ValueKey('open')),
            ),
          ),
        ),
      ),
    );
  }
}
