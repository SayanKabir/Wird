import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:wird2/core/notifications/reminder_planner.dart';
import 'package:wird2/core/repositories/practice_ids.dart';
import 'package:wird2/core/repositories/sunnah_progress_repository.dart';
import 'package:wird2/core/services/notification_service.dart';
import 'package:wird2/core/services/storage_service.dart';

import '../helpers/test_hive.dart';
import '../settings_integration_test.mocks.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await openTestStorage());
  tearDown(() => closeTestStorage(dir));

  group('starting practice', () {
    test('is added once, after what the user already keeps', () async {
      final repo = SunnahProgressRepository();
      await repo.togglePractice('my_own_sunnah');

      final added = await repo.seedDefaultPractice();
      expect(added, PracticeIds.defaults);
      var p = await repo.getProgress();
      expect(p.practiceIds.first, 'my_own_sunnah');
      expect(p.practiceIds, containsAll(PracticeIds.defaults));

      // Removing one sticks: seeding never runs again.
      await repo.togglePractice(PracticeIds.bismillah);
      expect(await repo.seedDefaultPractice(), isEmpty);
      p = await repo.getProgress();
      expect(p.practiceIds, isNot(contains(PracticeIds.bismillah)));
    });

    test('doesn\'t duplicate a default the user already chose', () async {
      final repo = SunnahProgressRepository();
      await repo.togglePractice(PracticeIds.morningAzkar);
      final added = await repo.seedDefaultPractice();
      expect(added, isNot(contains(PracticeIds.morningAzkar)));
      final p = await repo.getProgress();
      expect(p.practiceIds.where((id) => id == PracticeIds.morningAzkar), hasLength(1));
    });
  });

  group('settings', () {
    test('reminder switches default on and survive a save', () async {
      final storage = StorageService();
      final fresh = storage.getSettings();
      expect(fresh.practiceRemindersEnabled, isTrue);
      expect(fresh.quranRemindersEnabled, isTrue);
      expect(fresh.fastingRemindersEnabled, isTrue);

      await storage.saveSettings(fresh.copyWith(quranRemindersEnabled: false, fastingRemindersEnabled: false));

      // Read back from disk, not memory.
      await Hive.close();
      await storage.init(path: dir.path);
      final reread = storage.getSettings();
      expect(reread.practiceRemindersEnabled, isTrue);
      expect(reread.quranRemindersEnabled, isFalse);
      expect(reread.fastingRemindersEnabled, isFalse);
    });
  });

  group('NotificationService', () {
    late MockFlutterLocalNotificationsPlugin plugin;
    late NotificationService service;

    setUp(() {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
      plugin = MockFlutterLocalNotificationsPlugin();
      service = NotificationService.withPlugin(plugin);
      when(plugin.cancel(any)).thenAnswer((_) async {});
      when(plugin.zonedSchedule(any, any, any, any, any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              uiLocalNotificationDateInterpretation: anyNamed('uiLocalNotificationDateInterpretation'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload')))
          .thenAnswer((_) async {});
    });

    test('clears the reminder range, then schedules each with its target', () async {
      final at = DateTime.now().add(const Duration(hours: 2));
      await service.schedulePlannedReminders([
        PlannedReminder(id: ReminderPlanner.morningId, at: at, title: 'Morning azkar', body: 'b', target: 'session:morning', kind: ReminderKind.practice),
        PlannedReminder(id: ReminderPlanner.kahfId, at: at, title: "It's Friday", body: 'b', target: 'quran:18', kind: ReminderKind.practice),
      ]);
      for (final id in ReminderPlanner.allIds) {
        verify(plugin.cancel(id)).called(1);
      }
      verify(plugin.zonedSchedule(ReminderPlanner.morningId, 'Morning azkar', 'b', any, any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              uiLocalNotificationDateInterpretation: anyNamed('uiLocalNotificationDateInterpretation'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: 'open:session:morning'))
          .called(1);
      verify(plugin.zonedSchedule(ReminderPlanner.kahfId, any, any, any, any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              uiLocalNotificationDateInterpretation: anyNamed('uiLocalNotificationDateInterpretation'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: 'open:quran:18'))
          .called(1);
    });

    test('reads reminder targets out of payloads, and only those', () {
      expect(NotificationService.reminderTarget('open:session:evening'), 'session:evening');
      expect(NotificationService.reminderTarget('prayer_start:fajr:123'), isNull);
      expect(NotificationService.reminderTarget(null), isNull);
    });
  });
}
