import 'package:hive/hive.dart';

part 'quran_progress.g.dart';

@HiveType(typeId: 33)
class QuranProgress extends HiveObject {
  @HiveField(0)
  int totalVersesRead;

  @HiveField(1)
  int currentStreak;

  @HiveField(2)
  int longestStreak;

  @HiveField(3)
  int daysRead;

  @HiveField(4)
  Map<String, int> versesReadByDay;
  
  @HiveField(5)
  String? lastReadDateKey;

  QuranProgress({
    this.totalVersesRead = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.daysRead = 0,
    Map<String, int>? versesReadByDay,
    this.lastReadDateKey,
  }) : versesReadByDay = versesReadByDay ?? {};

  factory QuranProgress.empty() => QuranProgress();

  QuranProgress copyWith({
    int? totalVersesRead,
    int? currentStreak,
    int? longestStreak,
    int? daysRead,
    Map<String, int>? versesReadByDay,
    String? lastReadDateKey,
  }) {
    return QuranProgress(
      totalVersesRead: totalVersesRead ?? this.totalVersesRead,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      daysRead: daysRead ?? this.daysRead,
      versesReadByDay: versesReadByDay ?? this.versesReadByDay,
      lastReadDateKey: lastReadDateKey ?? this.lastReadDateKey,
    );
  }
}
