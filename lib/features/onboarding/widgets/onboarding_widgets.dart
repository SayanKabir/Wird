import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/durations.dart';
import '../../../core/constants/radii.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/athan_cue_service.dart';
import '../../../widgets/common/glass_panel.dart';
import '../../../widgets/common/pressable.dart';
import '../../../widgets/common/premium_flowing_loader.dart';

/// Onboarding's progress bar: the sun's path across the sky, with a point for
/// each step, echoing the Schedule icon. The sun glides along it as the user
/// moves through the day.
class DayArcProgress extends StatelessWidget {
  final int step;
  final int steps;

  const DayArcProgress({super.key, required this.step, required this.steps});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: step.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: AppCurves.move,
      builder: (context, t, _) => CustomPaint(
        size: const Size(148, 34),
        painter: _DayArcPainter(t: t, steps: steps),
      ),
    );
  }
}

class _DayArcPainter extends CustomPainter {
  final double t;
  final int steps;

  _DayArcPainter({required this.t, required this.steps});

  // The arc runs from 200° to 340°, a shallow dome above the horizon.
  static const _from = math.pi * 1.1;
  static const _sweep = math.pi * 0.8;

  Offset _at(Rect oval, double fraction) {
    final angle = _from + _sweep * fraction;
    return oval.center + Offset(math.cos(angle) * oval.width / 2, math.sin(angle) * oval.height / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 1.55),
      width: size.width * 1.05,
      height: size.height * 2.6,
    );
    final progress = steps <= 1 ? 1.0 : t / (steps - 1);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawArc(oval, _from, _sweep, false, track);

    final travelled = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.spiritualGold.withValues(alpha: 0.85);
    canvas.drawArc(oval, _from, _sweep * progress, false, travelled);

    for (var i = 0; i < steps; i++) {
      final f = steps <= 1 ? 0.0 : i / (steps - 1);
      final reached = i <= t + 0.01;
      canvas.drawCircle(
        _at(oval, f),
        2.2,
        Paint()..color = reached ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.35),
      );
    }

    final sun = _at(oval, progress);
    canvas.drawCircle(
      sun,
      9,
      Paint()
        ..color = AppColors.spiritualGold.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(sun, 4.6, Paint()..color = AppColors.spiritualGold);
  }

  @override
  bool shouldRepaint(covariant _DayArcPainter old) => old.t != t || old.steps != steps;
}

/// The phrase of the adhan now playing, in Arabic with its meaning, fading in
/// over the page while the clip sounds.
class AthanCueCaption extends StatelessWidget {
  const AthanCueCaption({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AthanCue?>(
      valueListenable: AthanCueService.instance.playing,
      builder: (context, cue, _) => AnimatedSwitcher(
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
        child: cue == null
            ? const SizedBox.shrink()
            : GlassPanel(
                key: ValueKey(cue),
                radius: AppRadii.pill,
                fill: 0.12,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cue.arabic,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.arabic(size: 18, color: AppColors.spiritualGold).copyWith(height: 1.3),
                    ),
                    const SizedBox(width: 12),
                    Text(cue.meaning, style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Speaker button that mutes the adhan cues.
class CueMuteButton extends StatelessWidget {
  const CueMuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AthanCueService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: service.muted,
      builder: (context, muted, _) => Semantics(
        button: true,
        label: muted ? 'Turn adhan sounds on' : 'Mute adhan sounds',
        child: Pressable(
          haptic: PressableHaptic.selection,
          onTap: () {
            service.muted.value = !muted;
            if (!muted) service.stop();
          },
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              size: 20,
              color: Colors.white.withValues(alpha: muted ? 0.45 : 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

/// Page title block: a small spaced label naming the prayer the sky now
/// shows, then the question this step asks.
class OnboardingHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;

  const OnboardingHeading({super.key, required this.eyebrow, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: AppTextStyles.sectionLabel(color: AppColors.spiritualGold.withValues(alpha: 0.9))),
        const SizedBox(height: 10),
        Text(title, style: AppTextStyles.display(size: 34, weight: FontWeight.w300, height: 1.15)),
        const SizedBox(height: 10),
        Text(body, style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.75))),
      ],
    );
  }
}

/// A glass tile that can be chosen, outlined in gold once it is.
class ChoiceTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ChoiceTile({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        pressedScale: 0.97,
        haptic: PressableHaptic.selection,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: AppCurves.emphasized,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.spiritualGold.withValues(alpha: 0.18), blurRadius: 18)]
                : null,
          ),
          child: GlassPanel(
            radius: AppRadii.card,
            fill: selected ? 0.14 : 0.07,
            edge: selected ? 0.0 : 0.12,
            edgeColor: selected ? AppColors.spiritualGold.withValues(alpha: 0.75) : null,
            edgeWidth: selected ? 1.4 : 1,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A labelled switch on a glass row, with an optional leading glyph.
class ToggleTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleTile({
    super.key,
    this.leading,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.98,
      haptic: PressableHaptic.selection,
      onTap: () => onChanged(!value),
      child: GlassPanel(
        radius: AppRadii.card,
        fill: value ? 0.12 : 0.07,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body(weight: FontWeight.w600)),
                  Text(subtitle, style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.65))),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.spiritualGold,
              activeTrackColor: AppColors.spiritualGold.withValues(alpha: 0.3),
              inactiveTrackColor: Colors.white10,
            ),
          ],
        ),
      ),
    );
  }
}

/// The solid pill that moves the user forward. White on the sky, so it stays
/// the brightest thing on every page whatever the hour.
class OnboardingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool gold;

  const OnboardingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final fill = gold ? AppColors.spiritualGold : Colors.white;
    return Pressable(
      pressedScale: 0.96,
      haptic: PressableHaptic.none,
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: AppDurations.normal,
        opacity: enabled || loading ? 1 : 0.4,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [
              BoxShadow(color: fill.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 6)),
            ],
          ),
          alignment: Alignment.center,
          child: loading
              ? const PremiumFlowingLoader(size: 20, color: Color(0xFF0A0E21))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: AppTextStyles.button(color: const Color(0xFF0A0E21))),
                    if (icon != null) ...[
                      const SizedBox(width: 10),
                      Icon(icon, size: 20, color: const Color(0xFF0A0E21)),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// A secondary action drawn as a glass pill.
class GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  const GhostButton({super.key, required this.label, required this.icon, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.97,
      onTap: loading ? null : onPressed,
      child: GlassPanel(
        radius: AppRadii.pill,
        fill: 0.14,
        edge: 0.25,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const PremiumFlowingLoader(size: 18, color: Colors.white)
            else
              Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.button()),
          ],
        ),
      ),
    );
  }
}
