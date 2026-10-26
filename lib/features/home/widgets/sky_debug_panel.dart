import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/debug_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../widgets/common/glass_panel.dart';
import '../../../widgets/common/pressable.dart';

/// Debug builds only: a clock for the sky. Scrub through a day, step to
/// other days (the new moon for the hilal), play a whole day in about a
/// minute, and force the weather and wind, to see every sky on the phone
/// without waiting for it. The prayer period follows the clock too, so
/// crossing an adhan time plays its swell.
///
/// Shown by the home screen behind `kDebugMode`; never in a release build.
class SkyDebugPanel extends StatefulWidget {
  const SkyDebugPanel({super.key});

  @override
  State<SkyDebugPanel> createState() => _SkyDebugPanelState();
}

class _SkyDebugPanelState extends State<SkyDebugPanel> {
  final DebugService _debug = DebugService();
  bool _open = false;
  Timer? _player;

  /// A day in a minute: 24 minutes of sky every second.
  static const _tick = Duration(milliseconds: 100);
  static const _minutesPerTick = 2.4;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _time => _debug.now();

  int get _dayOffset {
    final t = _time;
    return DateTime(t.year, t.month, t.day).difference(_today).inDays;
  }

  double get _minutes => _time.hour * 60 + _time.minute + _time.second / 60;

  void _set({double? minutes, int? dayOffset}) {
    final m = (minutes ?? _minutes) % 1440;
    final d = dayOffset ?? _dayOffset;
    setState(() {
      _debug.skyTime.value = DateTime(_today.year, _today.month, _today.day + d)
          .add(Duration(milliseconds: (m * 60000).round()));
    });
  }

  void _togglePlay() {
    if (_player != null) {
      setState(() {
        _player?.cancel();
        _player = null;
      });
      return;
    }
    _player = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      final next = _minutes + _minutesPerTick;
      // Roll over into the next day rather than looping one day.
      _set(minutes: next, dayOffset: next >= 1440 ? _dayOffset + 1 : _dayOffset);
    });
    setState(() {});
  }

  void _reset() {
    _player?.cancel();
    _player = null;
    setState(_debug.reset);
  }

  @override
  void dispose() {
    _player?.cancel();
    super.dispose();
  }

  String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _dayLabel => switch (_dayOffset) {
        0 => 'Today',
        1 => 'Tomorrow',
        -1 => 'Yesterday',
        final d => d > 0 ? '+$d days' : '$d days',
      };

  @override
  Widget build(BuildContext context) {
    final scrubbed = _debug.skyTime.value != null;

    if (!_open) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Pressable(
          onTap: () => setState(() => _open = true),
          child: GlassPanel(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: scrubbed ? AppColors.spiritualGold : Colors.white70),
                const SizedBox(width: 6),
                Text(scrubbed ? _clock(_time) : 'Sky', style: AppTextStyles.small(color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }

    return GlassPanel(
      radius: 20,
      fill: 0.16,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Sky clock', style: AppTextStyles.small(color: Colors.white70)),
              const Spacer(),
              Text('$_dayLabel  ${_clock(_time)}',
                  style: AppTextStyles.body(weight: FontWeight.w600)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                onPressed: () => setState(() => _open = false),
              ),
            ],
          ),
          Slider(
            value: _minutes.clamp(0, 1439.99),
            max: 1439.99,
            activeColor: AppColors.spiritualGold,
            inactiveColor: Colors.white12,
            onChanged: (v) => _set(minutes: v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Chip('− day', onTap: () => _set(dayOffset: _dayOffset - 1)),
              _Chip(_player != null ? 'Pause' : 'Play day', selected: _player != null, onTap: _togglePlay),
              _Chip('+ day', onTap: () => _set(dayOffset: _dayOffset + 1)),
              _Chip('Reset', onTap: _reset),
            ],
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<WeatherCondition?>(
            valueListenable: _debug.overriddenWeather,
            builder: (context, weather, _) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip('Live', selected: weather == null, onTap: () => _debug.setWeather(null)),
                for (final w in const [
                  WeatherCondition.clear,
                  WeatherCondition.cloudy,
                  WeatherCondition.rain,
                  WeatherCondition.thunderstorm,
                  WeatherCondition.fog,
                  WeatherCondition.snow,
                ])
                  _Chip(w == WeatherCondition.thunderstorm ? 'storm' : w.name,
                      selected: weather == w, onTap: () => _debug.setWeather(w)),
              ],
            ),
          ),
          ValueListenableBuilder<double?>(
            valueListenable: _debug.overriddenWind,
            builder: (context, wind, _) => Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text('Wind ${(wind ?? 5).round()} km/h', style: AppTextStyles.small(color: Colors.white70)),
                ),
                Expanded(
                  child: Slider(
                    value: wind ?? 5,
                    max: 60,
                    activeColor: AppColors.spiritualGold,
                    inactiveColor: Colors.white12,
                    onChanged: (v) => _debug.overriddenWind.value = v,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(this.label, {this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: PressableHaptic.selection,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? AppColors.spiritualGold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: selected ? AppColors.spiritualGold.withValues(alpha: 0.6) : Colors.white12),
        ),
        child: Text(label, style: AppTextStyles.small(color: selected ? AppColors.spiritualGold : Colors.white)),
      ),
    );
  }
}
