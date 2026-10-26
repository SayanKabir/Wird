import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/durations.dart';
import '../../core/constants/radii.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/athan_cue_service.dart';
import 'glass_panel.dart';

/// The phrase of the call now playing, in Arabic with its meaning, fading
/// in over the page while the clip sounds.
class AthanCueCaption extends StatelessWidget {
  const AthanCueCaption({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CuePhrase?>(
      valueListenable: AthanCueService.instance.playing,
      builder: (context, phrase, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: AppCurves.emphasized,
        switchOutCurve: AppCurves.exit,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -0.15), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: phrase == null
            ? const SizedBox.shrink()
            // Two lines, since the shahada and its meaning are too long to
            // share one.
            : GlassPanel(
                key: ValueKey(phrase),
                radius: AppRadii.group,
                fill: 0.12,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      phrase.arabic,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.arabic(size: 18, color: AppColors.spiritualGold).copyWith(height: 1.4),
                    ),
                    Text(
                      phrase.meaning,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The caption for screens that don't draw their own: floats just above the
/// navigation capsule, over whatever page is showing. Onboarding's last
/// phrases run on after home has arrived, and this is where they're read.
/// Mounted once, in a Stack above the navigator (MaterialApp.builder).
class AthanCueOverlay extends StatelessWidget {
  const AthanCueOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Positioned stays the Stack's direct child; only what's inside listens.
    return Positioned(
      left: AppSpacing.gutter(context),
      right: AppSpacing.gutter(context),
      bottom: AppSpacing.navClearance(context),
      child: IgnorePointer(
        // Above the navigator there's no Material to give text its style.
        child: Material(
          type: MaterialType.transparency,
          child: ValueListenableBuilder<bool>(
            valueListenable: AthanCueService.instance.captionedLocally,
            builder: (context, local, _) =>
                local ? const SizedBox.shrink() : const Center(child: AthanCueCaption()),
          ),
        ),
      ),
    );
  }
}
