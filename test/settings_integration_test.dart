import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wird2/core/services/storage_service.dart';
import 'package:wird2/core/services/notification_service.dart';
import 'package:wird2/core/repositories/sunnah_repository.dart';
import 'package:wird2/features/settings/screens/settings_screen.dart';
import 'package:wird2/models/settings.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wird2/features/home/bloc/prayer_bloc.dart';

// Generate mocks
@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  StorageService,
  SunnahRepository,
  PrayerBloc
])
import 'settings_integration_test.mocks.dart';
import 'helpers/test_hive.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late MockStorageService mockStorage;
  late MockSunnahRepository mockSunnahRepo;
  late NotificationService notificationService;
  late MockFlutterLocalNotificationsPlugin mockNotificationsPlugin;
  late MockPrayerBloc mockPrayerBloc;

  setUp(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC')); // Set a default location
    
    mockStorage = MockStorageService();
    mockSunnahRepo = MockSunnahRepository();
    mockNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
    // Inject mock plugin into NotificationService using the test constructor
    notificationService = NotificationService.withPlugin(mockNotificationsPlugin);
    mockPrayerBloc = MockPrayerBloc();
  });

  group('AppSettings Model', () {
    test('default values are true', () {
      const settings = AppSettings();
      expect(settings.sunnahNotificationsEnabled, true);
      expect(settings.islamicEventsEnabled, true);
    });

    test('copyWith updates fields', () {
      const settings = AppSettings();
      final newSettings = settings.copyWith(sunnahNotificationsEnabled: false);
      expect(newSettings.sunnahNotificationsEnabled, false);
      expect(newSettings.islamicEventsEnabled, true);
    });
  });

  group('NotificationService Logic', () {
    test('scheduleWeeklySunnahReminder schedules with ID 200', () async {
      when(mockNotificationsPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        uiLocalNotificationDateInterpretation: anyNamed('uiLocalNotificationDateInterpretation'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).thenAnswer((_) async {});

      await notificationService.scheduleWeeklySunnahReminder('Smile');

      verify(mockNotificationsPlugin.zonedSchedule(
        200,
        argThat(contains('Sunnah')),
        argThat(contains('Smile')),
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        uiLocalNotificationDateInterpretation: anyNamed('uiLocalNotificationDateInterpretation'),
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: anyNamed('payload'),
      )).called(1);
    });

    test('cancelSunnahNotifications cancels ID 200', () async {
      when(mockNotificationsPlugin.cancel(any)).thenAnswer((_) async {});

      await notificationService.cancelSunnahNotifications();

      verify(mockNotificationsPlugin.cancel(200)).called(1);
    });
  });

  group('SettingsScreen Widget Test', () {
    late Directory hiveDir;
    setUp(() async => hiveDir = await openTestStorage());
    tearDown(() => closeTestStorage(hiveDir));

    testWidgets('opens the Notifications group onto the sunnah and occasion toggles', (tester) async {
      when(mockPrayerBloc.state).thenReturn(PrayerLoading());
      when(mockPrayerBloc.stream).thenAnswer((_) => Stream.value(PrayerLoading()));

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<StorageService>.value(value: mockStorage),
            RepositoryProvider<NotificationService>.value(value: notificationService),
            RepositoryProvider<SunnahRepository>.value(value: mockSunnahRepo),
          ],
          child: MultiBlocProvider(
            providers: [BlocProvider<PrayerBloc>.value(value: mockPrayerBloc)],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Groups start folded: headers show, rows don't.
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Prayer times'), findsOneWidget);
      expect(find.text('Weekly sunnah'), findsNothing);

      await tester.scrollUntilVisible(find.text('Notifications'), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Notifications'));
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(find.text('Islamic occasions'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Weekly sunnah'), findsOneWidget);
      expect(find.text('Islamic occasions'), findsOneWidget);

      // Folding it again hides the rows.
      await tester.scrollUntilVisible(find.text('Notifications'), -300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Notifications'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Islamic occasions'), findsNothing);
    });
  });
}
