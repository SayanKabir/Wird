import 'package:intl/intl.dart';

/// Date and time utility functions
class AppDateUtils {
  AppDateUtils._();

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  /// Get start of day (midnight)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Check if it's Friday (for Jumuah)
  static bool isFriday(DateTime date) {
    return date.weekday == DateTime.friday;
  }

  /// Get the Islamic midnight between Maghrib today and Fajr tomorrow
  /// Islamic midnight = Maghrib + (Fajr - Maghrib) / 2
  static DateTime calculateIslamicMidnight(DateTime maghrib, DateTime fajr) {
    final duration = fajr.difference(maghrib);
    return maghrib.add(Duration(milliseconds: duration.inMilliseconds ~/ 2));
  }

  /// Get last third of night start time (for Tahajjud)
  static DateTime calculateLastThirdOfNight(DateTime isha, DateTime fajr) {
    final nightDuration = fajr.difference(isha);
    final twoThirds = Duration(
      milliseconds: (nightDuration.inMilliseconds * 2) ~/ 3,
    );
    return isha.add(twoThirds);
  }

  /// Get day name
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Get short day name
  static String getShortDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// Get days in month
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Get list of dates for a week starting from date
  static List<DateTime> getWeekDates(DateTime startDate) {
    return List.generate(7, (i) => startDate.add(Duration(days: i)));
  }

  /// Get list of dates for a month
  static List<DateTime> getMonthDates(int year, int month) {
    final days = getDaysInMonth(year, month);
    return List.generate(days, (i) => DateTime(year, month, i + 1));
  }
}
