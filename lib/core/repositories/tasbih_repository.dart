import 'package:hive_flutter/hive_flutter.dart';

import '../../models/tasbih.dart';

class TasbihRepository {
  static const String _boxName = 'tasbihBox';

  Future<Box<Tasbih>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Tasbih>(_boxName);
    }
    return Hive.box<Tasbih>(_boxName);
  }

  Future<void> init() async {
    await _getBox();
  }

  Future<List<Tasbih>> getAllTasbihs() async {
    final box = await _getBox();
    final defaults = _defaultTasbihs();

    // Backfill missing defaults for existing users and initialize for first-time users.
    for (final preset in defaults) {
      if (!box.containsKey(preset.id)) {
        await box.put(preset.id, preset);
      }
    }

    // Return in stable order: defaults first, then custom entries.
    final values = box.values.toList();
    final defaultIndex = <String, int>{
      for (int i = 0; i < defaults.length; i++) defaults[i].id: i,
    };

    values.sort((a, b) {
      final ai = defaultIndex[a.id];
      final bi = defaultIndex[b.id];
      if (ai != null && bi != null) return ai.compareTo(bi);
      if (ai != null) return -1;
      if (bi != null) return 1;
      return a.name.compareTo(b.name);
    });

    return values;
  }

  List<Tasbih> _defaultTasbihs() {
    final now = DateTime.now();

    return [
      Tasbih(
        id: 'morning_azkar',
        name: 'Morning Azkar',
        targetCount: 100,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'evening_azkar',
        name: 'Evening Azkar',
        targetCount: 100,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'before_sleep_azkar',
        name: 'Before Sleep Azkar',
        targetCount: 100,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'subhanallah',
        name: 'SubhanAllah',
        targetCount: 33,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'alhamdulillah',
        name: 'Alhamdulillah',
        targetCount: 33,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'allahuakbar',
        name: 'Allahu Akbar',
        targetCount: 34,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'astaghfirullah',
        name: 'Astaghfirullah',
        targetCount: 100,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'la_ilaha_illallah',
        name: 'La ilaha illallah',
        targetCount: 100,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'salawat',
        name: 'Salawat',
        targetCount: 100,
        lastUpdated: now,
      ),
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
