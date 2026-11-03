import 'package:hive_flutter/hive_flutter.dart';

import '../../models/tasbih.dart';
import '../dhikr/dhikr_catalog.dart';

class TasbihRepository {
  static const String _boxName = 'tasbihBox';
  static const String _sessionBoxName = 'dhikr_sessions';

  static const Map<String, (String, int)> _builtIns = {
    'subhanallah': ('SubhanAllah', 33),
    'alhamdulillah': ('Alhamdulillah', 33),
    'allahuakbar': ('Allahu Akbar', 34),
    'astaghfirullah': ('Astaghfirullah', 100),
    'la_ilaha_illallah': ('La ilaha illallah', 100),
    'salawat': ('Salawat', 100),
    'subhanallahi_wa_bihamdihi': ('SubhanAllahi wa bihamdihi', 100),
    'subhanallahil_azeem': ("SubhanAllahil 'Azeem", 33),
    'la_hawla': ('La hawla wa la quwwata', 33),
    'hasbunallah': ('Hasbunallah', 33),
    'dua_yunus': ('Dua of Yunus', 33),
    'sayyid_istighfar': ('Sayyid al-Istighfar', 1),
    'leaving_home': ('Leaving home', 1),
    'bismillah': ('Bismillah', 1),
  };

  /// Counters an earlier build made from a Sunnah in the practice, before
  /// these became built-ins. Their counts move across and they're removed.
  static const Map<String, String> _foldedIntoBuiltIns = {
    'sunnah_dhikr_azkar_say_sayyid_al_istighfar_morning_and_evening': 'sayyid_istighfar',
    'sunnah_dhikr_azkar_say_la_hawla_wa_la_quwwata_illa_billah': 'la_hawla',
  };

  Future<Box<Tasbih>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Tasbih>(_boxName);
    }
    return Hive.box<Tasbih>(_boxName);
  }

  Future<void> init() async {
    await _getBox();
    if (!Hive.isBoxOpen(_sessionBoxName)) {
      await Hive.openBox<dynamic>(_sessionBoxName);
    }
  }

  /// Every stored counter, including retired ones (their totals still count
  /// towards lifetime dhikr). Built-ins are backfilled if missing.
  Future<List<Tasbih>> getAllTasbihs() async {
    final box = await _getBox();
    final now = DateTime.now();
    for (final entry in _foldedIntoBuiltIns.entries) {
      final old = box.get(entry.key);
      if (old == null) continue;
      final current = box.get(entry.value);
      final (name, target) = _builtIns[entry.value]!;
      await box.put(
        entry.value,
        current == null
            ? old.copyWith(id: entry.value, name: name, targetCount: target, currentCount: 0, completedRounds: 0)
            : current.copyWith(
                totalCount: current.totalCount + old.totalCount,
                dayCount: current.todayCount(now: now) + old.todayCount(now: now),
                todayKey: Tasbih.dateKey(now),
              ),
      );
      await box.delete(entry.key);
    }
    for (final entry in _builtIns.entries) {
      if (!box.containsKey(entry.key)) {
        await box.put(
          entry.key,
          Tasbih(id: entry.key, name: entry.value.$1, targetCount: entry.value.$2, lastUpdated: now),
        );
      }
    }
    return box.values.toList();
  }

  /// The counters the hub lists: built-ins in catalog order, then the user's
  /// own in the order they were added. Retired session steps and the
  /// placeholder "Dhikr" entries the old screen saved are left out.
  static List<Tasbih> visibleCounters(List<Tasbih> all) {
    final byId = {for (final t in all) t.id: t};
    final custom = all
        .where((t) =>
            !DhikrCatalog.isBuiltIn(t.id) &&
            !DhikrCatalog.retiredCounterIds.contains(t.id) &&
            t.name != 'Dhikr')
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return [
      for (final id in DhikrCatalog.builtInCounterIds)
        if (byId[id] != null) byId[id]!,
      ...custom,
    ];
  }

  Future<void> saveTasbih(Tasbih tasbih) async {
    final box = await _getBox();
    await box.put(tasbih.id, tasbih);
  }

  Future<void> deleteTasbih(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}

/// Where the user is in each guided session today. Stored as a plain map so
/// no adapter is needed:
/// `{sessionId: {'day': 'yyyy-mm-dd', 'at': millis, 'step': int, 'count': int, 'done': bool}}`.
/// A position resumes only on the same day and within [_resumeWindow], so an
/// after-prayer session left at Dhuhr doesn't reappear half-done at Asr.
class DhikrSessionStore {
  static const String _boxName = 'dhikr_sessions';
  static const Duration _resumeWindow = Duration(hours: 2);

  Box<dynamic>? get _box => Hive.isBoxOpen(_boxName) ? Hive.box<dynamic>(_boxName) : null;

  Map? _today(String sessionId, DateTime now) {
    final raw = _box?.get(sessionId);
    if (raw is! Map || raw['day'] != Tasbih.dateKey(now)) return null;
    return raw;
  }

  bool isDoneToday(String sessionId, {DateTime? now}) =>
      _today(sessionId, now ?? DateTime.now())?['done'] == true;

  /// Today's unfinished position, or null if not started (or finished).
  (int step, int count)? resumePoint(String sessionId, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final raw = _today(sessionId, at);
    if (raw == null) return null;
    final savedAt = raw['at'] as int?;
    if (savedAt == null || at.millisecondsSinceEpoch - savedAt > _resumeWindow.inMilliseconds) return null;
    final step = raw['step'] as int? ?? 0;
    final count = raw['count'] as int? ?? 0;
    if (step == 0 && count == 0) return null;
    return (step, count);
  }

  /// [done] overrides today's completion flag; by default it's kept.
  Future<void> savePosition(String sessionId, int step, int count, {DateTime? now, bool? done}) async {
    final at = now ?? DateTime.now();
    final wasDone = done ?? isDoneToday(sessionId, now: at);
    await _box?.put(sessionId, {
      'day': Tasbih.dateKey(at),
      'at': at.millisecondsSinceEpoch,
      'step': step,
      'count': count,
      'done': wasDone,
    });
  }

  /// Records today's completion and clears the position, so the next start
  /// begins at the first step.
  Future<void> markDone(String sessionId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    await _box?.put(sessionId, {
      'day': Tasbih.dateKey(at),
      'at': at.millisecondsSinceEpoch,
      'step': 0,
      'count': 0,
      'done': true,
    });
  }
}
