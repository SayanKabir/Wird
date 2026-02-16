import 'package:hive_flutter/hive_flutter.dart';

import '../../models/sunnah_progress.dart';

class SunnahProgressRepository {
  static const String _boxName = 'sunnah_progress';
  static const String _key = 'progress';

  Future<Box<dynamic>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox<dynamic>(_boxName);
    }
    return Hive.box<dynamic>(_boxName);
  }

  Future<SunnahProgress> getProgress() async {
    final box = await _getBox();
    final raw = box.get(_key);
    if (raw is! Map) {
      return SunnahProgress.empty();
    }

    return SunnahProgress(
      totalPoints: (raw['totalPoints'] as int?) ?? 0,
      currentStreak: (raw['currentStreak'] as int?) ?? 0,
      longestStreak: (raw['longestStreak'] as int?) ?? 0,
      totalPracticeActions: (raw['totalPracticeActions'] as int?) ?? 0,
      lastPracticeDateKey: raw['lastPracticeDateKey'] as String?,
      practiceCountsBySunnah: _stringIntMap(raw['practiceCountsBySunnah']),
      lastPracticedDayBySunnah:
          _stringStringMap(raw['lastPracticedDayBySunnah']),
    );
  }

  Future<SunnahProgress> markPracticed(
    String sunnahId, {
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    final current = await getProgress();
    final alreadyPracticedToday = current.lastPracticedDayBySunnah[sunnahId] == todayKey;
    if (alreadyPracticedToday) {
      return current;
    }

    final counts = Map<String, int>.from(current.practiceCountsBySunnah);
    final lastBySunnah = Map<String, String>.from(current.lastPracticedDayBySunnah);

    final newCount = (counts[sunnahId] ?? 0) + 1;
    counts[sunnahId] = newCount;
    lastBySunnah[sunnahId] = todayKey;

    var nextStreak = current.currentStreak;
    if (current.lastPracticeDateKey == null) {
      nextStreak = 1;
    } else if (current.lastPracticeDateKey == todayKey) {
      nextStreak = current.currentStreak;
    } else if (current.lastPracticeDateKey == yesterdayKey) {
      nextStreak = current.currentStreak + 1;
    } else {
      nextStreak = 1;
    }

    final bonus = newCount == 1 ? 5 : 0;
    final pointsGained = 10 + bonus;

    final updated = current.copyWith(
      totalPoints: current.totalPoints + pointsGained,
      currentStreak: nextStreak,
      longestStreak:
          nextStreak > current.longestStreak ? nextStreak : current.longestStreak,
      totalPracticeActions: current.totalPracticeActions + 1,
      lastPracticeDateKey: todayKey,
      practiceCountsBySunnah: counts,
      lastPracticedDayBySunnah: lastBySunnah,
    );

    await _save(updated);
    return updated;
  }

  Future<void> _save(SunnahProgress progress) async {
    final box = await _getBox();
    await box.put(_key, <String, dynamic>{
      'totalPoints': progress.totalPoints,
      'currentStreak': progress.currentStreak,
      'longestStreak': progress.longestStreak,
      'totalPracticeActions': progress.totalPracticeActions,
      'lastPracticeDateKey': progress.lastPracticeDateKey,
      'practiceCountsBySunnah': progress.practiceCountsBySunnah,
      'lastPracticedDayBySunnah': progress.lastPracticedDayBySunnah,
    });
  }

  Map<String, int> _stringIntMap(dynamic raw) {
    if (raw is! Map) return <String, int>{};
    final out = <String, int>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString();
      final value = entry.value;
      if (key == null || value is! int) continue;
      out[key] = value;
    }
    return out;
  }

  Map<String, String> _stringStringMap(dynamic raw) {
    if (raw is! Map) return <String, String>{};
    final out = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString();
      final value = entry.value;
      if (key == null || value == null) continue;
      out[key] = value.toString();
    }
    return out;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

