import 'package:hive_flutter/hive_flutter.dart';
import '../../models/quran_progress.dart';

class QuranProgressRepository {
  static const String _boxName = 'quran_progress';
  static const String _key = 'progress';

  Future<Box<dynamic>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox<dynamic>(_boxName);
    }
    return Hive.box<dynamic>(_boxName);
  }

  Future<QuranProgress> getProgress() async {
    final box = await _getBox();
    final raw = box.get(_key);
    if (raw is! QuranProgress) {
      return QuranProgress.empty();
    }
    return raw;
  }

  Future<QuranProgress> markVersesRead(int count, {DateTime? at}) async {
    if (count <= 0) return await getProgress();

    final now = at ?? DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    final current = await getProgress();

    final versesByDay = Map<String, int>.from(current.versesReadByDay);
    versesByDay[todayKey] = (versesByDay[todayKey] ?? 0) + count;

    var nextStreak = current.currentStreak;
    var daysRead = current.daysRead;

    // First time reading today
    if (current.lastReadDateKey != todayKey) {
      daysRead++;
      
      if (current.lastReadDateKey == null) {
        nextStreak = 1;
      } else if (current.lastReadDateKey == yesterdayKey) {
        nextStreak = current.currentStreak + 1;
      } else {
        nextStreak = 1;
      }
    }

    final updated = current.copyWith(
      totalVersesRead: current.totalVersesRead + count,
      currentStreak: nextStreak,
      longestStreak: nextStreak > current.longestStreak ? nextStreak : current.longestStreak,
      daysRead: daysRead,
      versesReadByDay: versesByDay,
      lastReadDateKey: todayKey,
    );

    await _save(updated);
    return updated;
  }

  Future<void> _save(QuranProgress progress) async {
    final box = await _getBox();
    await box.put(_key, progress);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
