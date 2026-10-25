import 'package:equatable/equatable.dart';

/// Everything the user has done with sunnahs, stored as a plain map in Hive.
///
/// The original fields (points, streaks, counts, last day per sunnah) are kept
/// as they were so existing progress carries over. Fields added for the
/// reworked section:
/// - [practiceIds]: the handful of sunnahs the user has chosen to keep.
/// - [practiceLog]: which sunnahs were done on which day, so a tick can be
///   undone cleanly.
/// - [streakBeforeToday], [longestBeforeToday], [lastDateBeforeToday]: the
///   streak as it stood before today's first tick, restored if every tick of
///   today is undone.
class SunnahProgress extends Equatable {
  /// No longer awarded or shown; kept only so old data round-trips unchanged.
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final int totalPracticeActions;
  final String? lastPracticeDateKey;
  final Map<String, int> practiceCountsBySunnah;
  final Map<String, String> lastPracticedDayBySunnah;
  final List<String> practiceIds;
  final Map<String, List<String>> practiceLog;
  final int? streakBeforeToday;
  final int? longestBeforeToday;
  final String? lastDateBeforeToday;

  const SunnahProgress({
    required this.totalPoints,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalPracticeActions,
    this.lastPracticeDateKey,
    required this.practiceCountsBySunnah,
    required this.lastPracticedDayBySunnah,
    this.practiceIds = const <String>[],
    this.practiceLog = const <String, List<String>>{},
    this.streakBeforeToday,
    this.longestBeforeToday,
    this.lastDateBeforeToday,
  });

  factory SunnahProgress.empty() {
    return const SunnahProgress(
      totalPoints: 0,
      currentStreak: 0,
      longestStreak: 0,
      totalPracticeActions: 0,
      practiceCountsBySunnah: <String, int>{},
      lastPracticedDayBySunnah: <String, String>{},
    );
  }

  int get uniqueSunnahsPracticed => practiceCountsBySunnah.length;

  bool isPracticedToday(String sunnahId, {DateTime? now}) {
    final key = dateKey(now ?? DateTime.now());
    return lastPracticedDayBySunnah[sunnahId] == key;
  }

  bool isInPractice(String sunnahId) => practiceIds.contains(sunnahId);

  /// The streak as it should read right now: one whose last day is neither
  /// today nor yesterday has already lapsed.
  int liveStreak({DateTime? now}) {
    final today = now ?? DateTime.now();
    final last = lastPracticeDateKey;
    if (last == null) return 0;
    if (last == dateKey(today) ||
        last == dateKey(today.subtract(const Duration(days: 1)))) {
      return currentStreak;
    }
    return 0;
  }

  /// Nullable fields take a closure so they can be explicitly cleared.
  SunnahProgress copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalPracticeActions,
    String? Function()? lastPracticeDateKey,
    Map<String, int>? practiceCountsBySunnah,
    Map<String, String>? lastPracticedDayBySunnah,
    List<String>? practiceIds,
    Map<String, List<String>>? practiceLog,
    int? Function()? streakBeforeToday,
    int? Function()? longestBeforeToday,
    String? Function()? lastDateBeforeToday,
  }) {
    return SunnahProgress(
      totalPoints: totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalPracticeActions: totalPracticeActions ?? this.totalPracticeActions,
      lastPracticeDateKey:
          lastPracticeDateKey != null ? lastPracticeDateKey() : this.lastPracticeDateKey,
      practiceCountsBySunnah:
          practiceCountsBySunnah ?? this.practiceCountsBySunnah,
      lastPracticedDayBySunnah:
          lastPracticedDayBySunnah ?? this.lastPracticedDayBySunnah,
      practiceIds: practiceIds ?? this.practiceIds,
      practiceLog: practiceLog ?? this.practiceLog,
      streakBeforeToday:
          streakBeforeToday != null ? streakBeforeToday() : this.streakBeforeToday,
      longestBeforeToday:
          longestBeforeToday != null ? longestBeforeToday() : this.longestBeforeToday,
      lastDateBeforeToday:
          lastDateBeforeToday != null ? lastDateBeforeToday() : this.lastDateBeforeToday,
    );
  }

  static String dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        totalPoints,
        currentStreak,
        longestStreak,
        totalPracticeActions,
        lastPracticeDateKey,
        ..._sortedMapEntries(practiceCountsBySunnah),
        ..._sortedMapEntries(lastPracticedDayBySunnah),
        practiceIds.join(','),
        ..._sortedMapEntries(practiceLog.map((k, v) => MapEntry(k, v.join(',')))),
        streakBeforeToday,
        longestBeforeToday,
        lastDateBeforeToday,
      ];

  static List<String> _sortedMapEntries(Map<String, Object> map) {
    final entries =
        map.entries.map((e) => '${e.key}:${e.value}').toList(growable: false)
          ..sort();
    return entries;
  }
}
