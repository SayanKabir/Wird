import 'package:equatable/equatable.dart';

class SunnahProgress extends Equatable {
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final int totalPracticeActions;
  final String? lastPracticeDateKey;
  final Map<String, int> practiceCountsBySunnah;
  final Map<String, String> lastPracticedDayBySunnah;

  const SunnahProgress({
    required this.totalPoints,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalPracticeActions,
    this.lastPracticeDateKey,
    required this.practiceCountsBySunnah,
    required this.lastPracticedDayBySunnah,
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

  int get level => (totalPoints ~/ 100) + 1;
  int get pointsIntoLevel => totalPoints % 100;
  double get levelProgress => pointsIntoLevel / 100.0;
  int get uniqueSunnahsPracticed => practiceCountsBySunnah.length;

  bool isPracticedToday(String sunnahId, {DateTime? now}) {
    final key = _dateKey(now ?? DateTime.now());
    return lastPracticedDayBySunnah[sunnahId] == key;
  }

  List<String> get unlockedBadges {
    final badges = <String>[];
    if (totalPracticeActions >= 1) badges.add('Starter');
    if (currentStreak >= 7 || longestStreak >= 7) badges.add('7-Day Flame');
    if (uniqueSunnahsPracticed >= 10) badges.add('Explorer');
    if (currentStreak >= 30 || longestStreak >= 30) badges.add('Reviver');
    if (totalPoints >= 1000) badges.add('Master');
    return badges;
  }

  SunnahProgress copyWith({
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    int? totalPracticeActions,
    String? lastPracticeDateKey,
    Map<String, int>? practiceCountsBySunnah,
    Map<String, String>? lastPracticedDayBySunnah,
  }) {
    return SunnahProgress(
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalPracticeActions: totalPracticeActions ?? this.totalPracticeActions,
      lastPracticeDateKey: lastPracticeDateKey ?? this.lastPracticeDateKey,
      practiceCountsBySunnah:
          practiceCountsBySunnah ?? this.practiceCountsBySunnah,
      lastPracticedDayBySunnah:
          lastPracticedDayBySunnah ?? this.lastPracticedDayBySunnah,
    );
  }

  static String _dateKey(DateTime date) {
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
      ];

  static List<String> _sortedMapEntries(Map<String, Object> map) {
    final entries =
        map.entries.map((e) => '${e.key}:${e.value}').toList(growable: false)
          ..sort();
    return entries;
  }
}

