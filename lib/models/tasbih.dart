import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'tasbih.g.dart';

/// A dhikr counter. Counting goes in rounds of [targetCount]: reaching the
/// target fills the ring, and the next tap starts the next round rather than
/// silently wrapping.
@HiveType(typeId: 25)
class Tasbih extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  /// Count within the current round, 0..[targetCount]. Older data may hold a
  /// value above the target; that reads as a full round.
  @HiveField(2)
  final int currentCount;

  @HiveField(3)
  final int targetCount;

  @HiveField(4)
  final int totalCount; // Lifetime count

  @HiveField(5)
  final DateTime lastUpdated;

  /// Rounds finished since the counter was last reset.
  @HiveField(6)
  final int completedRounds;

  /// Taps on [todayKey]; read through [todayCount] so a new day starts at 0.
  @HiveField(7)
  final int dayCount;

  @HiveField(8)
  final String? todayKey;

  const Tasbih({
    required this.id,
    required this.name,
    this.currentCount = 0,
    this.targetCount = 33,
    this.totalCount = 0,
    required this.lastUpdated,
    this.completedRounds = 0,
    this.dayCount = 0,
    this.todayKey,
  });

  bool get isRoundFull => currentCount >= targetCount;

  /// The round being counted, starting at 1.
  int get round => completedRounds + 1;

  int todayCount({DateTime? now}) =>
      todayKey == dateKey(now ?? DateTime.now()) ? dayCount : 0;

  /// One tap: starts a new round first if the current one is full.
  Tasbih tapped({DateTime? now}) {
    final at = now ?? DateTime.now();
    final full = isRoundFull;
    return _withDay(1, at).copyWith(
      currentCount: full ? 1 : currentCount + 1,
      completedRounds: full ? completedRounds + 1 : completedRounds,
      totalCount: totalCount + 1,
      lastUpdated: at,
    );
  }

  /// Takes back the last tap, stepping back into the previous round if the
  /// tap had started a new one. Does nothing on an untouched counter.
  Tasbih undone({DateTime? now}) {
    final at = now ?? DateTime.now();
    if (currentCount <= 0) return this;
    final backToPrevious = currentCount == 1 && completedRounds > 0;
    return _withDay(-1, at).copyWith(
      currentCount: backToPrevious ? targetCount : (currentCount > targetCount ? targetCount : currentCount) - 1,
      completedRounds: backToPrevious ? completedRounds - 1 : completedRounds,
      totalCount: totalCount > 0 ? totalCount - 1 : 0,
      lastUpdated: at,
    );
  }

  /// Clears the current round and round count; totals are kept.
  Tasbih reset({DateTime? now}) => copyWith(
        currentCount: 0,
        completedRounds: 0,
        lastUpdated: now ?? DateTime.now(),
      );

  /// Adds [delta] (may be negative) to today's and the lifetime totals
  /// without touching the round. Used for taps made inside a session.
  Tasbih tallied(int delta, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final total = totalCount + delta;
    return _withDay(delta, at).copyWith(totalCount: total < 0 ? 0 : total, lastUpdated: at);
  }

  Tasbih _withDay(int delta, DateTime at) {
    final key = dateKey(at);
    final base = todayKey == key ? dayCount : 0;
    final next = base + delta;
    return copyWith(dayCount: next < 0 ? 0 : next, todayKey: key);
  }

  Tasbih copyWith({
    String? id,
    String? name,
    int? currentCount,
    int? targetCount,
    int? totalCount,
    DateTime? lastUpdated,
    int? completedRounds,
    int? dayCount,
    String? todayKey,
  }) {
    return Tasbih(
      id: id ?? this.id,
      name: name ?? this.name,
      currentCount: currentCount ?? this.currentCount,
      targetCount: targetCount ?? this.targetCount,
      totalCount: totalCount ?? this.totalCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      completedRounds: completedRounds ?? this.completedRounds,
      dayCount: dayCount ?? this.dayCount,
      todayKey: todayKey ?? this.todayKey,
    );
  }

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
        id,
        name,
        currentCount,
        targetCount,
        totalCount,
        lastUpdated,
        completedRounds,
        dayCount,
        todayKey,
      ];
}
