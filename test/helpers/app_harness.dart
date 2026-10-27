import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:wird2/main.dart';
import 'package:wird2/core/repositories/sunnah_repository.dart';
import 'package:wird2/core/repositories/quran_repository.dart';
import 'package:wird2/core/services/storage_service.dart';
import 'package:wird2/models/prayer.dart';
import 'package:wird2/models/prayer_log.dart';
import 'package:wird2/models/settings.dart';

import 'test_hive.dart';

/// Whole-app tests. Each file runs in its own isolate; keep to one test per
/// file that writes to storage. Writes the screens start belong to the
/// fake-time zone and never finish, and an unfinished write blocks that box
/// for every test after it in the same isolate.

/// Plugin channels the app talks to at startup. There is no platform side in
/// tests, so each answers with nothing, as an unsupported device would.
const _pluginChannels = [
  'xyz.luan/audioplayers',
  'xyz.luan/audioplayers.global',
  'xyz.luan/audioplayers.global/events',
  'flutter.baseflow.com/geolocator',
  'flutter.baseflow.com/geolocator_updates',
  'home_widget',
  'dexterous.com/flutter/local_notifications',
  'com.SayanKabir.wird2/app_icon',
  'com.SayanKabir.wird2/device',
  'com.SayanKabir.wird2/links',
  'com.SayanKabir.wird2/location',
];

/// Sets up storage, time zones and plugin stubs for the tests in a file.
void setUpApp() {
  late Directory hiveDir;
  setUpAll(() {
    // main() does this through NotificationService.init().
    tz.initializeTimeZones();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in _pluginChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
  });
  setUp(() async => hiveDir = await openTestStorage());
  // Closing Hive would wait on the unfinished writes forever, so drop the
  // folder and let the isolate end with the boxes open.
  tearDown(() => hiveDir.deleteSync(recursive: true));
}

/// Saves settings for someone who finished onboarding, plus today's prayer
/// log. Without the log, home awaits creating one, a disk write the fake
/// test clock never lets finish, and it would sit on its loading view.
Future<void> returningUser(WidgetTester tester, LocationData location) => tester.runAsync(() async {
      await StorageService().saveSettings(AppSettings(onboardingCompleted: true, location: location));
      await StorageService().savePrayerLog(PrayerLog.forToday(enabledPrayers: fardhPrayers, currentPrayer: null));
    });

/// Pumps the whole app, lets it run for a few seconds of fake time, then
/// tears it down so its tickers and timers stop before the test ends.
Future<void> runWird(WidgetTester tester, Future<void> Function() body) async {
  await tester.pumpWidget(WirdApp(
    sunnahRepository: SunnahRepository(),
    quranRepository: QuranRepository(),
  ));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  await body();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 1));
}
