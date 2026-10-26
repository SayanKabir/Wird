import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../models/prayer.dart';
import '../../models/settings.dart';
import 'prayer_service.dart';
import 'storage_service.dart';

/// Keeps the home screen icon in step with the user's choice in Settings:
/// one fixed prayer icon, or "Follow prayer times", where the icon shows the
/// sky of the current prayer.
///
/// The platforms differ, so this just says what should show now and when the
/// next switches fall (see AppIconChannel in AppDelegate.swift and
/// AppIconManager.kt):
/// - iOS can only change the icon while the app is open, and confirms every
///   change with a system alert, so it catches up when the app is opened.
/// - Android walks through the switch times with an alarm, even while the
///   app is closed, and changes the icon once the app is off screen.
class AppIconService with WidgetsBindingObserver {
  AppIconService._();
  static final AppIconService instance = AppIconService._();

  static const _channel = MethodChannel('com.SayanKabir.wird2/app_icon');

  /// How far ahead Android gets switch times. Opening the app tops this up;
  /// after that the icon simply stays on the last prayer.
  static const int _daysAhead = 4;

  bool _initialised = false;
  Object? _lastInputs;

  bool get _supported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  void init() {
    if (_initialised || !_supported) return;
    _initialised = true;
    WidgetsBinding.instance.addObserver(this);
    StorageService().getSettingsListenable().addListener(_onSettingsChanged);
    // After the first frame, so iOS sees the app as active.
    WidgetsBinding.instance.addPostFrameCallback((_) => sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) sync();
  }

  /// Only the settings that change which icon is due are worth a sync.
  void _onSettingsChanged() {
    final s = StorageService().getSettings();
    final inputs = (s.appIcon, s.location, s.calculationMethod, s.madhab);
    if (inputs == _lastInputs) return;
    _lastInputs = inputs;
    sync();
  }

  Future<void> sync() async {
    if (!_supported) return;
    final settings = StorageService().getSettings();
    _lastInputs = (settings.appIcon, settings.location, settings.calculationMethod, settings.madhab);

    final choice = AppIconChoice.fromKey(settings.appIcon);
    var name = choice.key;
    var schedule = <List<Object>>[];
    if (choice == AppIconChoice.auto) {
      if (settings.isValid) {
        final now = DateTime.now();
        name = iconFor(settings, now).key;
        schedule = [
          for (final (time, icon) in _switchTimes(settings, now))
            [time.millisecondsSinceEpoch, icon.key],
        ];
      } else {
        name = AppIconChoice.fallback.key;
      }
    }

    try {
      await _channel.invokeMethod('setIcon', {'name': name, 'schedule': schedule});
    } on PlatformException catch (e) {
      debugPrint('AppIconService: $e');
    } on MissingPluginException {
      // Not wired up on this platform build.
    }
  }

  /// The icon for the prayer period at [now], matching the app's own sky.
  static AppIconChoice iconFor(AppSettings settings, DateTime now) {
    final times = _timesFor(settings, now);
    return _iconForPeriod(PrayerService().getCurrentPrayerPeriod(times, now));
  }

  static AppIconChoice _iconForPeriod(PrayerPeriod period) => switch (period) {
        PrayerPeriod.fajr || PrayerPeriod.sunrise => AppIconChoice.fajr,
        PrayerPeriod.dhuhr => AppIconChoice.dhuhr,
        PrayerPeriod.asr => AppIconChoice.asr,
        PrayerPeriod.maghrib => AppIconChoice.maghrib,
        PrayerPeriod.isha || PrayerPeriod.tahajjud => AppIconChoice.isha,
      };

  /// Each prayer's start time from [now] on, for the next few days.
  static List<(DateTime, AppIconChoice)> _switchTimes(AppSettings settings, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final result = <(DateTime, AppIconChoice)>[];
    for (var day = 0; day < _daysAhead; day++) {
      final times = _timesFor(settings, today.add(Duration(days: day)));
      for (final (prayer, icon) in const [
        (Prayer.fajr, AppIconChoice.fajr),
        (Prayer.dhuhr, AppIconChoice.dhuhr),
        (Prayer.asr, AppIconChoice.asr),
        (Prayer.maghrib, AppIconChoice.maghrib),
        (Prayer.isha, AppIconChoice.isha),
      ]) {
        final start = times[prayer]?.startTime;
        if (start != null && start.isAfter(now)) result.add((start, icon));
      }
    }
    return result;
  }

  static Map<Prayer, PrayerTimeData> _timesFor(AppSettings settings, DateTime date) =>
      PrayerService().calculatePrayerTimes(
        date: date,
        location: settings.location!,
        calculationMethod: settings.calculationMethod,
        madhab: settings.madhab,
        // Only the five fard times decide the icon.
        includeTahajjud: false,
        includeIshraq: false,
        includeDuha: false,
      );
}
