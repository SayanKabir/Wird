import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/notifications/reminder_planner.dart';
import 'package:wird2/core/repositories/practice_ids.dart';
import 'package:wird2/core/repositories/sunnah_repository.dart';
import 'package:wird2/core/services/prayer_service.dart';
import 'package:wird2/core/utils/hijri_date.dart';
import 'package:wird2/models/prayer.dart';
import 'package:wird2/models/settings.dart';
import 'package:wird2/models/sunnah_progress.dart';

const _dhaka = LocationData(latitude: 23.8103, longitude: 90.4125, city: 'Dhaka');

Map<Prayer, PrayerTimeData> _times(DateTime day) => PrayerService().calculatePrayerTimes(
      date: day,
      location: _dhaka,
      calculationMethod: CalculationMethodType.muslimWorldLeague,
      madhab: MadhabType.shafi,
      includeTahajjud: false,
      includeIshraq: false,
      includeDuha: false,
    );

SunnahProgress _practice(List<String> ids, {Map<String, String> doneOn = const {}}) =>
    SunnahProgress.empty().copyWith(practiceIds: ids, lastPracticedDayBySunnah: doneOn);

/// First day on or after [from] that satisfies [test].
DateTime _find(bool Function(DateTime) test, {DateTime? from}) {
  var d = from ?? DateTime(2026, 11, 1);
  for (var i = 0; i < 800; i++, d = d.add(const Duration(days: 1))) {
    if (test(d)) return d;
  }
  throw StateError('not found');
}

List<PlannedReminder> _plan(
  DateTime now, {
  SunnahProgress? progress,
  AppSettings settings = const AppSettings(location: _dhaka),
  Set<String> sessions = const {},
  bool quranRead = false,
  int quranStreak = 0,
}) =>
    ReminderPlanner.plan(ReminderContext(
      now: now,
      times: _times(DateTime(now.year, now.month, now.day)),
      settings: settings,
      progress: progress ?? _practice(PracticeIds.defaults),
      sessionsDoneToday: sessions,
      quranReadToday: quranRead,
      quranStreak: quranStreak,
    ));

void main() {
  // A Tuesday, so neither Friday nor the eve of Monday or Thursday.
  final tuesday = _find((d) {
    final h = HijriDate.fromGregorian(d.add(const Duration(days: 1)));
    return d.weekday == DateTime.tuesday && h.month != 9 && h.month != 12 && h.month != 1 && h.day != 13;
  });
  final early = tuesday.add(const Duration(hours: 1)); // before Fajr
  final times = _times(tuesday);

  group('PracticeIds', () {
    test('every id names a real Sunnah', () {
      final ids = SunnahRepository().getAllSunnahsSync().map((s) => s.id).toSet();
      for (final id in [
        ...PracticeIds.defaults,
        PracticeIds.ayatKursiSleep,
        PracticeIds.mulkSleep,
        PracticeIds.fastMonThu,
        PracticeIds.fastWhiteDays,
      ]) {
        expect(ids, contains(id));
      }
    });
  });

  group('a day with the default practice', () {
    final plan = _plan(early);
    PlannedReminder byId(int id) => plan.firstWhere((r) => r.id == id);

    test('reminds of the azkar and the Quran, each inside its window', () {
      expect(plan.map((r) => r.id), containsAll([ReminderPlanner.morningId, ReminderPlanner.eveningId,
          ReminderPlanner.sleepId, ReminderPlanner.quranId]));

      final morning = byId(ReminderPlanner.morningId).at;
      expect(morning.isAfter(times[Prayer.fajr]!.startTime), isTrue);
      expect(morning.isBefore(times[Prayer.fajr]!.endTime), isTrue, reason: 'before sunrise');

      final evening = byId(ReminderPlanner.eveningId).at;
      expect(evening.isAfter(times[Prayer.asr]!.startTime), isTrue);
      expect(evening.isBefore(times[Prayer.maghrib]!.startTime), isTrue);

      final sleep = byId(ReminderPlanner.sleepId).at;
      expect(sleep.isAfter(times[Prayer.isha]!.startTime), isTrue);
      expect(sleep.isBefore(times[Prayer.isha]!.endTime), isTrue, reason: 'before Islamic midnight');

      expect(byId(ReminderPlanner.quranId).at.isAfter(times[Prayer.maghrib]!.startTime), isTrue);
    });

    test('opens the matching screen', () {
      expect(byId(ReminderPlanner.morningId).target, 'session:morning');
      expect(byId(ReminderPlanner.eveningId).target, 'session:evening');
      expect(byId(ReminderPlanner.sleepId).target, 'session:before_sleep');
      expect(byId(ReminderPlanner.quranId).target, 'quran:last');
    });

    test('is in time order with unique ids, all from the reserved range', () {
      final ats = plan.map((r) => r.at).toList();
      expect(ats, [...ats]..sort());
      expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
      for (final r in plan) {
        expect(ReminderPlanner.allIds, contains(r.id));
      }
    });

    test('no Friday reminder on a Tuesday', () {
      expect(plan.any((r) => r.id == ReminderPlanner.kahfId), isFalse);
    });
  });

  group('skips what is done or past', () {
    test('a Sunnah ticked today, or its session finished, isn\'t reminded', () {
      final key = SunnahProgress.dateKey(early);
      final ticked = _plan(early, progress: _practice(PracticeIds.defaults, doneOn: {PracticeIds.morningAzkar: key}));
      expect(ticked.any((r) => r.id == ReminderPlanner.morningId), isFalse);
      final session = _plan(early, sessions: {'evening'});
      expect(session.any((r) => r.id == ReminderPlanner.eveningId), isFalse);
      expect(session.any((r) => r.id == ReminderPlanner.morningId), isTrue);
    });

    test('nothing is scheduled in the past', () {
      final afterAsr = times[Prayer.maghrib]!.startTime.add(const Duration(minutes: 1));
      final plan = _plan(afterAsr);
      expect(plan.every((r) => r.at.isAfter(afterAsr)), isTrue);
      expect(plan.any((r) => r.id == ReminderPlanner.morningId || r.id == ReminderPlanner.eveningId), isFalse);
      expect(plan.any((r) => r.id == ReminderPlanner.sleepId), isTrue);
    });

    test('Quran read today: no Quran reminder', () {
      expect(_plan(early, quranRead: true).any((r) => r.id == ReminderPlanner.quranId), isFalse);
    });

    test('nothing in the practice: no practice reminders', () {
      final plan = _plan(early, progress: SunnahProgress.empty());
      expect(plan.where((r) => r.kind == ReminderKind.practice), isEmpty);
      expect(plan.any((r) => r.id == ReminderPlanner.quranId), isFalse);
    });
  });

  group('settings', () {
    test('prayer alerts off silences everything', () {
      expect(_plan(early, settings: const AppSettings(location: _dhaka, notificationsEnabled: false)), isEmpty);
    });

    test('each kind can be turned off on its own', () {
      final noPractice = _plan(early, settings: const AppSettings(location: _dhaka, practiceRemindersEnabled: false));
      expect(noPractice.where((r) => r.kind == ReminderKind.practice), isEmpty);
      expect(noPractice.any((r) => r.id == ReminderPlanner.quranId), isTrue);

      final noQuran = _plan(early, settings: const AppSettings(location: _dhaka, quranRemindersEnabled: false));
      expect(noQuran.any((r) => r.id == ReminderPlanner.quranId), isFalse);
      expect(noQuran.any((r) => r.id == ReminderPlanner.morningId), isTrue);
    });
  });

  group('Friday', () {
    test('al-Kahf on Friday morning, opening the surah', () {
      final friday = _find((d) => d.weekday == DateTime.friday).add(const Duration(hours: 1));
      final kahf = _plan(friday).firstWhere((r) => r.id == ReminderPlanner.kahfId);
      expect(kahf.target, 'quran:18');
      final t = _times(DateTime(friday.year, friday.month, friday.day));
      expect(kahf.at.isAfter(t[Prayer.fajr]!.endTime), isTrue);
      expect(kahf.at.isBefore(t[Prayer.dhuhr]!.startTime), isTrue);
    });
  });

  group('streaks', () {
    SunnahProgress streak(int n, String lastKey) =>
        _practice(PracticeIds.defaults).copyWith(currentStreak: n, lastPracticeDateKey: () => lastKey);
    final yesterday = SunnahProgress.dateKey(tuesday.subtract(const Duration(days: 1)));

    test('a Sunnah streak about to lapse gets a nudge', () {
      final nudge = _plan(early, progress: streak(5, yesterday)).firstWhere((r) => r.id == ReminderPlanner.streakId);
      expect(nudge.title, contains('5-day'));
    });

    test('not once something is kept today, nor for a 1-day streak', () {
      expect(_plan(early, progress: streak(5, SunnahProgress.dateKey(tuesday))).any((r) => r.id == ReminderPlanner.streakId), isFalse);
      expect(_plan(early, progress: streak(1, yesterday)).any((r) => r.id == ReminderPlanner.streakId), isFalse);
    });

    test('the Quran reminder names a streak worth keeping', () {
      final q = _plan(early, quranStreak: 6).firstWhere((r) => r.id == ReminderPlanner.quranId);
      expect(q.title, contains('6-day'));
      // A streak alone is reason enough, even without "Read Quran daily".
      expect(_plan(early, progress: SunnahProgress.empty(), quranStreak: 3).any((r) => r.id == ReminderPlanner.quranId), isTrue);
    });
  });

  group('fasting', () {
    PlannedReminder? fasting(DateTime day, SunnahProgress progress) {
      final plan = _plan(day.add(const Duration(hours: 1)), progress: progress);
      for (final r in plan) {
        if (r.id == ReminderPlanner.fastingId) return r;
      }
      return null;
    }

    test('Monday and Thursday only when in the practice', () {
      final sunday = _find((d) {
        final h = HijriDate.fromGregorian(d.add(const Duration(days: 1)));
        return d.weekday == DateTime.sunday && h.month != 9 && h.day != 13 && h.month != 12 && h.month != 1;
      });
      expect(fasting(sunday, _practice([PracticeIds.fastMonThu]))!.title, 'Tomorrow is Monday');
      expect(fasting(sunday, _practice(const [])), isNull);
    });

    test('Arafah and the start of Ramadan for everyone', () {
      final arafahEve = _find((d) {
        final h = HijriDate.fromGregorian(d.add(const Duration(days: 1)));
        return h.month == 12 && h.day == 9;
      });
      expect(fasting(arafahEve, SunnahProgress.empty())!.title, contains('Arafah'));
      final ramadanEve = _find((d) {
        final h = HijriDate.fromGregorian(d.add(const Duration(days: 1)));
        return h.month == 9 && h.day == 1;
      });
      final r = fasting(ramadanEve, SunnahProgress.empty())!;
      expect(r.title, 'Ramadan begins tomorrow');
      expect(r.kind, ReminderKind.fasting);
    });

    test('the white days when in the practice', () {
      final eve = _find((d) {
        final h = HijriDate.fromGregorian(d.add(const Duration(days: 1)));
        return h.day == 13 && h.month != 9 && h.month != 12;
      });
      expect(fasting(eve, _practice([PracticeIds.fastWhiteDays]))!.title, contains('white days'));
    });

    test('Mondays in Ramadan get no extra reminder', () {
      final sundayInRamadan = _find((d) {
        final h = HijriDate.fromGregorian(d.add(const Duration(days: 1)));
        return d.weekday == DateTime.sunday && h.month == 9 && h.day > 1;
      });
      expect(fasting(sundayInRamadan, _practice([PracticeIds.fastMonThu])), isNull);
    });
  });
}
