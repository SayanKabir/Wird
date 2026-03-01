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
    testWidgets('renders Sunnah & Insights section', (tester) async {
       // Setup mocks
       when(mockStorage.getSettings()).thenReturn(const AppSettings());
       when(mockPrayerBloc.state).thenReturn(PrayerLoading());
       when(mockPrayerBloc.stream).thenAnswer((_) => Stream.value(PrayerLoading()));
       
       // Stub NotificationService calls if triggered by built-in logic?
       // SettingsScreen uses RepositoryProvider for NotificationService.
       // We can provide our `notificationService` instance which has the mock plugin.

       await tester.pumpWidget(
         MultiRepositoryProvider(
           providers: [
             RepositoryProvider<StorageService>.value(value: mockStorage),
             RepositoryProvider<NotificationService>.value(value: notificationService),
             RepositoryProvider<SunnahRepository>.value(value: mockSunnahRepo),
           ],
           child: MultiBlocProvider(
             providers: [
               BlocProvider<PrayerBloc>.value(value: mockPrayerBloc),
             ],
             child: const MaterialApp(home: SettingsScreen()),
           ),
         ),
       );
       
       await tester.pumpAndSettle();

       // Verify Top Section Title (to confirm render)
       expect(find.text('Show Weather'), findsOneWidget);

       // Scroll to the bottom to ensure visibility (multiple drags if needed)
       await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
       await tester.pumpAndSettle();
       await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
       await tester.pumpAndSettle();
       await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
       await tester.pumpAndSettle();

       // Verify Section Title
       expect(find.text('SUNNAH & INSIGHTS'), findsOneWidget);
       
       // Verify Toggles
       expect(find.text('Weekly Sunnah Reminder'), findsOneWidget);
       expect(find.text('Islamic Events'), findsOneWidget);
       expect(find.byType(Switch), findsWidgets);
    });
  });
}
