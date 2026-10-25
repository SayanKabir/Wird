import 'package:flutter/material.dart' show IconData, Icons;
import 'package:hive/hive.dart';

part 'prayer.g.dart';

/// Prayer types in Islam
/// 
/// Includes 5 Fardh (obligatory) prayers and 3 optional Sunnah prayers
@HiveType(typeId: 0)
enum Prayer {
  /// Optional night prayer (last third of night)
  @HiveField(0)
  tahajjud,

  /// Dawn prayer (obligatory)
  @HiveField(1)
  fajr,

  /// Post-sunrise prayer (optional)
  @HiveField(2)
  ishraq,

  /// Mid-morning prayer (optional)
  @HiveField(3)
  duha,

  /// Midday prayer (obligatory)
  /// Replaced by Jumuah on Fridays
  @HiveField(4)
  dhuhr,

  /// Afternoon prayer (obligatory)
  @HiveField(5)
  asr,

  /// Sunset prayer (obligatory)
  @HiveField(6)
  maghrib,

  /// Night prayer (obligatory)
  @HiveField(7)
  isha,
}

/// Extension methods for Prayer enum
extension PrayerExtension on Prayer {
  /// Get the display name in English
  String get displayName {
    switch (this) {
      case Prayer.tahajjud:
        return 'Tahajjud';
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.ishraq:
        return 'Ishraq';
      case Prayer.duha:
        return 'Duha';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
    }
  }

  /// Get the Arabic name
  String get arabicName {
    switch (this) {
      case Prayer.tahajjud:
        return 'التهجد';
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.ishraq:
        return 'الإشراق';
      case Prayer.duha:
        return 'الضحى';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
    }
  }

  /// Icon for this prayer, following the sun through the day. Material
  /// rounded icons rather than emoji, which rendered differently on every
  /// phone and couldn't take the card's tint.
  IconData get icon {
    switch (this) {
      case Prayer.tahajjud:
        return Icons.nights_stay_rounded;
      case Prayer.fajr:
        return Icons.wb_twilight_rounded;
      case Prayer.ishraq:
        return Icons.light_mode_outlined;
      case Prayer.duha:
        return Icons.light_mode_rounded;
      case Prayer.dhuhr:
        return Icons.wb_sunny_rounded;
      case Prayer.asr:
        return Icons.brightness_6_rounded;
      case Prayer.maghrib:
        return Icons.nightlight_round;
      case Prayer.isha:
        return Icons.dark_mode_rounded;
    }
  }

  /// Check if this is a Fardh (obligatory) prayer
  bool get isFardh {
    return this == Prayer.fajr ||
        this == Prayer.dhuhr ||
        this == Prayer.asr ||
        this == Prayer.maghrib ||
        this == Prayer.isha;
  }

  /// Check if this is a Sunnah (optional) prayer
  bool get isSunnah {
    return this == Prayer.tahajjud ||
        this == Prayer.ishraq ||
        this == Prayer.duha;
  }

  /// Get display name for Friday (Jumuah replaces Dhuhr)
  String displayNameForDay(DateTime date) {
    if (this == Prayer.dhuhr && date.weekday == DateTime.friday) {
      return 'Jumuah';
    }
    return displayName;
  }

  /// Get Arabic name for Friday
  String arabicNameForDay(DateTime date) {
    if (this == Prayer.dhuhr && date.weekday == DateTime.friday) {
      return 'الجمعة';
    }
    return arabicName;
  }

  /// Get icon for Friday
  IconData iconForDay(DateTime date) {
    if (this == Prayer.dhuhr && date.weekday == DateTime.friday) {
      return Icons.mosque_rounded;
    }
    return icon;
  }
}

/// All Fardh prayers in order
const List<Prayer> fardhPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// All Sunnah prayers in order
const List<Prayer> sunnahPrayers = [
  Prayer.tahajjud,
  Prayer.ishraq,
  Prayer.duha,
];

/// All prayers in chronological order (for a typical day)
const List<Prayer> allPrayersInOrder = [
  Prayer.tahajjud,
  Prayer.fajr,
  Prayer.ishraq,
  Prayer.duha,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];
