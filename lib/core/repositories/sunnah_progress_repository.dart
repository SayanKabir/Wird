import 'package:hive_flutter/hive_flutter.dart';

import '../../models/sunnah_progress.dart';

class SunnahProgressRepository {
  static const String _boxName = 'sunnah_progress';
  static const String _key = 'progress';

  /// How many days of the per-day log to keep. Undo only ever needs today,
  /// and "last kept" needs the most recent earlier day, so a year is plenty.
  static const int _logRetentionDays = 400;

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
      practiceIds: _stringList(raw['practiceIds']),
      practiceLog: _stringListMap(raw['practiceLog']),
      streakBeforeToday: raw['streakBeforeToday'] as int?,
      longestBeforeToday: raw['longestBeforeToday'] as int?,
      lastDateBeforeToday: raw['lastDateBeforeToday'] as String?,
    );
  }

  /// Marks [sunnahId] as done today, or undoes today's mark if it is already
  /// there. Returns the updated progress.
  Future<SunnahProgress> toggleToday(String sunnahId, {DateTime? at}) async {
    final current = await getProgress();
    final now = at ?? DateTime.now();
    final updated = current.isPracticedToday(sunnahId, now: now)
        ? _unmark(current, sunnahId, now)
        : _mark(current, sunnahId, now);
    await _save(updated);
    return updated;
  }

  /// Adds [sunnahId] to the user's practice, or removes it if already there.
  Future<SunnahProgress> togglePractice(String sunnahId) async {
    final current = await getProgress();
    final ids = List<String>.from(current.practiceIds);
    if (!ids.remove(sunnahId)) ids.add(sunnahId);
    final updated = current.copyWith(practiceIds: ids);
    await _save(updated);
    return updated;
  }

  SunnahProgress _mark(SunnahProgress current, String sunnahId, DateTime now) {
    final todayKey = SunnahProgress.dateKey(now);
    final yesterdayKey =
        SunnahProgress.dateKey(now.subtract(const Duration(days: 1)));

    final counts = Map<String, int>.from(current.practiceCountsBySunnah)
      ..update(sunnahId, (c) => c + 1, ifAbsent: () => 1);
    final lastBySunnah =
        Map<String, String>.from(current.lastPracticedDayBySunnah)
          ..[sunnahId] = todayKey;
    final log = _copyLog(current.practiceLog);
    log.putIfAbsent(todayKey, () => <String>[]).add(sunnahId);

    // Today's first tick moves the streak; remember where it stood so undoing
    // every tick of today can put it back.
    if (current.lastPracticeDateKey == todayKey) {
      return current.copyWith(
        totalPracticeActions: current.totalPracticeActions + 1,
        practiceCountsBySunnah: counts,
        lastPracticedDayBySunnah: lastBySunnah,
        practiceLog: log,
      );
    }

    final nextStreak = current.lastPracticeDateKey == yesterdayKey
        ? current.currentStreak + 1
        : 1;
    return current.copyWith(
      currentStreak: nextStreak,
      longestStreak: nextStreak > current.longestStreak
          ? nextStreak
          : current.longestStreak,
      totalPracticeActions: current.totalPracticeActions + 1,
      lastPracticeDateKey: () => todayKey,
      practiceCountsBySunnah: counts,
      lastPracticedDayBySunnah: lastBySunnah,
      practiceLog: log,
      streakBeforeToday: () => current.currentStreak,
      longestBeforeToday: () => current.longestStreak,
      lastDateBeforeToday: () => current.lastPracticeDateKey,
    );
  }

  SunnahProgress _unmark(SunnahProgress current, String sunnahId, DateTime now) {
    final todayKey = SunnahProgress.dateKey(now);
    final yesterdayKey =
        SunnahProgress.dateKey(now.subtract(const Duration(days: 1)));

    final counts = Map<String, int>.from(current.practiceCountsBySunnah);
    final count = (counts[sunnahId] ?? 1) - 1;
    if (count <= 0) {
      counts.remove(sunnahId);
    } else {
      counts[sunnahId] = count;
    }

    final log = _copyLog(current.practiceLog);
    log[todayKey]?.remove(sunnahId);
    if (log[todayKey]?.isEmpty ?? false) log.remove(todayKey);

    // Fall back to the most recent earlier day this sunnah was kept, if the
    // log remembers one.
    final lastBySunnah =
        Map<String, String>.from(current.lastPracticedDayBySunnah)
          ..remove(sunnahId);
    final earlier = log.entries
        .where((e) => e.key.compareTo(todayKey) < 0 && e.value.contains(sunnahId))
        .map((e) => e.key)
        .fold<String?>(null, (best, k) => best == null || k.compareTo(best) > 0 ? k : best);
    if (earlier != null) lastBySunnah[sunnahId] = earlier;

    var updated = current.copyWith(
      totalPracticeActions:
          current.totalPracticeActions > 0 ? current.totalPracticeActions - 1 : 0,
      practiceCountsBySunnah: counts,
      lastPracticedDayBySunnah: lastBySunnah,
      practiceLog: log,
    );

    final anythingLeftToday = lastBySunnah.values.contains(todayKey);
    if (anythingLeftToday || current.lastPracticeDateKey != todayKey) {
      return updated;
    }

    if (current.streakBeforeToday != null) {
      updated = updated.copyWith(
        currentStreak: current.streakBeforeToday,
        longestStreak: current.longestBeforeToday ?? current.longestStreak,
        lastPracticeDateKey: () => current.lastDateBeforeToday,
      );
    } else {
      // Ticked before the undo snapshot existed: best guess is that today
      // added one day on top of a streak ending yesterday.
      final previous = current.currentStreak - 1;
      updated = updated.copyWith(
        currentStreak: previous > 0 ? previous : 0,
        lastPracticeDateKey: () => previous > 0 ? yesterdayKey : null,
      );
    }
    return updated.copyWith(
      streakBeforeToday: () => null,
      longestBeforeToday: () => null,
      lastDateBeforeToday: () => null,
    );
  }

  Future<void> _save(SunnahProgress progress) async {
    final box = await _getBox();
    final cutoff = SunnahProgress.dateKey(
        DateTime.now().subtract(const Duration(days: _logRetentionDays)));
    final log = <String, List<String>>{
      for (final e in progress.practiceLog.entries)
        if (e.key.compareTo(cutoff) >= 0) e.key: e.value,
    };
    await box.put(_key, <String, dynamic>{
      'totalPoints': progress.totalPoints,
      'currentStreak': progress.currentStreak,
      'longestStreak': progress.longestStreak,
      'totalPracticeActions': progress.totalPracticeActions,
      'lastPracticeDateKey': progress.lastPracticeDateKey,
      'practiceCountsBySunnah': progress.practiceCountsBySunnah,
      'lastPracticedDayBySunnah': progress.lastPracticedDayBySunnah,
      'practiceIds': progress.practiceIds,
      'practiceLog': log,
      'streakBeforeToday': progress.streakBeforeToday,
      'longestBeforeToday': progress.longestBeforeToday,
      'lastDateBeforeToday': progress.lastDateBeforeToday,
    });
  }

  Map<String, List<String>> _copyLog(Map<String, List<String>> log) => {
        for (final e in log.entries) e.key: List<String>.from(e.value),
      };

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

  List<String> _stringList(dynamic raw) {
    if (raw is! List) return <String>[];
    return raw.whereType<Object>().map((e) => e.toString()).toList();
  }

  Map<String, List<String>> _stringListMap(dynamic raw) {
    if (raw is! Map) return <String, List<String>>{};
    final out = <String, List<String>>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString();
      if (key == null) continue;
      out[key] = _stringList(entry.value);
    }
    return out;
  }
}
