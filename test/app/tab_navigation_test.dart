import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wird2/features/qibla/screens/qibla_screen.dart';
import 'package:wird2/features/quran/screens/quran_screen.dart';
import 'package:wird2/features/settings/screens/settings_screen.dart';
import 'package:wird2/features/statistics/screens/statistics_screen.dart';
import 'package:wird2/features/sunnah/screens/sunnah_screen.dart';
import 'package:wird2/models/settings.dart';

import '../helpers/app_harness.dart';

void main() {
  setUpApp();

  // London, so the high-latitude prayer times are on screen too.
  testWidgets('every tab opens by swiping across the home pager', (tester) async {
    await returningUser(tester, const LocationData(latitude: 51.5074, longitude: -0.1278, city: 'London', country: 'UK'));
    await runWird(tester, () async {
      final pager = find.byType(PageView).first;
      Future<void> swipe(double dx) async {
        await tester.fling(pager, Offset(dx, 0), 1500);
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
      }

      // Home sits in the middle; to its right are Schedule, Sunnah, Qibla
      // and Stats, one page per swipe.
      await swipe(-400);
      for (final screen in [SunnahScreen, QiblaScreen, StatisticsScreen]) {
        await swipe(-400);
        expect(find.byType(screen), findsOneWidget, reason: '$screen');
      }
      // Back left past Home to Quran, then Settings.
      for (var i = 0; i < 5; i++) {
        await swipe(400);
      }
      expect(find.byType(QuranScreen), findsOneWidget);
      await swipe(400);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
