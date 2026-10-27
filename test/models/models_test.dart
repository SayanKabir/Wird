import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/dhikr/dhikr_catalog.dart';
import 'package:wird2/core/repositories/tasbih_repository.dart';
import 'package:wird2/models/prayer.dart';
import 'package:wird2/models/prayer_log.dart';
import 'package:wird2/models/prayer_status.dart';
import 'package:wird2/models/settings.dart';
import 'package:wird2/models/sunnah_progress.dart';
import 'package:wird2/models/tasbih.dart';

void main() {
  group('Tasbih counting', () {
    final morning = DateTime(2026, 10, 27, 8);
    Tasbih fresh({int target = 3}) => Tasbih(id: 't', name: 'T', targetCount: target, lastUpdated: morning);

    test('taps fill a round, the next tap starts a new one', () {
      var t = fresh();
      for (var i = 0; i < 3; i++) {
        t = t.tapped(now: morning);
      }
      expect(t.currentCount, 3);
      expect(t.isRoundFull, isTrue);
      expect(t.round, 1);

      t = t.tapped(now: morning);
      expect(t.currentCount, 1);
      expect(t.completedRounds, 1);
      expect(t.round, 2);
      expect(t.totalCount, 4);
      expect(t.todayCount(now: morning), 4);
    });

    test('undo steps back across a round boundary', () {
      var t = fresh();
      for (var i = 0; i < 4; i++) {
        t = t.tapped(now: morning);
      }
      t = t.undone(now: morning);
      expect((t.currentCount, t.completedRounds, t.totalCount), (3, 0, 3));
      t = t.undone(now: morning);
      expect((t.currentCount, t.completedRounds, t.totalCount), (2, 0, 2));
    });

    test('undo on an untouched counter does nothing', () {
      final t = fresh();
      expect(t.undone(now: morning), t);
    });

    test('undo on old data above the target lands on target - 1', () {
      final t = fresh().copyWith(currentCount: 10, totalCount: 10);
      expect(t.undone(now: morning).currentCount, 2);
    });

    test('reset clears the round but keeps the totals', () {
      var t = fresh();
      for (var i = 0; i < 5; i++) {
        t = t.tapped(now: morning);
      }
      t = t.reset(now: morning);
      expect((t.currentCount, t.completedRounds), (0, 0));
      expect(t.totalCount, 5);
      expect(t.todayCount(now: morning), 5);
    });

    test("today's count starts again at zero the next day", () {
      var t = fresh().tapped(now: morning).tapped(now: morning);
      final tomorrow = morning.add(const Duration(days: 1));
      expect(t.todayCount(now: tomorrow), 0);
      t = t.tapped(now: tomorrow);
      expect(t.todayCount(now: tomorrow), 1);
      expect(t.totalCount, 3);
    });

    test('tallies add to totals without touching the round, never below zero', () {
      var t = fresh().tallied(33, now: morning);
      expect((t.currentCount, t.totalCount, t.todayCount(now: morning)), (0, 33, 33));
      t = t.tallied(-50, now: morning);
      expect((t.totalCount, t.todayCount(now: morning)), (0, 0));
    });

    test('date keys are zero padded', () {
      expect(Tasbih.dateKey(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('DhikrCatalog', () {
    test('every built-in counter has its words', () {
      for (final id in DhikrCatalog.builtInCounterIds) {
        expect(DhikrCatalog.isBuiltIn(id), isTrue);
      }
      expect(DhikrCatalog.isBuiltIn('my_own'), isFalse);
    });

    test('sessions are unique, non-empty and findable', () {
      final ids = DhikrCatalog.sessions.map((s) => s.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final s in DhikrCatalog.sessions) {
        expect(DhikrCatalog.session(s.id), same(s));
        expect(s.steps, isNotEmpty);
        expect(s.totalCount, greaterThan(0));
        for (final step in s.steps) {
          expect(step.count, greaterThan(0), reason: '${s.id}/${step.label}');
          expect(step.arabic.trim(), isNotEmpty, reason: '${s.id}/${step.label}');
          if (step.counterId != null) {
            expect(DhikrCatalog.isBuiltIn(step.counterId!), isTrue, reason: step.counterId);
          }
        }
      }
      expect(DhikrCatalog.session('nope'), isNull);
    });

    test('Tasbih of Fatimah is 33 / 33 / 34', () {
      expect(DhikrCatalog.session('fatimah')!.steps.map((s) => s.count), [33, 33, 34]);
    });

    test('sunnah links open the matching session', () {
      expect(DhikrCatalog.sessionForSunnah(tasbihId: 'morning_azkar', title: 'x'), 'morning');
      expect(DhikrCatalog.sessionForSunnah(tasbihId: 'evening_azkar', title: 'x'), 'evening');
      expect(DhikrCatalog.sessionForSunnah(tasbihId: 'before_sleep_azkar', title: 'x'), 'before_sleep');
      expect(DhikrCatalog.sessionForSunnah(tasbihId: null, title: 'Tasbih of Fatimah'), 'fatimah');
      expect(DhikrCatalog.sessionForSunnah(tasbihId: null, title: 'Smile'), isNull);
    });

    test('visible counters: built-ins in order, then custom, hiding retired and placeholders', () {
      final now = DateTime(2026);
      final all = [
        Tasbih(id: 'zz_custom', name: 'Mine', lastUpdated: now),
        Tasbih(id: 'aa_custom', name: 'Also mine', lastUpdated: now),
        Tasbih(id: 'placeholder', name: 'Dhikr', lastUpdated: now),
        for (final id in DhikrCatalog.retiredCounterIds) Tasbih(id: id, name: id, lastUpdated: now),
        for (final id in DhikrCatalog.builtInCounterIds.reversed) Tasbih(id: id, name: id, lastUpdated: now),
      ];
      final visible = TasbihRepository.visibleCounters(all).map((t) => t.id).toList();
      expect(visible, [...DhikrCatalog.builtInCounterIds, 'aa_custom', 'zz_custom']);
    });
  });

  group('PrayerLog', () {
    final log = PrayerLog(date: DateTime(2026, 10, 27), entries: {
      Prayer.fajr: PrayerEntry.missed(),
      Prayer.dhuhr: const PrayerEntry(status: PrayerStatus.onTime),
      Prayer.asr: const PrayerEntry(status: PrayerStatus.late),
      Prayer.maghrib: const PrayerEntry(status: PrayerStatus.onTime),
      Prayer.isha: PrayerEntry.upcoming(),
    });

    test('groups prayers by status', () {
      expect(log.completedPrayers, unorderedEquals([Prayer.dhuhr, Prayer.asr, Prayer.maghrib]));
      expect(log.onTimePrayers, unorderedEquals([Prayer.dhuhr, Prayer.maghrib]));
      expect(log.missedPrayers, [Prayer.fajr]);
      expect(log.hasPrayer(Prayer.tahajjud), isFalse);
      expect(log.getEntry(Prayer.asr)!.status, PrayerStatus.late);
    });

    test('completion counts on-time fardh only', () {
      expect(log.calculateCompletionPercentage(fardhPrayers), 40);
      expect(log.calculateCompletionPercentage(const []), 0);
    });

    test('a perfect day needs every enabled prayer on time', () {
      expect(log.checkIsPerfectDay(fardhPrayers, const []), isFalse);
      var perfect = log;
      for (final p in fardhPrayers) {
        perfect = perfect.updatePrayer(p, const PrayerEntry(status: PrayerStatus.onTime));
      }
      expect(perfect.checkIsPerfectDay(fardhPrayers, const []), isTrue);
      expect(perfect.checkIsPerfectDay(fardhPrayers, const [Prayer.tahajjud]), isFalse);
      expect(perfect.calculateCompletionPercentage(fardhPrayers), 100);
    });

    test('updatePrayer leaves the original untouched', () {
      final updated = log.updatePrayer(Prayer.fajr, const PrayerEntry(status: PrayerStatus.late));
      expect(log.getEntry(Prayer.fajr)!.status, PrayerStatus.missed);
      expect(updated.getEntry(Prayer.fajr)!.status, PrayerStatus.late);
    });

    test('a new day marks past and current prayers pending, later ones upcoming', () {
      final today = PrayerLog.forToday(enabledPrayers: fardhPrayers, currentPrayer: Prayer.asr);
      expect(today.getEntry(Prayer.fajr)!.status, PrayerStatus.pending);
      expect(today.getEntry(Prayer.asr)!.status, PrayerStatus.pending);
      expect(today.getEntry(Prayer.maghrib)!.status, PrayerStatus.upcoming);
      final night = PrayerLog.forToday(enabledPrayers: fardhPrayers, currentPrayer: null);
      expect(night.entries.values.every((e) => e.status == PrayerStatus.upcoming), isTrue);
    });
  });

  group('PrayerStatus', () {
    test('only on-time counts toward a streak; only missed breaks it', () {
      for (final s in PrayerStatus.values) {
        expect(s.countsTowardStreak, s == PrayerStatus.onTime);
        expect(s.breaksStreak, s == PrayerStatus.missed);
        expect(s.isCompleted, s == PrayerStatus.onTime || s == PrayerStatus.late);
        expect(s.displayName, isNotEmpty);
      }
    });
  });

  group('Prayer', () {
    test('five fardh, all in day order', () {
      expect(fardhPrayers, [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha]);
      for (final p in fardhPrayers) {
        expect(p.isFardh, isTrue);
        expect(allPrayersInOrder, contains(p));
      }
      for (final p in Prayer.values) {
        expect(p.displayName, isNotEmpty);
        expect(p.arabicName, isNotEmpty);
      }
    });
  });

  group('SunnahProgress', () {
    final today = DateTime(2026, 10, 27, 12);
    final key = SunnahProgress.dateKey(today);
    final yesterday = SunnahProgress.dateKey(today.subtract(const Duration(days: 1)));

    test('a streak is live only if last kept today or yesterday', () {
      final p = SunnahProgress.empty().copyWith(currentStreak: 5, lastPracticeDateKey: () => yesterday);
      expect(p.liveStreak(now: today), 5);
      expect(p.copyWith(lastPracticeDateKey: () => key).liveStreak(now: today), 5);
      expect(p.copyWith(lastPracticeDateKey: () => '2026-10-20').liveStreak(now: today), 0);
      expect(SunnahProgress.empty().liveStreak(now: today), 0);
    });

    test('copyWith can clear nullable fields', () {
      final p = SunnahProgress.empty().copyWith(lastPracticeDateKey: () => key, streakBeforeToday: () => 3);
      final cleared = p.copyWith(lastPracticeDateKey: () => null, streakBeforeToday: () => null);
      expect(cleared.lastPracticeDateKey, isNull);
      expect(cleared.streakBeforeToday, isNull);
      // Leaving them out keeps them.
      expect(p.copyWith(currentStreak: 1).lastPracticeDateKey, key);
    });
  });

  group('AppSettings', () {
    test('defaults are safe for a first launch', () {
      const s = AppSettings();
      expect(s.onboardingCompleted, isFalse);
      expect(s.location, isNull);
      expect(s.calculationMethod, CalculationMethodType.muslimWorldLeague);
      expect(s.madhab, MadhabType.shafi);
      expect(s.soundsEnabled, isFalse);
      expect(s.weatherSoundsEnabled, isFalse);
      expect(s.notificationsEnabled, isTrue);
      expect(AppSettings.defaults(), s);
    });

    test('copyWith changes only what it is given', () {
      const s = AppSettings();
      final changed = s.copyWith(madhab: MadhabType.hanafi, soundsEnabled: true);
      expect(changed.madhab, MadhabType.hanafi);
      expect(changed.soundsEnabled, isTrue);
      expect(changed.calculationMethod, s.calculationMethod);
      expect(changed.notificationsEnabled, s.notificationsEnabled);
      expect(changed, isNot(s));
      expect(s.copyWith(), s);
    });
  });
}
