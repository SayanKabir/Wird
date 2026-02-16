import '../../models/azkar.dart';

class AzkarRepository {
  // Hardcoded data for Phase 2 - a subset of authentic Azkar
  final List<Azkar> _allAzkar = [
    // --- MORNING AZKAR ---
    const Azkar(
      id: 'morning_ayat_alkursi',
      category: AzkarCategory.morning,
      order: 1,
      arabic: 'اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...',
      transliteration: "Allahu la ilaha illa Huwa, Al-Haiyul-Qaiyum...",
      translation: "Allah! There is no god but He, the Ever Living, the One Who sustains and protects all that exists...",
      repetitions: 1,
      virtue: "Whoever says this when he rises in the morning will be protected from jinn until he retires in the evening.",
      reference: {'source': 'Hisn al-Muslim', 'hadith': 'Nasai, Tabarani'},
    ),
    const Azkar(
      id: 'morning_surah_ikhlas',
      category: AzkarCategory.morning,
      order: 2,
      arabic: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ...',
      transliteration: "Qul Huwallahu Ahad...",
      translation: "Say: He is Allah, the One...",
      repetitions: 3,
      virtue: "Whoever recites these three times in the morning and in the evening, they will suffice him (as a protection) against everything.",
      reference: {'source': 'Hisn al-Muslim', 'hadith': 'Abu Dawud 5082'},
    ),
    const Azkar(
      id: 'morning_surah_falaq',
      category: AzkarCategory.morning,
      order: 3,
      arabic: 'قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ...',
      transliteration: "Qul a'udhu bi-rabbil-falaq...",
      translation: "Say: I seek refuge with (Allah) the Lord of the daybreak...",
      repetitions: 3,
      virtue: "Protection against everything.",
      reference: {'source': 'Hisn al-Muslim', 'hadith': 'Abu Dawud 5082'},
    ),
    const Azkar(
      id: 'morning_surah_nas',
      category: AzkarCategory.morning,
      order: 4,
      arabic: 'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ...',
      transliteration: "Qul a'udhu bi-rabbin-nas...",
      translation: "Say: I seek refuge with (Allah) the Lord of mankind...",
      repetitions: 3,
      virtue: "Protection against everything.",
      reference: {'source': 'Hisn al-Muslim', 'hadith': 'Abu Dawud 5082'},
    ),
    const Azkar(
      id: 'morning_sayyid_istighfar',
      category: AzkarCategory.morning,
      order: 5,
      arabic: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ...',
      transliteration: "Allahumma Anta Rabbi la ilaha illa Anta, Khalaqtani wa ana 'abduka...",
      translation: "O Allah, You are my Lord, none has the right to be worshipped except You, You created me and I am Your servant...",
      repetitions: 1,
      virtue: "If used with certainty in the morning & dies, enters Paradise.",
      reference: {'source': 'Bukhari 6306', 'grade': 'Sahih'},
    ),

    // --- EVENING AZKAR ---
    const Azkar(
      id: 'evening_ayat_alkursi',
      category: AzkarCategory.evening,
      order: 1,
      arabic: 'اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...',
      transliteration: "Allahu la ilaha illa Huwa, Al-Haiyul-Qaiyum...",
      translation: "Allah! There is no god but He, the Ever Living...",
      repetitions: 1,
      virtue: "Protected from jinn until morning.",
      reference: {'source': 'Hisn al-Muslim', 'hadith': 'Nasai'},
    ),
     const Azkar(
      id: 'evening_surah_ikhlas',
      category: AzkarCategory.evening,
      order: 2,
      arabic: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ...',
      transliteration: "Qul Huwallahu Ahad...",
      translation: "Say: He is Allah, the One...",
      repetitions: 3,
      virtue: "Suffice him against everything.",
      reference: {'source': 'Abu Dawud 5082'},
    ),

    // --- BEFORE SLEEP ---
     const Azkar(
      id: 'sleep_subhanallah',
      category: AzkarCategory.beforeSleep,
      order: 1,
      arabic: 'سُبْحَانَ اللَّهِ',
      transliteration: "SubhanAllah",
      translation: "Glory is to Allah",
      repetitions: 33,
      virtue: "Better than a servant.",
      reference: {'source': 'Bukhari 3113'},
    ),
    const Azkar(
      id: 'sleep_alhamdulillah',
      category: AzkarCategory.beforeSleep,
      order: 2,
      arabic: 'الْحَمْدُ لِلَّهِ',
      transliteration: "Alhamdulillah",
      translation: "Praise is to Allah",
      repetitions: 33,
      virtue: "Better than a servant.",
      reference: {'source': 'Bukhari 3113'},
    ),
    const Azkar(
      id: 'sleep_allahuakbar',
      category: AzkarCategory.beforeSleep,
      order: 3,
      arabic: 'اللَّهُ أَكْبَرُ',
      transliteration: "Allahu Akbar",
      translation: "Allah is the Greatest",
      repetitions: 34,
      virtue: "Better than a servant.",
      reference: {'source': 'Bukhari 3113'},
    ),
  ];

  Future<List<AzkarCategory>> getAvailableCategories() async {
    // Return all categories that have at least one Azkar
    final categories = _allAzkar.map((a) => a.category).toSet().toList();
    categories.sort((a, b) => a.index.compareTo(b.index));
    return categories;
  }

  Future<List<Azkar>> getAzkarByCategory(AzkarCategory category) async {
    await Future.delayed(const Duration(milliseconds: 50)); // Sim delay
    final list = _allAzkar.where((a) => a.category == category).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }
}
