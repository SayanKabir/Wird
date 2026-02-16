import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'prayer.dart';
import 'prayer_status.dart';

part 'prayer_log.g.dart';

/// Entry for a single prayer in the daily log
@HiveType(typeId: 2)
class PrayerEntry extends Equatable {
  /// The status of this prayer
  @HiveField(0)
  final PrayerStatus status;

  /// When the prayer was marked as completed (null if not completed)
  @HiveField(1)
  final DateTime? timestamp;

  /// Whether the prayer was done in congregation (Jama'ah)
  @HiveField(2)
  final bool isJamaah;

  const PrayerEntry({
    required this.status,
    this.timestamp,
    this.isJamaah = false,
  });

  /// Create a pending prayer entry
  factory PrayerEntry.pending() => const PrayerEntry(
    status: PrayerStatus.pending,
  );

  /// Create an upcoming prayer entry
  factory PrayerEntry.upcoming() => const PrayerEntry(
    status: PrayerStatus.upcoming,
  );

  /// Create a completed prayer entry
  factory PrayerEntry.completed({
    required bool isOnTime,
    bool isJamaah = false,
  }) => PrayerEntry(
    status: isOnTime ? PrayerStatus.onTime : PrayerStatus.late,
    timestamp: DateTime.now(),
    isJamaah: isJamaah,
  );

  /// Create a missed prayer entry
  factory PrayerEntry.missed() => const PrayerEntry(
    status: PrayerStatus.missed,
  );

  /// Create a copy with updated values
  PrayerEntry copyWith({
    PrayerStatus? status,
    DateTime? timestamp,
    bool? isJamaah,
  }) {
    return PrayerEntry(
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isJamaah: isJamaah ?? this.isJamaah,
    );
  }

  @override
  List<Object?> get props => [status, timestamp, isJamaah];
}

/// Daily prayer log containing status for all prayers
@HiveType(typeId: 3)
class PrayerLog extends Equatable {
  /// The date for this log
  @HiveField(0)
  final DateTime date;

  /// Prayer entries mapped by prayer type
  @HiveField(1)
  final Map<Prayer, PrayerEntry> entries;

  /// Whether all required prayers were completed on time
  @HiveField(2)
  final bool isPerfectDay;

  /// Percentage of prayers completed on time (0-100)
  @HiveField(3)
  final int completionPercentage;

  const PrayerLog({
    required this.date,
    required this.entries,
    this.isPerfectDay = false,
    this.completionPercentage = 0,
  });

  /// Create an empty log for today
  factory PrayerLog.forToday({
    required List<Prayer> enabledPrayers,
    required Prayer? currentPrayer,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final entries = <Prayer, PrayerEntry>{};
    
    for (final prayer in enabledPrayers) {
      if (currentPrayer != null) {
        final prayerIndex = allPrayersInOrder.indexOf(prayer);
        final currentIndex = allPrayersInOrder.indexOf(currentPrayer);
        
        if (prayerIndex < currentIndex) {
          // Past prayer - pending (user needs to mark)
          entries[prayer] = PrayerEntry.pending();
        } else if (prayerIndex == currentIndex) {
          // Current prayer
          entries[prayer] = PrayerEntry.pending();
        } else {
          // Future prayer
          entries[prayer] = PrayerEntry.upcoming();
        }
      } else {
        entries[prayer] = PrayerEntry.upcoming();
      }
    }
    
    return PrayerLog(
      date: today,
      entries: entries,
    );
  }

  /// Get entry for a specific prayer
  PrayerEntry? getEntry(Prayer prayer) => entries[prayer];

  /// Check if a prayer is in this log
  bool hasPrayer(Prayer prayer) => entries.containsKey(prayer);

  /// Get all completed prayers (on time or late)
  List<Prayer> get completedPrayers => entries.entries
      .where((e) => e.value.status.isCompleted)
      .map((e) => e.key)
      .toList();

  /// Get all on-time prayers
  List<Prayer> get onTimePrayers => entries.entries
      .where((e) => e.value.status == PrayerStatus.onTime)
      .map((e) => e.key)
      .toList();

  /// Get all missed prayers
  List<Prayer> get missedPrayers => entries.entries
      .where((e) => e.value.status == PrayerStatus.missed)
      .map((e) => e.key)
      .toList();

  /// Calculate completion percentage
  int calculateCompletionPercentage(List<Prayer> enabledFardh) {
    if (enabledFardh.isEmpty) return 0;
    
    final onTimeCount = entries.entries
        .where((e) => enabledFardh.contains(e.key))
        .where((e) => e.value.status == PrayerStatus.onTime)
        .length;
    
    return ((onTimeCount / enabledFardh.length) * 100).round();
  }

  /// Check if all enabled Fardh prayers were on time
  bool checkIsPerfectDay(List<Prayer> enabledFardh, List<Prayer> enabledSunnah) {
    // All Fardh must be on time
    final fardhOnTime = enabledFardh.every((prayer) =>
        entries[prayer]?.status == PrayerStatus.onTime);
    
    // All enabled Sunnah must be on time
    final sunnahOnTime = enabledSunnah.every((prayer) =>
        entries[prayer]?.status == PrayerStatus.onTime);
    
    return fardhOnTime && sunnahOnTime;
  }

  /// Create a copy with updated values
  PrayerLog copyWith({
    DateTime? date,
    Map<Prayer, PrayerEntry>? entries,
    bool? isPerfectDay,
    int? completionPercentage,
  }) {
    return PrayerLog(
      date: date ?? this.date,
      entries: entries ?? Map.from(this.entries),
      isPerfectDay: isPerfectDay ?? this.isPerfectDay,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  /// Update a single prayer entry
  PrayerLog updatePrayer(Prayer prayer, PrayerEntry entry) {
    final newEntries = Map<Prayer, PrayerEntry>.from(entries);
    newEntries[prayer] = entry;
    return copyWith(entries: newEntries);
  }

  @override
  List<Object?> get props => [date, entries, isPerfectDay, completionPercentage];
}
