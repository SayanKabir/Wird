import 'quran_passages.dart';

/// One step of a guided session: a dhikr said [count] times before moving on.
class SessionStep {
  final String label;
  final int count;
  final String arabic;
  final String? transliteration;
  final String? translation;
  final String? virtue;
  final String? reference;

  /// Quranic text, shown in the Uthmani Quran font rather than plain Amiri.
  final bool quranic;

  /// The counter this step's taps also add to (today and all-time), so the
  /// SubhanAllah said after prayer shows up under SubhanAllah too. It never
  /// touches that counter's current round.
  final String? counterId;

  const SessionStep({
    required this.label,
    required this.count,
    required this.arabic,
    this.transliteration,
    this.translation,
    this.virtue,
    this.reference,
    this.quranic = false,
    this.counterId,
  });

  SessionStep.quran(
    QuranPassage passage, {
    required this.label,
    required this.count,
    this.virtue,
    this.counterId,
  })  : arabic = passage.arabic,
        transliteration = passage.transliteration,
        translation = passage.translation,
        reference = passage.reference,
        quranic = true;
}

/// A guided sequence of dhikr, such as the morning azkar.
class DhikrSession {
  final String id;
  final String name;
  final List<SessionStep> steps;

  const DhikrSession({required this.id, required this.name, required this.steps});

  int get totalCount => steps.fold(0, (sum, s) => sum + s.count);
}

/// The words behind a built-in counter.
class CounterText {
  final String arabic;
  final String transliteration;
  final String translation;
  final String? virtue;

  const CounterText({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.virtue,
  });
}

/// Everything the dhikr section knows how to recite. Sessions and the text
/// for built-in counters live here, in one place, so the screens stay data
/// driven.
class DhikrCatalog {
  DhikrCatalog._();

  // ─────────────────── Counters ───────────────────

  /// Built-in counters shown in the hub, in order. Their ids match the Hive
  /// keys the old Tasbih used, so existing totals carry over.
  static const List<String> builtInCounterIds = [
    'subhanallah',
    'alhamdulillah',
    'allahuakbar',
    'astaghfirullah',
    'la_ilaha_illallah',
    'salawat',
  ];

  /// Ids the old Tasbih stored that are now session steps, not counters.
  /// They stay in Hive so their totals still count towards lifetime dhikr,
  /// but the hub no longer lists them.
  static const Set<String> retiredCounterIds = {
    'morning_azkar',
    'evening_azkar',
    'before_sleep_azkar',
    'allahumma_antassalam',
    'ayatul_kursi',
    'tasbih_completion',
    'muawwidhat',
  };

  static bool isBuiltIn(String id) => builtInCounterIds.contains(id);

  static const Map<String, CounterText> counterText = {
    'subhanallah': _subhanallah,
    'alhamdulillah': _alhamdulillah,
    'allahuakbar': _allahuakbar,
    'astaghfirullah': CounterText(
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      transliteration: 'Astaghfirullah',
      translation: 'I seek forgiveness from Allah',
      virtue: 'The Prophet ﷺ sought forgiveness more than seventy times a day. (Bukhari 6307)',
    ),
    'la_ilaha_illallah': CounterText(
      arabic: 'لَا إِلَـٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
      transliteration: 'La ilaha illAllahu wahdahu la sharika lah',
      translation: 'There is no god but Allah alone, with no partner.',
      virtue: 'Said 100 times: the reward of freeing ten slaves and protection from Shaytan. (Bukhari 3293)',
    ),
    'salawat': CounterText(
      arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
      transliteration: "Allahumma salli 'ala Muhammad wa 'ala ali Muhammad",
      translation: 'O Allah, send blessings on Muhammad and on the family of Muhammad.',
      virtue: 'Whoever sends salawat once, Allah sends blessings upon him ten times. (Muslim 408)',
    ),
  };

  static const _subhanallah = CounterText(
    arabic: 'سُبْحَانَ اللَّهِ',
    transliteration: 'SubhanAllah',
    translation: 'Glory be to Allah',
  );
  static const _alhamdulillah = CounterText(
    arabic: 'الْحَمْدُ لِلَّهِ',
    transliteration: 'Alhamdulillah',
    translation: 'All praise is due to Allah',
  );
  static const _allahuakbar = CounterText(
    arabic: 'اللَّهُ أَكْبَرُ',
    transliteration: 'Allahu Akbar',
    translation: 'Allah is the Greatest',
  );

  // ─────────────────── Sessions ───────────────────

  static DhikrSession? session(String id) {
    for (final s in sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Sessions in hub order.
  static final List<DhikrSession> sessions = [
    DhikrSession(id: 'morning', name: 'Morning azkar', steps: _protectionSteps(morning: true)),
    DhikrSession(id: 'evening', name: 'Evening azkar', steps: _protectionSteps(morning: false)),
    DhikrSession(id: 'after_prayer', name: 'After prayer', steps: _afterPrayer),
    DhikrSession(id: 'before_sleep', name: 'Before sleep', steps: _beforeSleep),
    DhikrSession(id: 'fatimah', name: 'Tasbih of Fatimah', steps: _fatimah),
  ];

  /// Which session a Sunnah's tasbih link should open, if any.
  static String? sessionForSunnah({required String? tasbihId, required String title}) {
    final t = title.toLowerCase();
    if (t.contains('fatimah')) return 'fatimah';
    switch (tasbihId) {
      case 'morning_azkar':
        return 'morning';
      case 'evening_azkar':
        return 'evening';
      case 'before_sleep_azkar':
        return 'before_sleep';
    }
    return null;
  }

  static const String _sayyidArabic =
      'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ';
  static const String _sayyidTranslit =
      "Allahumma anta Rabbi, la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata'tu, a'udhu bika min sharri ma sana'tu, abu'u laka bini'matika 'alayya, wa abu'u laka bidhanbi faghfir li, fa innahu la yaghfirudh-dhunuba illa anta";
  static const String _sayyidTranslation =
      'O Allah, You are my Lord; none has the right to be worshipped but You. You created me and I am Your servant, and I keep Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You.';

  static List<SessionStep> _protectionSteps({required bool morning}) => [
        SessionStep.quran(
          QuranPassages.ayatulKursi,
          label: 'Ayat al-Kursi',
          count: 1,
          virtue: morning
              ? 'Whoever says it in the morning is protected from the jinn until evening. (Nasa\'i)'
              : 'Whoever says it in the evening is protected from the jinn until morning. (Nasa\'i)',
        ),
        SessionStep.quran(
          QuranPassages.ikhlas,
          label: 'Al-Ikhlas',
          count: 3,
          virtue: 'Recited three times morning and evening, the three Quls suffice you against everything. (Abu Dawud 5082)',
        ),
        SessionStep.quran(QuranPassages.falaq, label: 'Al-Falaq', count: 3),
        SessionStep.quran(QuranPassages.nas, label: 'An-Nas', count: 3),
        SessionStep(
          label: 'Sayyid al-Istighfar',
          count: 1,
          arabic: _sayyidArabic,
          transliteration: _sayyidTranslit,
          translation: _sayyidTranslation,
          virtue: morning
              ? 'Whoever says it with certainty during the day and dies before evening is of the people of Paradise.'
              : 'Whoever says it with certainty at night and dies before morning is of the people of Paradise.',
          reference: 'Bukhari 6306',
        ),
      ];

  static final List<SessionStep> _afterPrayer = [
    const SessionStep(
      label: 'Istighfar',
      count: 3,
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      transliteration: 'Astaghfirullah',
      translation: 'I seek the forgiveness of Allah',
      reference: 'Muslim 591',
      counterId: 'astaghfirullah',
    ),
    const SessionStep(
      label: 'Allahumma Antas-Salam',
      count: 1,
      arabic: 'اللَّهُمَّ أَنْتَ السَّلَامُ، وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      transliteration: 'Allahumma Antas-Salam wa minkas-salam, tabarakta ya Dhal-Jalali wal-Ikram',
      translation: 'O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of majesty and honour.',
      reference: 'Muslim 591',
    ),
    const SessionStep(
      label: 'Tahlil',
      count: 1,
      arabic:
          'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
      transliteration:
          "La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadir. Allahumma la mani'a lima a'tayta, wa la mu'tiya lima mana'ta, wa la yanfa'u dhal-jaddi minkal-jadd.",
      translation:
          'None has the right to be worshipped except Allah, alone, without partner. To Him belongs all sovereignty and praise, and He is over all things capable. O Allah, none can withhold what You give, none can give what You withhold, and no one\'s wealth avails him against You.',
      reference: 'Bukhari 844, Muslim 593',
    ),
    SessionStep(
      label: 'SubhanAllah',
      count: 33,
      arabic: _subhanallah.arabic,
      transliteration: _subhanallah.transliteration,
      translation: _subhanallah.translation,
      reference: 'Muslim 597',
      counterId: 'subhanallah',
    ),
    SessionStep(
      label: 'Alhamdulillah',
      count: 33,
      arabic: _alhamdulillah.arabic,
      transliteration: _alhamdulillah.transliteration,
      translation: _alhamdulillah.translation,
      reference: 'Muslim 597',
      counterId: 'alhamdulillah',
    ),
    SessionStep(
      label: 'Allahu Akbar',
      count: 33,
      arabic: _allahuakbar.arabic,
      transliteration: _allahuakbar.transliteration,
      translation: _allahuakbar.translation,
      reference: 'Muslim 597',
      counterId: 'allahuakbar',
    ),
    const SessionStep(
      label: 'Completing the hundred',
      count: 1,
      arabic: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      transliteration: "La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu wa Huwa 'ala kulli shay'in Qadir",
      translation: 'None has the right to be worshipped except Allah, alone, without partner. To Him belongs all sovereignty and praise, and He is over all things capable.',
      virtue: 'Whoever says this after the 33s, his sins are forgiven even if they are like the foam of the sea.',
      reference: 'Muslim 597',
    ),
    SessionStep.quran(
      QuranPassages.ayatulKursi,
      label: 'Ayat al-Kursi',
      count: 1,
      virtue: 'Whoever recites it after every prescribed prayer, nothing stands between him and Paradise but death. (Nasa\'i)',
    ),
    SessionStep.quran(QuranPassages.ikhlas, label: 'Al-Ikhlas', count: 1),
    SessionStep.quran(QuranPassages.falaq, label: 'Al-Falaq', count: 1),
    SessionStep.quran(QuranPassages.nas, label: 'An-Nas', count: 1),
  ];

  static final List<SessionStep> _fatimah = [
    SessionStep(
      label: 'SubhanAllah',
      count: 33,
      arabic: _subhanallah.arabic,
      transliteration: _subhanallah.transliteration,
      translation: _subhanallah.translation,
      reference: 'Bukhari 3113',
      counterId: 'subhanallah',
    ),
    SessionStep(
      label: 'Alhamdulillah',
      count: 33,
      arabic: _alhamdulillah.arabic,
      transliteration: _alhamdulillah.transliteration,
      translation: _alhamdulillah.translation,
      reference: 'Bukhari 3113',
      counterId: 'alhamdulillah',
    ),
    SessionStep(
      label: 'Allahu Akbar',
      count: 34,
      arabic: _allahuakbar.arabic,
      transliteration: _allahuakbar.transliteration,
      translation: _allahuakbar.translation,
      virtue: 'Taught to Fatimah as better for her than a servant.',
      reference: 'Bukhari 3113',
      counterId: 'allahuakbar',
    ),
  ];

  static final List<SessionStep> _beforeSleep = [
    SessionStep.quran(
      QuranPassages.ayatulKursi,
      label: 'Ayat al-Kursi',
      count: 1,
      virtue: 'A guardian from Allah stays with you and no devil comes near until morning. (Bukhari 2311)',
    ),
    ..._fatimah,
    const SessionStep(
      label: 'Sleep dua',
      count: 1,
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      transliteration: 'Bismika Allahumma amutu wa ahya',
      translation: 'In Your name, O Allah, I die and I live.',
      reference: 'Bukhari 6324',
    ),
  ];
}
