import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wird2/features/home/screens/home_screen.dart';
import 'package:wird2/features/onboarding/screens/onboarding_screen.dart';
import 'package:wird2/models/settings.dart';

import '../helpers/app_harness.dart';

void main() {
  setUpApp();

  testWidgets('a returning user lands on home', (tester) async {
    await returningUser(
        tester, const LocationData(latitude: 23.8103, longitude: 90.4125, city: 'Dhaka', country: 'Bangladesh'));
    await runWird(tester, () async {
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      // Past loading: the pager with all seven tabs is up.
      expect(find.byType(PageView), findsWidgets);
    });
  });
}
