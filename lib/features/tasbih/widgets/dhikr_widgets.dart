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
/// the text is long, so it never pushes the counting area off screen.
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
      size: long ? 23 : 32,
      script: quranic ? QuranScript.uthmani : null,
    ).copyWith(height: long ? 2.0 : 1.7);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            children: [
              Text(arabic, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: arabicStyle),
              if (transliteration != null) ...[
                const SizedBox(height: 12),
                Text(
                  transliteration!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small(color: AppColors.spiritualGold.withValues(alpha: 0.85))
                      .copyWith(fontStyle: FontStyle.italic, height: 1.5),
                ),
              ],
              if (translation != null) ...[
                const SizedBox(height: 8),
                Text(
                  translation!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.7)).copyWith(height: 1.5),
                ),
              ],
              if (virtue != null) ...[
                const SizedBox(height: 14),
                Text(
                  virtue!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.55)).copyWith(height: 1.5),
                ),
              ],
              if (reference != null) ...[
                const SizedBox(height: 8),
                Text(reference!, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.4))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress ring that eases between values and turns fully gold when full.
class DhikrRing extends StatelessWidget {
  final double progress;
  final double size;
  final Widget child;

  const DhikrRing({super.key, required this.progress, required this.child, this.size = 240});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(value),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = AppColors.spiritualGold.withValues(alpha: progress >= 1 ? 1 : 0.85)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
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
