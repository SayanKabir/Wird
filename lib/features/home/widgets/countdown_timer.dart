import 'dart:async';
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
/// The seconds display drives itself.
///
/// It used to be a StatelessWidget fed a pre-computed [Duration], which meant
/// the only way to advance it was to rebuild whatever built it. PrayerBloc did
/// that by emitting a fresh state every second, and because the BlocBuilder
/// consuming that state sits above CelestialBackground, the Scaffold and the
/// whole PageView, one clock tick rebuilt the entire home tree — and forced
/// every visible BackdropFilter to re-blur — once a second, forever.
///
/// Owning a [Timer] here keeps that per-second rebuild scoped to these few Text
/// widgets. Pass [targetTime]; the remaining duration is derived internally.
class HeroCountdown extends StatefulWidget {
  /// The moment being counted down to.
  final DateTime targetTime;
  final String prayerName;
  final bool isPrayerActive;
  final bool reduceMotion;

  const HeroCountdown({
    super.key,
    required this.targetTime,
    required this.prayerName,
    required this.isPrayerActive,
    this.reduceMotion = false,
  });

  @override
  State<HeroCountdown> createState() => _HeroCountdownState();
}

class _HeroCountdownState extends State<HeroCountdown>
    with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  /// The clock only needs to tick while it is on screen. Left running, it kept
  /// waking once a second behind a locked screen to re-render digits nobody
  /// could see. The displayed value is derived from [HeroCountdown.targetTime]
  /// at build time, so it is correct immediately on resume with no catch-up.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _startTicker();
      setState(() {}); // redraw at once rather than after the next tick
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final left = widget.targetTime.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  Widget build(BuildContext context) {
    final duration = _remaining;
    final isPrayerActive = widget.isPrayerActive;
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