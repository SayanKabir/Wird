import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wird2/core/services/achievement_service.dart';
import 'package:wird2/features/statistics/screens/statistics_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('earned medallions with long titles fit on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final achievements = [
      for (final (title, earned) in [
        ('A Thousand Prostrations', true),
        ('Companion of the Quran', true),
        ('Heart of the Masjid', true),
        ('Night Prayer Champion', false),
        ('Congregation Starter', false),
        ('Weekly Warrior', false),
      ])
        Achievement(
          id: title,
          title: title,
          description: 'A description long enough to wrap onto a second line.',
          icon: Icons.star_rounded,
          isUnlocked: earned,
          unlockedDate: earned ? DateTime(2026, 10, 26) : null,
          progress: earned ? 1 : 0.4,
          progressText: earned ? '' : '4 / 10 days',
        ),
    ];

    await tester.pumpWidget(MaterialApp(home: AchievementsScreen(achievements: achievements)));
    await tester.pump();

    // Font loading is off in tests; ignore that, fail on anything else
    // (an overflow is reported as an exception).
    final error = tester.takeException();
    expect(error == null || '$error'.contains('GoogleFonts') || '$error'.contains('font'), isTrue, reason: '$error');
    expect(find.text('A Thousand Prostrations'), findsOneWidget);
  });
}
