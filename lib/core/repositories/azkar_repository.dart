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

    // --- AFTER PRAYER AZKAR ---
    const Azkar(
      id: 'after_prayer_istighfar',
      category: AzkarCategory.afterPrayer,
      order: 1,
      arabic: 'أَسْتَغْفِرُ اللَّهَ\n\nاللَّهُمَّ أَنْتَ السَّلَامُ، وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      transliteration: "Astaghfirullah (3x)\n\nAllahumma Antas-Salam wa minkas-salam, tabarakta ya Dhal-Jalali wal-Ikram.",
      translation: "I seek the forgiveness of Allah.\n\nO Allah, You are Peace and from You comes peace. Blessed are You, O Owner of majesty and honor.",
      repetitions: 1, // Astaghfirullah is recited 3 times, but it's one block here. We'll set reps to 1 to simplify logic, or 1 for the whole block.
      virtue: "The Prophet ﷺ would recite this immediately after finishing every obligatory prayer.",
      reference: {'source': 'Muslim 591'},
    ),
    const Azkar(
      id: 'after_prayer_tahlil',
      category: AzkarCategory.afterPrayer,
      order: 2,
      arabic: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
      transliteration: "La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadir. Allahumma la mani'a lima a'tayta, wa la mu'tiya lima mana'ta, wa la yanfa'u dhal-jaddi minkal-jadd.",
      translation: "None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and praise and He is over all things omnipotent. O Allah, none can prevent what You have willed to bestow and none can bestow what You have willed to prevent, and no wealth or majesty can benefit anyone, as from You is all wealth and majesty.",
      repetitions: 1,
      virtue: "A profound declaration of Tawheed and submission to Allah's will.",
      reference: {'source': 'Bukhari 844', 'hadith': 'Muslim 593'},
    ),
    const Azkar(
      id: 'after_prayer_tasbih',
      category: AzkarCategory.afterPrayer,
      order: 3,
      arabic: 'سُبْحَانَ اللَّهِ\nالْحَمْدُ لِلَّهِ\nاللَّهُ أَكْبَرُ',
      transliteration: "Subhanallah (33x)\nAlhamdulillah (33x)\nAllahu Akbar (33x)",
      translation: "Glory is to Allah\nPraise is to Allah\nAllah is the Most Great",
      repetitions: 33, // This acts as a single counter for 33 times for all, or 33 each. We'll use 33 for the UI to tap through.
      virtue: "Whoever recites Subhanallah 33x, Alhamdulillah 33x, and Allahu Akbar 33x after every prescribed prayer, and says La ilaha illallah... to complete 100, his sins will be forgiven even if they are like the foam of the sea.",
      reference: {'source': 'Muslim 597'},
    ),
    const Azkar(
      id: 'after_prayer_tasbih_completion',
      category: AzkarCategory.afterPrayer,
      order: 4,
      arabic: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      transliteration: "La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadir.",
      translation: "None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and praise and He is over all things omnipotent.",
      repetitions: 1,
      virtue: "Said to complete the 100th remembrance after the 33x Tasbih.",
      reference: {'source': 'Muslim 597'},
    ),
    const Azkar(
      id: 'after_prayer_ayat_alkursi',
      category: AzkarCategory.afterPrayer,
      order: 5,
      arabic: 'اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      transliteration: "Allahu la ilaha illa Huwa, Al-Haiyul-Qaiyum. La ta'khudhuhu sinatun wa la nawm, lahu ma fis-samawati wa ma fil-'ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnihi. Ya'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bi shai'in min 'ilmihi illa bi ma sha'a. Wasi'a kursiyuhus-samawati wal ard, wa la ya'uduhu hifdhuhuma wa Huwal 'Aliyul-Adheem.",
      translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is [presently] before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
      repetitions: 1,
      virtue: "Whoever recites Ayatul Kursi after every prescribed prayer, there is nothing standing between him and entering Paradise except death.",
      reference: {'source': 'An-Nasa\'i', 'grade': 'Sahih (Albani)'},
    ),
    const Azkar(
      id: 'after_prayer_muawwidhat',
      category: AzkarCategory.afterPrayer,
      order: 6,
      arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ... \nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ... \nقُلْ أَعُوذُ بِرَبِّ النَّاسِ...',
      transliteration: "Surah Al-Ikhlas, Al-Falaq, An-Nas",
      translation: "Recitation of Surah Al-Ikhlas (112), Al-Falaq (113), and An-Nas (114).",
      repetitions: 1, // Recited once after Dhuhr, Asr, Isha. Thrice after Fajr & Maghrib. We default to 1 here for simplicity in UI.
      virtue: "The Prophet ﷺ ordered me (Uqbah) to recite the Mu'awwidhat (these three Surahs) after every prayer.",
      reference: {'source': 'Abu Dawud 1523', 'grade': 'Sahih'},
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
