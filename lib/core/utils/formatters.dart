import 'package:intl/intl.dart';

/// Formatting utility functions
class AppFormatters {
  AppFormatters._();

  // ============================================
  // TIME FORMATTING
  // ============================================

  /// Format time as "3:45 PM"
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Format time as "15:45" (24-hour)
  static String formatTime24(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Format time with seconds "3:45:30 PM"
  static String formatTimeWithSeconds(DateTime time) {
    return DateFormat('h:mm:ss a').format(time);
  }

  // ============================================
  // DATE FORMATTING
  // ============================================

  /// Format date as "January 30, 2026"
  static String formatDateFull(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Format date as "Jan 30"
  static String formatDateShort(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  /// Format date as "30 Jan 2026"
  static String formatDateMedium(DateTime date) {
    return DateFormat('d MMM y').format(date);
  }

  /// Format date as "2026-01-30"
  static String formatDateIso(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format date as "Friday, January 30"
  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEEE, MMMM d').format(date);
  }

  // ============================================
  // COUNTDOWN FORMATTING
  // ============================================

  /// Format duration for countdown display
  /// 
  /// Returns different formats based on remaining time:
  /// - >1 hour: "2h 34m"
  /// - <1 hour: "45m"
  /// - <5 minutes: "3m 12s"
  /// - <1 minute: "42s"
  static String formatCountdown(Duration duration) {
    if (duration.isNegative) {
      return '0s';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes >= 5) {
      return '${minutes}m';
    } else if (minutes >= 1) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Format countdown with "remaining" suffix
  static String formatCountdownWithSuffix(Duration duration) {
    return '${formatCountdown(duration)} remaining';
  }

  /// Format duration in full (for accessibility)
  static String formatDurationFull(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final parts = <String>[];
    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
    }
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
    }
    if (seconds > 0 && hours == 0) {
      parts.add('$seconds ${seconds == 1 ? 'second' : 'seconds'}');
    }

    return parts.join(' ');
  }

  // ============================================
  // PRAYER TIME WINDOW FORMATTING
  // ============================================

  /// Format time window as "3:45 PM - 6:12 PM"
  static String formatTimeWindow(DateTime start, DateTime end) {
    return '${formatTime(start)} - ${formatTime(end)}';
  }

  // ============================================
  // PERCENTAGE FORMATTING
  // ============================================

  /// Format percentage as "75%"
  static String formatPercentage(int percentage) {
    return '$percentage%';
  }

  /// Format percentage as "75% on-time"
  static String formatCompletionPercentage(int percentage) {
    return '$percentage% on-time';
  }

  // ============================================
  // STREAK FORMATTING
  // ============================================

  /// Format streak as "🔥 7-day streak"
  static String formatStreak(int days) {
    if (days == 0) {
      return 'No streak';
    } else if (days == 1) {
      return '🔥 1 day';
    } else {
      return '🔥 $days days';
    }
  }

  /// Format prayer count as "21/35 prayers"
  static String formatPrayerCount(int completed, int total) {
    return '$completed/$total prayers';
  }

  // ============================================
  // COORDINATE FORMATTING
  // ============================================

  /// Format coordinates as "40.71°N, 74.01°W"
  static String formatCoordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(2)}°$latDir, ${lng.abs().toStringAsFixed(2)}°$lngDir';
  }

  /// Format bearing as "58° NE"
  static String formatBearing(double bearing) {
    // Normalize to 0-360
    bearing = bearing % 360;
    if (bearing < 0) bearing += 360;

    String direction;
    if (bearing >= 337.5 || bearing < 22.5) {
      direction = 'N';
    } else if (bearing >= 22.5 && bearing < 67.5) {
      direction = 'NE';
    } else if (bearing >= 67.5 && bearing < 112.5) {
      direction = 'E';
    } else if (bearing >= 112.5 && bearing < 157.5) {
      direction = 'SE';
    } else if (bearing >= 157.5 && bearing < 202.5) {
      direction = 'S';
    } else if (bearing >= 202.5 && bearing < 247.5) {
      direction = 'SW';
    } else if (bearing >= 247.5 && bearing < 292.5) {
      direction = 'W';
    } else {
      direction = 'NW';
    }

    return '${bearing.round()}° $direction';
  }

  // ============================================
  // DISTANCE FORMATTING
  // ============================================

  /// Format distance in km or m
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${meters.round()} m';
    }
  }
}
