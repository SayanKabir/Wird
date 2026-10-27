import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/utils/date_utils.dart';
import 'package:wird2/core/utils/formatters.dart';
import 'package:wird2/core/utils/validators.dart';

void main() {
  group('AppDateUtils', () {
    test('isSameDay ignores the time of day', () {
      expect(AppDateUtils.isSameDay(DateTime(2026, 3, 1, 0, 0), DateTime(2026, 3, 1, 23, 59)), isTrue);
      expect(AppDateUtils.isSameDay(DateTime(2026, 3, 1, 23, 59), DateTime(2026, 3, 2)), isFalse);
      expect(AppDateUtils.isSameDay(DateTime(2025, 3, 1), DateTime(2026, 3, 1)), isFalse);
    });

    test('today, yesterday and tomorrow are relative to now', () {
      final now = DateTime.now();
      expect(AppDateUtils.isToday(now), isTrue);
      expect(AppDateUtils.isYesterday(now.subtract(const Duration(days: 1))), isTrue);
      expect(AppDateUtils.isTomorrow(now.add(const Duration(days: 1))), isTrue);
      expect(AppDateUtils.isToday(now.add(const Duration(days: 1))), isFalse);
    });

    test('start and end of day bracket the whole day', () {
      final d = DateTime(2026, 7, 14, 15, 30);
      expect(AppDateUtils.startOfDay(d), DateTime(2026, 7, 14));
      expect(AppDateUtils.endOfDay(d), DateTime(2026, 7, 14, 23, 59, 59, 999));
    });

    test('weeks start on Monday, months on the 1st', () {
      // 2026-10-29 is a Thursday.
      expect(AppDateUtils.startOfWeek(DateTime(2026, 10, 29, 9)), DateTime(2026, 10, 26));
      // A Monday is its own week start.
      expect(AppDateUtils.startOfWeek(DateTime(2026, 10, 26, 22)), DateTime(2026, 10, 26));
      // A Sunday belongs to the week that began six days earlier.
      expect(AppDateUtils.startOfWeek(DateTime(2026, 11, 1)), DateTime(2026, 10, 26));
      expect(AppDateUtils.startOfMonth(DateTime(2026, 10, 29)), DateTime(2026, 10, 1));
    });

    test('isFriday only on Fridays', () {
      expect(AppDateUtils.isFriday(DateTime(2026, 10, 30)), isTrue);
      expect(AppDateUtils.isFriday(DateTime(2026, 10, 31)), isFalse);
    });

    test('Islamic midnight is halfway from Maghrib to Fajr', () {
      final maghrib = DateTime(2026, 1, 1, 18, 0);
      final fajr = DateTime(2026, 1, 2, 5, 0);
      expect(AppDateUtils.calculateIslamicMidnight(maghrib, fajr), DateTime(2026, 1, 1, 23, 30));
    });

    test('last third of the night starts two thirds after Isha', () {
      final isha = DateTime(2026, 1, 1, 20, 0);
      final fajr = DateTime(2026, 1, 2, 5, 0);
      expect(AppDateUtils.calculateLastThirdOfNight(isha, fajr), DateTime(2026, 1, 2, 2, 0));
    });

    test('days in month handles leap years', () {
      expect(AppDateUtils.getDaysInMonth(2024, 2), 29);
      expect(AppDateUtils.getDaysInMonth(2025, 2), 28);
      expect(AppDateUtils.getDaysInMonth(2100, 2), 28);
      expect(AppDateUtils.getDaysInMonth(2000, 2), 29);
      expect(AppDateUtils.getDaysInMonth(2026, 12), 31);
      expect(AppDateUtils.getDaysInMonth(2026, 4), 30);
    });

    test('week and month date lists', () {
      final week = AppDateUtils.getWeekDates(DateTime(2026, 12, 28));
      expect(week, hasLength(7));
      expect(week.last, DateTime(2027, 1, 3));
      final month = AppDateUtils.getMonthDates(2024, 2);
      expect(month, hasLength(29));
      expect(month.first, DateTime(2024, 2, 1));
      expect(month.last, DateTime(2024, 2, 29));
    });

    test('day names', () {
      expect(AppDateUtils.getDayName(DateTime(2026, 10, 30)), 'Friday');
      expect(AppDateUtils.getShortDayName(DateTime(2026, 10, 30)), 'Fri');
    });
  });

  group('AppFormatters', () {
    test('times', () {
      final t = DateTime(2026, 1, 1, 13, 5, 9);
      expect(AppFormatters.formatTime(t), '1:05 PM');
      expect(AppFormatters.formatTime24(t), '13:05');
      expect(AppFormatters.formatTimeWithSeconds(t), '1:05:09 PM');
      expect(AppFormatters.formatTime(DateTime(2026, 1, 1, 0, 0)), '12:00 AM');
      expect(AppFormatters.formatTimeWindow(DateTime(2026, 1, 1, 15, 45), DateTime(2026, 1, 1, 18, 12)),
          '3:45 PM - 6:12 PM');
    });

    test('dates', () {
      final d = DateTime(2026, 10, 27);
      expect(AppFormatters.formatDateFull(d), 'October 27, 2026');
      expect(AppFormatters.formatDateShort(d), 'Oct 27');
      expect(AppFormatters.formatDateMedium(d), '27 Oct 2026');
      expect(AppFormatters.formatDateIso(d), '2026-10-27');
      expect(AppFormatters.formatDateWithDay(d), 'Tuesday, October 27');
    });

    test('countdown picks its precision by how much time is left', () {
      expect(AppFormatters.formatCountdown(const Duration(hours: 2, minutes: 34, seconds: 10)), '2h 34m');
      expect(AppFormatters.formatCountdown(const Duration(minutes: 45, seconds: 30)), '45m');
      expect(AppFormatters.formatCountdown(const Duration(minutes: 5)), '5m');
      expect(AppFormatters.formatCountdown(const Duration(minutes: 3, seconds: 12)), '3m 12s');
      expect(AppFormatters.formatCountdown(const Duration(seconds: 42)), '42s');
      expect(AppFormatters.formatCountdown(Duration.zero), '0s');
      expect(AppFormatters.formatCountdown(const Duration(seconds: -5)), '0s');
      expect(AppFormatters.formatCountdownWithSuffix(const Duration(minutes: 10)), '10m remaining');
    });

    test('full durations read naturally', () {
      expect(AppFormatters.formatDurationFull(const Duration(hours: 1, minutes: 1)), '1 hour 1 minute');
      expect(AppFormatters.formatDurationFull(const Duration(hours: 2, minutes: 30, seconds: 5)), '2 hours 30 minutes');
      expect(AppFormatters.formatDurationFull(const Duration(minutes: 2, seconds: 1)), '2 minutes 1 second');
      expect(AppFormatters.formatDurationFull(Duration.zero), '');
    });

    test('percentages, streaks and counts', () {
      expect(AppFormatters.formatPercentage(75), '75%');
      expect(AppFormatters.formatCompletionPercentage(80), '80% on-time');
      expect(AppFormatters.formatStreak(0), 'No streak');
      expect(AppFormatters.formatStreak(1), '1 day');
      expect(AppFormatters.formatStreak(7), '7 days');
      expect(AppFormatters.formatPrayerCount(21, 35), '21/35 prayers');
    });

    test('coordinates use hemisphere letters', () {
      expect(AppFormatters.formatCoordinates(40.7128, -74.006), '40.71°N, 74.01°W');
      expect(AppFormatters.formatCoordinates(-33.8688, 151.2093), '33.87°S, 151.21°E');
      expect(AppFormatters.formatCoordinates(0, 0), '0.00°N, 0.00°E');
    });

    test('bearings normalise and name all eight directions', () {
      expect(AppFormatters.formatBearing(0), '0° N');
      expect(AppFormatters.formatBearing(359), '359° N');
      expect(AppFormatters.formatBearing(45), '45° NE');
      expect(AppFormatters.formatBearing(90), '90° E');
      expect(AppFormatters.formatBearing(135), '135° SE');
      expect(AppFormatters.formatBearing(180), '180° S');
      expect(AppFormatters.formatBearing(225), '225° SW');
      expect(AppFormatters.formatBearing(270), '270° W');
      expect(AppFormatters.formatBearing(315), '315° NW');
      expect(AppFormatters.formatBearing(-90), '270° W');
      expect(AppFormatters.formatBearing(450), '90° E');
    });

    test('distances switch to km at 1000 m', () {
      expect(AppFormatters.formatDistance(999.4), '999 m');
      expect(AppFormatters.formatDistance(1000), '1.0 km');
      expect(AppFormatters.formatDistance(12345), '12.3 km');
    });
  });

  group('Validators', () {
    test('latitude and longitude ranges are inclusive', () {
      expect(Validators.isValidLatitude(90), isTrue);
      expect(Validators.isValidLatitude(-90), isTrue);
      expect(Validators.isValidLatitude(90.01), isFalse);
      expect(Validators.isValidLongitude(180), isTrue);
      expect(Validators.isValidLongitude(-180.5), isFalse);
    });

    test('null island is rejected', () {
      expect(Validators.isValidCoordinates(0, 0), isFalse);
      expect(Validators.isValidCoordinates(0, 1), isTrue);
      expect(Validators.isValidCoordinates(23.8, 90.4), isTrue);
      expect(Validators.isValidCoordinates(100, 0), isFalse);
    });

    test('high and extreme latitudes in both hemispheres', () {
      expect(Validators.isHighLatitude(48), isFalse);
      expect(Validators.isHighLatitude(48.1), isTrue);
      expect(Validators.isHighLatitude(-60), isTrue);
      expect(Validators.isExtremeLatitude(65), isFalse);
      expect(Validators.isExtremeLatitude(-70), isTrue);
      expect(Validators.getHighLatitudeWarning(30), isNull);
      expect(Validators.getHighLatitudeWarning(55), contains('high latitude'));
      expect(Validators.getHighLatitudeWarning(70), contains('polar'));
    });

    test('city names', () {
      expect(Validators.isValidCityName('  '), isFalse);
      expect(Validators.isValidCityName('A'), isFalse);
      expect(Validators.isValidCityName(' Ur '), isTrue);
      expect(Validators.isValidCityName('x' * 100), isTrue);
      expect(Validators.isValidCityName('x' * 101), isFalse);
    });

    test('settings ranges', () {
      expect(Validators.isValidSnoozeDuration(0), isFalse);
      expect(Validators.isValidSnoozeDuration(30), isTrue);
      expect(Validators.isValidSnoozeDuration(31), isFalse);
      for (final m in [5, 10, 15, 20, 30]) {
        expect(Validators.isValidEndWarningMinutes(m), isTrue);
      }
      expect(Validators.isValidEndWarningMinutes(25), isFalse);
      expect(Validators.isValidTextSizeMultiplier(0.8), isTrue);
      expect(Validators.isValidTextSizeMultiplier(2.0), isTrue);
      expect(Validators.isValidTextSizeMultiplier(2.1), isFalse);
      expect(Validators.isValidTextSizeMultiplier(0.5), isFalse);
    });

    test('coordinate error messages', () {
      expect(Validators.validateCoordinatesError(null, 1), contains('required'));
      expect(Validators.validateCoordinatesError(91, 1), contains('latitude'));
      expect(Validators.validateCoordinatesError(1, 181), contains('longitude'));
      expect(Validators.validateCoordinatesError(0, 0), contains('invalid'));
      expect(Validators.validateCoordinatesError(21.4, 39.8), isNull);
    });
  });
}
