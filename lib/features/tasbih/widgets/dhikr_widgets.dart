import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../models/settings.dart';
import '../../../widgets/common/pressable.dart';
import '../../home/bloc/prayer_bloc.dart';
import '../../home/widgets/celestial_background.dart';
import 'dhikr_motion.dart';

/// The sky behind the dhikr screens, matching the time of day like the rest
/// of the app. The sun or moon is hidden so nothing competes with the text.
class DhikrBackdrop extends StatelessWidget {
  final Widget child;

  const DhikrBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerBloc, PrayerState>(
      buildWhen: (a, b) => _period(a) != _period(b),
      builder: (context, prayerState) {
        final settings = StorageService().getSettings();
        return CelestialBackground(
          prayerPeriod: _period(prayerState),
          weatherCondition: _condition(settings.weatherTheme),
          cloudCoverage: _clouds(settings.weatherTheme),
          latitude: settings.location?.latitude ?? 0.0,
          showCelestialBody: false,
          child: child,
        );
      },
    );
  }

  static PrayerPeriod _period(PrayerState state) =>
      state is PrayerLoaded ? state.prayerPeriod : PrayerPeriod.isha;

  static WeatherCondition _condition(WeatherTheme theme) {
    switch (theme) {
      case WeatherTheme.cloudy:
        return WeatherCondition.cloudy;
      case WeatherTheme.rain:
        return WeatherCondition.rain;
      case WeatherTheme.thunderstorm:
        return WeatherCondition.thunderstorm;
      case WeatherTheme.snow:
        return WeatherCondition.snow;
      case WeatherTheme.fog:
        return WeatherCondition.fog;
      case WeatherTheme.clear:
      case WeatherTheme.auto:
        return WeatherCondition.clear;
    }
  }

  static int _clouds(WeatherTheme theme) {
    switch (theme) {
      case WeatherTheme.cloudy:
        return 90;
      case WeatherTheme.rain:
      case WeatherTheme.thunderstorm:
      case WeatherTheme.snow:
        return 100;
      case WeatherTheme.fog:
        return 40;
      case WeatherTheme.clear:
      case WeatherTheme.auto:
        return 0;
    }
  }
}

/// Round translucent icon button used in the dhikr headers.
class DhikrIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const DhikrIconButton({super.key, required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.88,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Header row: a button on each side and a centred title.
class DhikrHeader extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const DhikrHeader({super.key, required this.leading, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          leading,
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w600),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.55))),
              ],
            ),
          ),
          // Keep the title centred when there's nothing on the right.
          trailing ?? const SizedBox(width: 42),
        ],
      ),
    );
  }
}

/// Arabic, transliteration, translation and virtue. Scrolls on its own when
/// the text is long, so it never pushes the counting area off screen, and
/// text heading out of view folds away softly instead of being cut off.
class DhikrTextCard extends StatelessWidget {
  final String arabic;
  final String? transliteration;
  final String? translation;
  final String? virtue;
  final String? reference;
  final bool quranic;

  const DhikrTextCard({
    super.key,
    required this.arabic,
    this.transliteration,
    this.translation,
    this.virtue,
    this.reference,
    this.quranic = false,
  });

  @override
  Widget build(BuildContext context) {
    final long = arabic.length > 120;
    final arabicStyle = AppTextStyles.arabic(
      color: Colors.white,
      size: long ? 24 : 34,
      script: quranic ? QuranScript.uthmani : null,
    ).copyWith(height: long ? 1.9 : 1.6);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: FoldingScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            children: [
              FoldText(arabic, style: arabicStyle, direction: TextDirection.rtl),
              if (transliteration != null || translation != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Fold(
                    child: Container(
                      width: 28,
                      height: 1,
                      color: AppColors.spiritualGold.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              if (transliteration != null)
                FoldText(
                  transliteration!,
                  style: AppTextStyles.small(color: AppColors.spiritualGold.withValues(alpha: 0.9))
                      .copyWith(fontStyle: FontStyle.italic, height: 1.5),
                ),
              if (translation != null) ...[
                const SizedBox(height: 10),
                FoldText(
                  translation!,
                  style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.72)).copyWith(height: 1.5),
                ),
              ],
              if (virtue != null) ...[
                const SizedBox(height: 16),
                FoldText(
                  virtue!,
                  style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.55)).copyWith(height: 1.5),
                ),
              ],
              if (reference != null) ...[
                const SizedBox(height: 8),
                Fold(child: Text(reference!, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.4)))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress ring that eases between values. A small bead rides the leading
/// edge, and a full round glows softly and gives a gentle pulse.
class DhikrRing extends StatelessWidget {
  final double progress;
  final double size;
  final Widget child;

  /// Changes whenever a round fills, to replay the pulse.
  final Object? pulseKey;

  const DhikrRing({super.key, required this.progress, required this.child, this.size = 240, this.pulseKey});

  @override
  Widget build(BuildContext context) {
    final full = progress >= 1;
    return TweenAnimationBuilder<double>(
      key: ValueKey(full ? pulseKey : null),
      tween: Tween(begin: full ? 1.06 : 1, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => CustomPaint(
            painter: _RingPainter(value, stroke: size < 160 ? 7 : 10),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;

  _RingPainter(this.progress, {required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final arcRect = (Offset.zero & size).deflate(stroke / 2 + 6);
    final center = arcRect.center;
    final radius = arcRect.width / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress <= 0) return;

    final sweep = math.pi * 2 * progress;
    final full = progress >= 1;
    if (full) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.spiritualGold.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          endAngle: math.pi * 2,
          colors: [AppColors.spiritualGold.withValues(alpha: 0.55), AppColors.spiritualGold],
          stops: [0, progress.clamp(0.01, 1.0)],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
    if (!full) {
      final angle = -math.pi / 2 + sweep;
      final head = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(head, stroke * 0.95, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.stroke != stroke;
}

/// Quiet text action ("Undo", "Skip step") that dims when it can't act.
class DhikrTextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const DhikrTextAction({super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: onTap == null ? 0.25 : 0.7);
    return Pressable(
      onTap: onTap,
      haptic: PressableHaptic.selection,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.small(color: color, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// "1.3k" style for large all-time counts.
String compactCount(int n) {
  if (n < 1000) return '$n';
  if (n < 10000) {
    final s = (n / 1000).toStringAsFixed(1);
    return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}k';
  }
  if (n < 1000000) return '${n ~/ 1000}k';
  return '${(n / 1000000).toStringAsFixed(1)}M';
}
