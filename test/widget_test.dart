import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wird2/features/home/screens/home_screen.dart';
import 'package:wird2/features/onboarding/screens/onboarding_screen.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpApp();

  testWidgets('a first launch opens onboarding', (tester) async {
    await runWird(tester, () async {
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
