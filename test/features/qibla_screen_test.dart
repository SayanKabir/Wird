import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/services/prayer_service.dart';
import 'package:wird2/core/services/storage_service.dart';
import 'package:wird2/features/qibla/screens/qibla_screen.dart';
import 'package:wird2/models/settings.dart';

import '../helpers/test_hive.dart';

const _dhaka = LocationData(latitude: 23.8103, longitude: 90.4125, city: 'Dhaka', country: 'Bangladesh');

CompassEvent _reading(double heading, {double accuracy = 15}) => CompassEvent.fromList([heading, heading, accuracy]);

void main() {
  late Directory hiveDir;
  late StreamController<CompassEvent> compass;

  setUp(() async {
    hiveDir = await openTestStorage();
    compass = StreamController<CompassEvent>();
  });
  tearDown(() async {
    await compass.close();
    await closeTestStorage(hiveDir);
  });

  Future<void> pumpQibla(WidgetTester tester, {LocationData? location = _dhaka}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    if (location != null) {
      await tester.runAsync(() => StorageService().saveSettings(AppSettings(location: location)));
    }
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(backgroundColor: const Color(0xFF0E1424), body: QiblaScreen(compassEvents: compass.stream)),
    ));
    await tester.pump();
  }

  Future<void> feed(WidgetTester tester, CompassEvent event) async {
    compass.add(event);
    await tester.pump();
    // Long enough for the readout's cross-fade to finish.
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  final qibla = PrayerService().getQiblaDirection(_dhaka); // about 277°

  testWidgets('shows where you are and how far Makkah is', (tester) async {
    await pumpQibla(tester);
    expect(find.text('Qibla'), findsOneWidget);
    expect(find.textContaining('Dhaka · 5,1'), findsOneWidget);
    expect(find.textContaining('km to Makkah'), findsOneWidget);
    expect(find.text('Finding direction…'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('tells you which way to turn and by how much', (tester) async {
    await pumpQibla(tester);

    await feed(tester, _reading(qibla - 40));
    expect(find.text('40°'), findsOneWidget);
    expect(find.text('Turn right'), findsOneWidget);

    await feed(tester, _reading(qibla + 25));
    expect(find.text('25°'), findsOneWidget);
    expect(find.text('Turn left'), findsOneWidget);
    expect(find.textContaining('Heading'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('locks on within 3° and holds until 6°', (tester) async {
    await pumpQibla(tester);
    await feed(tester, _reading(qibla - 20));
    expect(find.text('Facing the Qibla'), findsNothing);

    await feed(tester, _reading(qibla - 2));
    expect(find.text('Facing the Qibla'), findsOneWidget);

    // A small wobble doesn't drop it.
    await feed(tester, _reading(qibla + 5));
    expect(find.text('Facing the Qibla'), findsOneWidget);

    await feed(tester, _reading(qibla + 9));
    expect(find.text('Facing the Qibla'), findsNothing);
    expect(find.text('Turn left'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('asks for calibration on a low reading but keeps pointing', (tester) async {
    await pumpQibla(tester);
    await feed(tester, _reading(qibla - 30, accuracy: 30));
    expect(find.text('Calibrate your compass'), findsNothing, reason: 'medium accuracy is fine');

    await feed(tester, _reading(qibla - 30, accuracy: 45));
    expect(find.text('Calibrate your compass'), findsOneWidget);
    // The readout still follows the compass.
    await feed(tester, _reading(qibla - 10, accuracy: 45));
    expect(find.text('10°'), findsOneWidget);

    await feed(tester, _reading(qibla - 10));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Calibrate your compass'), findsNothing);
    await unmount(tester);
  });

  testWidgets('asks for a location instead of pointing north', (tester) async {
    await pumpQibla(tester, location: null);
    expect(find.text('Set your location'), findsOneWidget);
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Finding direction…'), findsNothing);
    await unmount(tester);
  });

  testWidgets('without a compass it still gives the bearing', (tester) async {
    await pumpQibla(tester);
    compass.addError(Exception('no sensor'));
    await tester.pump();
    expect(find.text('This phone has no compass'), findsOneWidget);
    expect(find.textContaining(RegExp(r'27[78]° W from north')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('fits on a small phone at every angle', (tester) async {
    await pumpQibla(tester);
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    await tester.pump();
    for (var h = 0; h < 360; h += 45) {
      await feed(tester, _reading(h.toDouble(), accuracy: h == 180 ? 45 : 15));
      expect(tester.takeException(), isNull, reason: 'heading $h');
    }
    await unmount(tester);
  });
}
