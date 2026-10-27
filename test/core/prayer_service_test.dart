import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/services/prayer_service.dart';
import 'package:wird2/models/prayer.dart';
import 'package:wird2/models/settings.dart';

void main() {
  final service = PrayerService();

  Map<Prayer, PrayerTimeData> timesFor(
    LocationData location,
    DateTime date, {
    CalculationMethodType method = CalculationMethodType.muslimWorldLeague,
    MadhabType madhab = MadhabType.shafi,
    bool sunnah = true,
  }) =>
      service.calculatePrayerTimes(
        date: date,
        location: location,
        calculationMethod: method,
        madhab: madhab,
        includeTahajjud: sunnah,
        includeIshraq: sunnah,
        includeDuha: sunnah,
      );

  const dhaka = LocationData(latitude: 23.8103, longitude: 90.4125, city: 'Dhaka');
  const makkah = LocationData(latitude: 21.4225, longitude: 39.8262, city: 'Makkah');
  const london = LocationData(latitude: 51.5074, longitude: -0.1278, city: 'London');
  const sydney = LocationData(latitude: -33.8688, longitude: 151.2093, city: 'Sydney');
  const reykjavik = LocationData(latitude: 64.1466, longitude: -21.9426, city: 'Reykjavik');

  group('calculatePrayerTimes', () {
    for (final location in [dhaka, makkah, london, sydney, reykjavik]) {
      for (final date in [DateTime(2026, 1, 15), DateTime(2026, 6, 21), DateTime(2026, 10, 27)]) {
        test('${location.city} ${date.month}/${date.day}: windows are ordered and non-empty', () {
          final t = timesFor(location, date);
          expect(t.keys, containsAll(<Prayer>[...fardhPrayers, Prayer.tahajjud, Prayer.ishraq, Prayer.duha]));

          for (final data in t.values) {
            expect(data.endTime.isAfter(data.startTime), isTrue,
                reason: '${data.prayer} ends ${data.endTime} before it starts ${data.startTime}');
            expect(data.duration, greaterThan(Duration.zero));
          }

          // Fardh follow one another through the day.
          expect(t[Prayer.fajr]!.endTime.isBefore(t[Prayer.dhuhr]!.startTime), isTrue);
          expect(t[Prayer.dhuhr]!.endTime, t[Prayer.asr]!.startTime);
          expect(t[Prayer.asr]!.endTime.isBefore(t[Prayer.maghrib]!.startTime), isTrue);
          expect(t[Prayer.maghrib]!.endTime, t[Prayer.isha]!.startTime);

          // Asr stops 20 minutes before Maghrib (the makruh time).
          expect(t[Prayer.maghrib]!.startTime.difference(t[Prayer.asr]!.endTime), const Duration(minutes: 20));

          // Ishraq and Duha sit between sunrise and Dhuhr without overlapping.
          final sunrise = t[Prayer.fajr]!.endTime;
          expect(t[Prayer.ishraq]!.startTime, sunrise.add(const Duration(minutes: 15)));
          expect(t[Prayer.ishraq]!.endTime, t[Prayer.duha]!.startTime);
          expect(t[Prayer.duha]!.endTime, t[Prayer.dhuhr]!.startTime.subtract(const Duration(minutes: 15)));

          // Isha ends at Islamic midnight, before the last third begins, and
          // Tahajjud runs into the next day's Fajr.
          expect(t[Prayer.isha]!.endTime.isBefore(t[Prayer.tahajjud]!.startTime), isTrue);
          expect(t[Prayer.tahajjud]!.endTime.isAfter(t[Prayer.isha]!.startTime), isTrue);
          expect(t[Prayer.tahajjud]!.endTime.difference(t[Prayer.fajr]!.startTime).inHours, inInclusiveRange(22, 25));
        });
      }
    }

    test('optional prayers are left out when turned off', () {
      final t = timesFor(dhaka, DateTime(2026, 10, 27), sunnah: false);
      expect(t.keys.toSet(), fardhPrayers.toSet());
    });

    test('Dhaka times land near published values (MWL)', () {
      // Dhaka 2026-10-27 (UTC+6): Fajr ~4:45, Dhuhr ~11:40, Maghrib ~17:20.
      final t = timesFor(dhaka, DateTime(2026, 10, 27));
      DateTime local(Prayer p) => t[p]!.startTime.toUtc().add(const Duration(hours: 6));
      expect(local(Prayer.dhuhr).hour, 11);
      expect(local(Prayer.dhuhr).minute, inInclusiveRange(30, 50));
      expect(local(Prayer.maghrib).hour, 17);
      expect(local(Prayer.fajr).hour, 4);
    });

    test('Hanafi Asr comes later than Shafi Asr', () {
      final date = DateTime(2026, 10, 27);
      final shafi = timesFor(dhaka, date, madhab: MadhabType.shafi);
      final hanafi = timesFor(dhaka, date, madhab: MadhabType.hanafi);
      expect(hanafi[Prayer.asr]!.startTime.isAfter(shafi[Prayer.asr]!.startTime), isTrue);
      expect(hanafi[Prayer.dhuhr]!.startTime, shafi[Prayer.dhuhr]!.startTime);
    });

    test('every calculation method produces a full day', () {
      for (final method in CalculationMethodType.values) {
        final t = timesFor(makkah, DateTime(2026, 3, 20), method: method);
        expect(t[Prayer.fajr]!.startTime.isBefore(t[Prayer.isha]!.startTime), isTrue, reason: '$method');
      }
    });

    test('Qibla points roughly west-north-west from Dhaka and south-east from London', () {
      expect(service.getQiblaDirection(dhaka), closeTo(277.5, 3));
      expect(service.getQiblaDirection(london), closeTo(119, 3));
    });
  });

  group('current and next prayer', () {
    final t = timesFor(dhaka, DateTime(2026, 10, 27));
    DateTime mid(Prayer p) => t[p]!.startTime.add(Duration(milliseconds: t[p]!.duration.inMilliseconds ~/ 2));

    test('inside each window the current prayer is that prayer', () {
      for (final p in [Prayer.fajr, Prayer.ishraq, Prayer.duha, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha]) {
        expect(service.getCurrentPrayer(t, mid(p)), p);
      }
    });

    test('the start instant belongs to the prayer, the end instant does not', () {
      expect(service.getCurrentPrayer(t, t[Prayer.dhuhr]!.startTime), Prayer.dhuhr);
      expect(t[Prayer.fajr]!.isWithinWindow(t[Prayer.fajr]!.endTime), isFalse);
    });

    test('in the makruh gap before Maghrib nothing is current', () {
      final gap = t[Prayer.asr]!.endTime.add(const Duration(minutes: 5));
      expect(service.getCurrentPrayer(t, gap), isNull);
      expect(service.getNextPrayer(t, gap), Prayer.maghrib);
    });

    test('next prayer walks forward through the day', () {
      expect(service.getNextPrayer(t, mid(Prayer.fajr)), Prayer.ishraq);
      expect(service.getNextPrayer(t, mid(Prayer.dhuhr)), Prayer.asr);
      expect(service.getNextPrayer(t, mid(Prayer.maghrib)), Prayer.isha);
    });

    test('after Isha the next prayer is the night prayer, then Fajr wraps around', () {
      expect(service.getNextPrayer(t, mid(Prayer.isha)), Prayer.tahajjud);
      final afterAll = t[Prayer.tahajjud]!.startTime.add(const Duration(minutes: 1));
      expect(service.getNextPrayer(t, afterAll), Prayer.fajr);
    });

    test('countdowns are positive and roll over to tomorrow', () {
      final now = mid(Prayer.dhuhr);
      expect(service.getCountdownToNextPrayer(t, now, Prayer.asr), t[Prayer.asr]!.startTime.difference(now));
      final late = t[Prayer.isha]!.startTime.add(const Duration(hours: 1));
      final toFajr = service.getCountdownToNextPrayer(t, late, Prayer.fajr);
      expect(toFajr.isNegative, isFalse);
      expect(toFajr.inHours, lessThan(12));
      expect(service.getCountdownDuration(t, mid(Prayer.asr)), t[Prayer.asr]!.endTime.difference(mid(Prayer.asr)));
    });

    test('period follows the sky through the day', () {
      expect(service.getCurrentPrayerPeriod(t, mid(Prayer.fajr)), PrayerPeriod.fajr);
      expect(service.getCurrentPrayerPeriod(t, mid(Prayer.duha)), PrayerPeriod.sunrise);
      expect(service.getCurrentPrayerPeriod(t, mid(Prayer.dhuhr)), PrayerPeriod.dhuhr);
      // Asr colours hold through the makruh gap until Maghrib.
      expect(service.getCurrentPrayerPeriod(t, t[Prayer.asr]!.endTime.add(const Duration(minutes: 5))), PrayerPeriod.asr);
      expect(service.getCurrentPrayerPeriod(t, mid(Prayer.maghrib)), PrayerPeriod.maghrib);
      expect(service.getCurrentPrayerPeriod(t, mid(Prayer.isha)), PrayerPeriod.isha);
      expect(service.getCurrentPrayerPeriod(t, t[Prayer.tahajjud]!.startTime.add(const Duration(minutes: 10))),
          PrayerPeriod.tahajjud);
    });
  });

  group('PrayerTimeData', () {
    final data = PrayerTimeData(
      prayer: Prayer.asr,
      startTime: DateTime(2026, 1, 1, 15),
      endTime: DateTime(2026, 1, 1, 17),
    );

    test('remaining and time-until never go negative in the wrong direction', () {
      expect(data.getRemainingTime(DateTime(2026, 1, 1, 16)), const Duration(hours: 1));
      expect(data.getTimeUntilStart(DateTime(2026, 1, 1, 14)), const Duration(hours: 1));
      expect(data.getTimeUntilStart(DateTime(2026, 1, 1, 16)), Duration.zero);
    });
  });

  group('Jumuah', () {
    test('Dhuhr reads as Jumuah on Fridays only', () {
      expect(service.getPrayerDisplayName(Prayer.dhuhr, DateTime(2026, 10, 30)), 'Jumuah');
      expect(service.getPrayerDisplayName(Prayer.dhuhr, DateTime(2026, 10, 29)), Prayer.dhuhr.displayName);
      expect(service.getPrayerDisplayName(Prayer.asr, DateTime(2026, 10, 30)), Prayer.asr.displayName);
      expect(service.isFriday(DateTime(2026, 10, 30)), isTrue);
    });
  });

  group('LocationData', () {
    test('display name falls back from city to coordinates', () {
      expect(const LocationData(latitude: 1, longitude: 2, city: 'A', country: 'B').displayName, 'A, B');
      expect(const LocationData(latitude: 1, longitude: 2, city: 'A').displayName, 'A');
      expect(const LocationData(latitude: 1, longitude: 2, country: 'B').displayName, 'B');
      expect(const LocationData(latitude: 1.234, longitude: 2.345).displayName, '1.23°, 2.35°');
    });

    test('validity', () {
      expect(const LocationData(latitude: 0, longitude: 0).isValid, isFalse);
      expect(const LocationData(latitude: 91, longitude: 0).isValid, isFalse);
      expect(dhaka.isValid, isTrue);
      expect(const AppSettings().isValid, isFalse);
      expect(const AppSettings(location: dhaka).isValid, isTrue);
    });
  });
}
