import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';

/// Small Countdown timer widget for lists/cards
class CountdownTimer extends StatelessWidget {
  final Duration duration;
  final bool isActive;
  final String? label;
  final bool reduceMotion;
  final TextStyle? styleOverride;

  const CountdownTimer({
    super.key,
    required this.duration,
    this.isActive = false,
    this.label,
    this.reduceMotion = false,
    this.styleOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = duration.inMinutes < 5 && duration.inSeconds > 0;
    final isVeryUrgent = duration.inMinutes < 1 && duration.inSeconds > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Text(
            label!,
            style: AppTextStyles.tiny(
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        AnimatedDefaultTextStyle(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          style: styleOverride ?? _getTextStyle(isUrgent, isVeryUrgent),
          child: Text(
            AppFormatters.formatCountdown(duration),
          ),
        ),
      ],
    );
  }

  TextStyle _getTextStyle(bool isUrgent, bool isVeryUrgent) {
    // Monospaced font for numbers to prevent jitter
    final baseStyle = const TextStyle(
      fontFamily: 'JetBrains Mono',
      fontWeight: FontWeight.w500,
    );

    if (isVeryUrgent) {
      return baseStyle.copyWith(color: AppColors.statusMissed);
    } else if (isUrgent) {
      return baseStyle.copyWith(color: AppColors.statusLate);
    } else if (isActive) {
      return baseStyle.copyWith(color: AppColors.activeGlow);
    } else {
      return baseStyle.copyWith(color: Colors.white.withOpacity(0.9));
    }
  }
}

/// Large, typography-based countdown for Home Screen
/// No containers, just clean, large text.
class HeroCountdown extends StatelessWidget {
  final Duration duration;
  final String prayerName;
  final bool isPrayerActive;
  final bool reduceMotion;

  const HeroCountdown({
    super.key,
    required this.duration,
    required this.prayerName,
    required this.isPrayerActive,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    // Urgency Logic
    final isUrgent = duration.inMinutes < 5; // < 5 mins
    final isCritical = duration.inMinutes < 1; // < 1 min

    Color timeColor = Colors.white;
    if (isCritical) {
      timeColor = AppColors.statusMissed; // Red
    } else if (isUrgent) {
      timeColor = AppColors.statusUpcoming; // Yellow/Orange
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pure Typography Row
        // Wrapped in FittedBox to prevent overflow on small screens when showing H:M:S
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (hours > 0) ...[
                _TimeUnit(value: hours, label: 'h', color: timeColor),
                _TimeSeparator(color: timeColor),
              ],

              _TimeUnit(value: minutes, label: 'm', color: timeColor),

              // Always show seconds now
              _TimeSeparator(color: timeColor),
              _TimeUnit(value: seconds, label: 's', color: timeColor),
            ],
          ),
        ),

        // Contextual sub-text (optional, keeps UI clean)
        if (isPrayerActive && !isCritical)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'remaining',
              style: AppTextStyles.tiny(
                color: timeColor.withOpacity(0.6),
              ).copyWith(letterSpacing: 2),
            ),
          ),
      ],
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  final Color color;
  const _TimeSeparator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ":",
        style: AppTextStyles.h2(color: color.withOpacity(0.5)).copyWith(
          fontFamily: 'JetBrains Mono',
          fontSize: 32,
        ),
      ),
    );
  }
}

/// Individual time unit (Number + Label)
/// Uses Baseline alignment for perfect typography
class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _TimeUnit({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Number
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontFamily: 'JetBrains Mono', // Monospaced for stability
            fontSize: 56, // Huge hero size
            fontWeight: FontWeight.w300, // Light weight
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 4),
        // Label (h, m, s)
        Text(
          label,
          style: AppTextStyles.body(
            color: color.withOpacity(0.5),
          ).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}