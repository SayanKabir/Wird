import 'package:flutter/material.dart' show IconData, Icons;
import 'package:hive/hive.dart';

part 'prayer_status.g.dart';

/// Status of a prayer
/// 
/// Represents whether a prayer was completed on time, late, missed, etc.
@HiveType(typeId: 1)
enum PrayerStatus {
  /// Prayer time is active, not yet prayed
  @HiveField(0)
  pending,

  /// Prayer completed within the valid time window
  @HiveField(1)
  onTime,

  /// Prayer completed after the time window ended (Qadha)
  @HiveField(2)
  late,

  /// Prayer time ended, not completed
  @HiveField(3)
  missed,

  /// Future prayer for today
  @HiveField(4)
  upcoming,
}

/// Extension methods for PrayerStatus
extension PrayerStatusExtension on PrayerStatus {
  /// Get the display name
  String get displayName {
    switch (this) {
      case PrayerStatus.pending:
        return 'Pending';
      case PrayerStatus.onTime:
        return 'Prayed On Time';
      case PrayerStatus.late:
        return 'Prayed Late';
      case PrayerStatus.missed:
        return 'Missed';
      case PrayerStatus.upcoming:
        return 'Upcoming';
    }
  }

  /// Get the status icon
  IconData get icon {
    switch (this) {
      case PrayerStatus.pending:
        return Icons.hourglass_bottom_rounded;
      case PrayerStatus.onTime:
        return Icons.check_circle_rounded;
      case PrayerStatus.late:
        return Icons.schedule_rounded;
      case PrayerStatus.missed:
        return Icons.cancel_rounded;
      case PrayerStatus.upcoming:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  /// Check if this status counts toward streak
  bool get countsTowardStreak {
    return this == PrayerStatus.onTime;
  }

  /// Check if this status breaks streak
  bool get breaksStreak {
    return this == PrayerStatus.missed;
  }

  /// Check if this prayer was completed (either on time or late)
  bool get isCompleted {
    return this == PrayerStatus.onTime || this == PrayerStatus.late;
  }

  /// Check if this prayer can still be marked
  bool get canBeMarked {
    return this == PrayerStatus.pending || 
           this == PrayerStatus.upcoming ||
           this == PrayerStatus.missed;
  }
}
