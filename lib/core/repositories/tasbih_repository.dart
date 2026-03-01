import 'package:hive_flutter/hive_flutter.dart';

import '../../models/tasbih.dart';
import '../../models/tasbih_flow.dart';

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
        id: 'allahumma_antassalam',
        name: 'Allahumma Antas-Salam',
        targetCount: 1,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'ayatul_kursi',
        name: 'Ayatul Kursi',
        targetCount: 1,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'la_ilaha_illallah',
        name: 'La ilaha illallah',
        targetCount: 100,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'tasbih_completion',
        name: 'Tasbih Completion',
        targetCount: 1,
        lastUpdated: now,
      ),
      Tasbih(
        id: 'muawwidhat',
        name: 'Al-Mu\'awwidhat',
        targetCount: 1,
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

  // =========================================================================
  // MULTI-PHASE FLOWS
  // =========================================================================

  /// Lookup a predefined multi-phase flow by its ID.
  /// Returns `null` for unknown flow IDs.
  TasbihFlow? getFlow(String flowId) {
    return _predefinedFlows[flowId];
  }

  /// All available flow IDs.
  List<String> get availableFlowIds => _predefinedFlows.keys.toList();

  static final Map<String, TasbihFlow> _predefinedFlows = {
    'fatimah': const TasbihFlow(
      id: 'fatimah',
      name: 'Tasbih of Fatimah (RA)',
      phases: [
        TasbihFlowPhase(
          tasbihId: 'subhanallah',
          label: 'SubhanAllah',
          target: 33,
          arabic: 'سُبْحَانَ اللَّهِ',
          transliteration: 'SubhanAllah',
          translation: 'Glory be to Allah',
        ),
        TasbihFlowPhase(
          tasbihId: 'alhamdulillah',
          label: 'Alhamdulillah',
          target: 33,
          arabic: 'الْحَمْدُ لِلَّهِ',
          transliteration: 'Alhamdulillah',
          translation: 'Praise be to Allah',
        ),
        TasbihFlowPhase(
          tasbihId: 'allahuakbar',
          label: 'Allahu Akbar',
          target: 34,
          arabic: 'اللَّهُ أَكْبَرُ',
          transliteration: 'Allahu Akbar',
          translation: 'Allah is the Greatest',
        ),
      ],
    ),
    'after_prayer': const TasbihFlow(
      id: 'after_prayer',
      name: 'After-Prayer Dhikr',
      phases: [
        TasbihFlowPhase(
          tasbihId: 'astaghfirullah',
          label: 'Istighfar',
          target: 3,
          arabic: 'أَسْتَغْفِرُ اللَّهَ',
          translation: 'I seek the forgiveness of Allah',
        ),
        TasbihFlowPhase(
          tasbihId: 'allahumma_antassalam',
          label: 'Allahumma Antas-Salam',
          target: 1,
          arabic: 'اللَّهُمَّ أَنْتَ السَّلَامُ، وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
          transliteration: 'Allahumma Antas-Salam wa minkas-salam, tabarakta ya Dhal-Jalali wal-Ikram',
          translation: 'O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of majesty and honor',
        ),
        TasbihFlowPhase(
          tasbihId: 'ayatul_kursi',
          label: 'Ayatul Kursi',
          target: 1,
          arabic: 'اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ...',
          translation: 'Allah! There is no deity except Him, the Ever-Living, the Sustainer of [all] existence...',
          virtue: 'There is nothing standing between a reciter of this and entering Paradise except death.',
        ),
        TasbihFlowPhase(
          tasbihId: 'subhanallah',
          label: 'SubhanAllah',
          target: 33,
          arabic: 'سُبْحَانَ اللَّهِ',
          transliteration: 'SubhanAllah',
          translation: 'Glory be to Allah',
        ),
        TasbihFlowPhase(
          tasbihId: 'alhamdulillah',
          label: 'Alhamdulillah',
          target: 33,
          arabic: 'الْحَمْدُ لِلَّهِ',
          transliteration: 'Alhamdulillah',
          translation: 'Praise be to Allah',
        ),
        TasbihFlowPhase(
          tasbihId: 'allahuakbar',
          label: 'Allahu Akbar',
          target: 33,
          arabic: 'اللَّهُ أَكْبَرُ',
          transliteration: 'Allahu Akbar',
          translation: 'Allah is the Greatest',
        ),
        TasbihFlowPhase(
          tasbihId: 'tasbih_completion',
          label: 'Tahlil',
          target: 1,
          arabic: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
          transliteration: 'La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu wa Huwa \'ala kulli shay\'in Qadir',
          translation: 'None has the right to be worshipped except Allah, alone, without partner...',
          virtue: 'Said to complete the 100th remembrance after the 33x Tasbih, forgiving sins even if they are like the foam of the sea.',
        ),
        TasbihFlowPhase(
          tasbihId: 'muawwidhat',
          label: 'Al-Mu\'awwidhat',
          target: 1,
          arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ... \nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ... \nقُلْ أَعُوذُ بِرَبِّ النَّاسِ...',
          translation: 'Recitation of Surah Al-Ikhlas, Al-Falaq, and An-Nas',
        ),
      ],
    ),
    'before_sleep': const TasbihFlow(
      id: 'before_sleep',
      name: 'Before Sleep Azkar',
      phases: [
        TasbihFlowPhase(
          tasbihId: 'subhanallah',
          label: 'SubhanAllah',
          target: 33,
          arabic: 'سُبْحَانَ اللَّهِ',
          transliteration: 'SubhanAllah',
          translation: 'Glory be to Allah',
        ),
        TasbihFlowPhase(
          tasbihId: 'alhamdulillah',
          label: 'Alhamdulillah',
          target: 33,
          arabic: 'الْحَمْدُ لِلَّهِ',
          transliteration: 'Alhamdulillah',
          translation: 'Praise be to Allah',
        ),
        TasbihFlowPhase(
          tasbihId: 'allahuakbar',
          label: 'Allahu Akbar',
          target: 34,
          arabic: 'اللَّهُ أَكْبَرُ',
          transliteration: 'Allahu Akbar',
          translation: 'Allah is the Greatest',
        ),
      ],
    ),
  };
}
