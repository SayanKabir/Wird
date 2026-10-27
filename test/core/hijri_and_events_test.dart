import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/utils/hijri_date.dart';
import 'package:wird2/core/utils/islamic_day_utils.dart';
import 'package:wird2/core/utils/moon_phase_utils.dart';

void main() {
  group('HijriDate', () {
    test('mid-month dates convert to the right month and year', () {
      // Ramadan 1447 began around 2026-02-18; 1 March is mid-Ramadan.
      final ramadan = HijriDate.fromGregorian(DateTime(2026, 3, 1));
      expect(ramadan.year, 1447);
      expect(ramadan.month, 9);
      expect(ramadan.day, inInclusiveRange(10, 13));

      // 1 Muharram 1448 is around 2026-06-16.
      final newYear = HijriDate.fromGregorian(DateTime(2026, 6, 25));
      expect(newYear.year, 1448);
      expect(newYear.month, 1);

      // 1 Muharram 1445 was around 2023-07-19.
      final older = HijriDate.fromGregorian(DateTime(2023, 8, 1));
      expect((older.year, older.month), (1445, 1));
    });

    test('consecutive days advance by one, wrapping months and years', () {
      var previous = HijriDate.fromGregorian(DateTime(2025, 1, 1));
      for (var i = 1; i <= 800; i++) {
        final next = HijriDate.fromGregorian(DateTime(2025, 1, 1).add(Duration(days: i)));
        expect(next.day, inInclusiveRange(1, 30));
        expect(next.month, inInclusiveRange(1, 12));
        if (next.day != 1) {
          expect((next.year, next.month, next.day), (previous.year, previous.month, previous.day + 1));
        } else {
          expect(previous.day, inInclusiveRange(29, 30));
          final wrapped = previous.month == 12;
          expect(next.month, wrapped ? 1 : previous.month + 1);
          expect(next.year, wrapped ? previous.year + 1 : previous.year);
        }
        previous = next;
      }
    });

    test('the Islamic day turns over at Maghrib', () {
      final maghrib = DateTime(2026, 3, 1, 18, 0);
      final afternoon = HijriDate.fromDateTime(DateTime(2026, 3, 1, 15), maghribTime: maghrib);
      final evening = HijriDate.fromDateTime(DateTime(2026, 3, 1, 19), maghribTime: maghrib);
      final plain = HijriDate.fromGregorian(DateTime(2026, 3, 1));
      expect(evening.day, plain.day);
      expect(afternoon.day, plain.day - 1);
      // Without a Maghrib time it is the plain conversion.
      expect(HijriDate.fromDateTime(DateTime(2026, 3, 1, 15)).day, plain.day);
    });

    test('formats in English and Arabic', () {
      const d = HijriDate(year: 1447, month: 9, day: 27);
      expect(d.formatEnglish(), '27 Ramadan 1447');
      expect(d.formatArabic(), '27 رمضان 1447');
      expect(d.formatShort(), '27 Ramadan');
      expect(d.toString(), d.formatEnglish());
      expect(const HijriDate(year: 1447, month: 3, day: 12).formatShort(), "12 Rabi'");
      for (var m = 1; m <= 12; m++) {
        final h = HijriDate(year: 1447, month: m, day: 1);
        expect(h.monthNameEnglish, isNotEmpty);
        expect(h.monthNameArabic, isNotEmpty);
      }
    });
  });

  group('IslamicDayUtils', () {
    /// First Gregorian date in [from, from+days) whose Hijri date matches.
    DateTime findHijri(int month, int day, {DateTime? from}) {
      final start = from ?? DateTime(2026, 1, 1);
      for (var i = 0; i < 400; i++) {
        final d = start.add(Duration(days: i));
        final h = HijriDate.fromGregorian(d);
        if (h.month == month && h.day == day) return d;
      }
      throw StateError('no $day/$month found');
    }

    test('Eids, Arafah, Ashura and Laylat al-Qadr are recognised', () {
      expect(IslamicDayUtils.messageForDate(findHijri(10, 1))!.type, IslamicEventType.eidAlFitr);
      expect(IslamicDayUtils.messageForDate(findHijri(12, 10))!.type, IslamicEventType.eidAlAdha);
      expect(IslamicDayUtils.messageForDate(findHijri(12, 9))!.type, IslamicEventType.arafah);
      expect(IslamicDayUtils.messageForDate(findHijri(1, 10))!.type, IslamicEventType.ashura);
      expect(IslamicDayUtils.messageForDate(findHijri(9, 27))!.type, IslamicEventType.laylatAlQadr);
    });

    test('Ramadan days are Ramadan and the countdown reaches zero inside it', () {
      final ramadanDay = findHijri(9, 5);
      expect(IslamicDayUtils.isRamadanDate(ramadanDay), isTrue);
      expect(IslamicDayUtils.daysUntilNextRamadan(ramadanDay), 0);
      final shawwal = findHijri(10, 5);
      expect(IslamicDayUtils.isRamadanDate(shawwal), isFalse);
      final until = IslamicDayUtils.daysUntilNextRamadan(shawwal)!;
      expect(until, inInclusiveRange(320, 360));
      final firstOfRamadan = shawwal.add(Duration(days: until));
      expect(HijriDate.fromGregorian(firstOfRamadan).month, 9);
      expect(HijriDate.fromGregorian(firstOfRamadan).day, 1);
    });

    test('Fridays outside special days are Jummah', () {
      // Find an ordinary Friday: not in Ramadan, Dhul Hijjah or the white days.
      var d = DateTime(2026, 10, 2);
      while (true) {
        final h = HijriDate.fromGregorian(d);
        if (d.weekday == DateTime.friday && h.month != 9 && h.month != 12 && (h.day < 13 || h.day > 15) &&
            !(h.month == 1 && (h.day == 9 || h.day == 10))) {
          break;
        }
        d = d.add(const Duration(days: 1));
      }
      expect(IslamicDayUtils.messageForDate(d)?.type, IslamicEventType.jummah);
    });

    test('every message has text and an icon, colour and lead time', () {
      var d = DateTime(2026, 1, 1);
      final seen = <IslamicEventType>{};
      for (var i = 0; i < 400; i++, d = d.add(const Duration(days: 1))) {
        final m = IslamicDayUtils.messageForDate(d);
        if (m == null) continue;
        seen.add(m.type);
        expect(m.title, isNotEmpty);
        expect(m.subtitle, isNotEmpty);
        IslamicDayUtils.iconForType(m.type);
        IslamicDayUtils.accentColor(m.type);
        expect(IslamicDayUtils.countdownLeadDays(m.type), greaterThanOrEqualTo(0));
      }
      expect(seen, containsAll([
        IslamicEventType.eidAlFitr,
        IslamicEventType.eidAlAdha,
        IslamicEventType.ramadan,
        IslamicEventType.jummah,
        IslamicEventType.ayyamAlBeed,
      ]));
    });

    test('the next important event is in the future and skips the one in progress', () {
      final midRamadan = findHijri(9, 10);
      final next = IslamicDayUtils.nextImportantEvent(midRamadan)!;
      expect(next.daysUntil, greaterThan(0));
      expect(next.event.type, isNot(IslamicEventType.ramadan));
      expect(next.date, midRamadan.add(Duration(days: next.daysUntil)));

      // Cached per calendar day: asking again later the same day gives the same answer.
      final again = IslamicDayUtils.nextImportantEvent(midRamadan.add(const Duration(hours: 20)));
      expect(again!.date, next.date);
    });

    test('month events are inside the requested month', () {
      for (var m = 1; m <= 12; m++) {
        for (final e in IslamicDayUtils.eventsForMonth(DateTime(2026, m))) {
          expect(e.date.month, m);
          expect(e.date.year, 2026);
        }
      }
    });
  });

  group('MoonPhaseUtils', () {
    test('known new and full moons', () {
      // New moon 2024-04-08 18:21 UTC, full moon 2024-04-23 23:49 UTC.
      expect(MoonPhaseUtils.getMoonPhase(DateTime.utc(2024, 4, 8, 18, 21)), MoonPhase.newMoon);
      expect(MoonPhaseUtils.getIllumination(DateTime.utc(2024, 4, 8, 18, 21)), lessThan(0.02));
      expect(MoonPhaseUtils.getMoonPhase(DateTime.utc(2024, 4, 23, 23, 49)), MoonPhase.fullMoon);
      expect(MoonPhaseUtils.getIllumination(DateTime.utc(2024, 4, 23, 23, 49)), greaterThan(0.97));
    });

    test('lunar age and phase value stay in range', () {
      for (var i = 0; i < 60; i++) {
        final d = DateTime.utc(1990, 1, 1).add(Duration(days: i * 173));
        final age = MoonPhaseUtils.getLunarAge(d);
        expect(age, inInclusiveRange(0, 29.54));
        expect(MoonPhaseUtils.getPhaseValue(d), inInclusiveRange(0, 1));
        expect(MoonPhaseUtils.getIllumination(d), inInclusiveRange(0, 1));
      }
    });

    test('tilt is widest at the equator and flips between hemispheres', () {
      final d = DateTime.utc(2024, 4, 12); // waxing
      expect(MoonPhaseUtils.getMoonTilt(d, 0).abs(), closeTo(1.5708, 0.001));
      expect(MoonPhaseUtils.getMoonTilt(d, 90), closeTo(0, 0.001));
      expect(MoonPhaseUtils.getMoonTilt(d, 30), -MoonPhaseUtils.getMoonTilt(d, -30));
    });

    test('every phase has a name', () {
      for (final p in MoonPhase.values) {
        expect(p.displayName, isNotEmpty);
        expect(p.illumination, inInclusiveRange(0, 1));
      }
    });
  });
}
