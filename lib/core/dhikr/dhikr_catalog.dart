import '../../models/sunnah.dart';
import '../../models/tasbih.dart';
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
    'subhanallahi_wa_bihamdihi',
    'subhanallahil_azeem',
    'la_hawla',
    'hasbunallah',
    'dua_yunus',
    // From the starting practice, so it's here from day one.
    'sayyid_istighfar',
    'leaving_home',
    'bismillah',
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

  // ─────────────────── Counters from Sunnahs ───────────────────

  static const String _sunnahPrefix = 'sunnah_';

  /// The counter a Sunnah adds to the hub when it joins the user's practice.
  static String counterIdForSunnah(String sunnahId) => '$_sunnahPrefix$sunnahId';

  /// Dhikr Sunnahs with words of their own and no counter or session yet
  /// (Sayyid al-Istighfar, La hawla wa la quwwata). The rest already point
  /// at a built-in counter or a guided session through their tasbihId.
  static bool sunnahNeedsCounter(Sunnah s) =>
      s.category == 'Dhikr & Azkar' && s.tasbihId == null && (s.arabic ?? '').trim().isNotEmpty;

  /// "Say Sayyid al-Istighfar morning and evening" → "Sayyid al-Istighfar".
  static String counterNameForSunnah(Sunnah s) {
    var name = s.title.replaceFirst(RegExp(r'^Say\s+'), '');
    name = name.replaceFirst(RegExp(r'\s+(morning|evening|after|before|\d+ times|daily).*$', caseSensitive: false), '');
    return name.trim().isEmpty ? s.title : name.trim();
  }

  /// The Sunnah's count if it has one; a short phrase is counted in 33s,
  /// a long supplication said once.
  static int counterTargetForSunnah(Sunnah s) =>
      s.repetitions ?? ((s.arabic ?? '').length <= 60 ? 33 : 1);

  /// Words for a counter that came from a Sunnah, or null for any other id.
  static CounterText? counterTextFromSunnahs(String counterId, Iterable<Sunnah> sunnahs) {
    if (!counterId.startsWith(_sunnahPrefix)) return null;
    final id = counterId.substring(_sunnahPrefix.length);
    for (final s in sunnahs) {
      if (s.id != id) continue;
      return CounterText(
        arabic: s.arabic ?? '',
        transliteration: s.transliteration ?? '',
        translation: s.translation ?? '',
        virtue: s.virtue.isEmpty ? null : s.virtue,
      );
    }
    return null;
  }

  // ─────────────────── Keeping the practice ───────────────────

  /// The counter whose count today keeps [s], or null when a guided session
  /// keeps it instead, or nothing on the dhikr page does.
  static String? counterKeeping(Sunnah s) {
    if (sessionForSunnah(tasbihId: s.tasbihId, title: s.title) != null) return null;
    if (s.tasbihId != null) return retiredCounterIds.contains(s.tasbihId) ? null : s.tasbihId;
    return sunnahNeedsCounter(s) ? counterIdForSunnah(s.id) : null;
  }

  /// Sunnahs among [practiceIds] that [counters] have kept today: their
  /// counter has been said as many times as the Sunnah asks (its own count,
  /// or a full round when it names none). Session steps add to the same
  /// counters, so after-prayer dhikr said in the session counts too.
  static Set<String> keptByCounters({
    required Iterable<Sunnah> sunnahs,
    required Iterable<String> practiceIds,
    required List<Tasbih> counters,
    DateTime? now,
  }) {
    final ids = practiceIds.toSet();
    final byId = {for (final t in counters) t.id: t};
    return {
      for (final s in sunnahs)
        if (ids.contains(s.id))
          if (byId[counterKeeping(s)] case final t?)
            if (t.todayCount(now: now) >= (s.repetitions ?? t.targetCount)) s.id,
    };
  }

  /// Sunnahs a finished [sessionId] keeps: the morning session keeps
  /// "Complete Morning Azkar", and so on.
  static Set<String> keptBySession(String sessionId, Iterable<Sunnah> sunnahs) => {
        for (final s in sunnahs)
          if (sessionForSunnah(tasbihId: s.tasbihId, title: s.title) == sessionId) s.id,
      };

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
    'subhanallahi_wa_bihamdihi': CounterText(
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      transliteration: 'SubhanAllahi wa bihamdihi',
      translation: 'Glory be to Allah, and praise be to Him.',
      virtue: 'Said 100 times a day, sins are forgiven even if they are like the foam of the sea. (Bukhari 6405)',
    ),
    'subhanallahil_azeem': CounterText(
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
      transliteration: "SubhanAllahi wa bihamdihi, SubhanAllahil 'Azeem",
      translation: 'Glory be to Allah, and praise be to Him. Glory be to Allah, the Magnificent.',
      virtue: 'Two words light on the tongue, heavy on the scale, beloved to the Most Merciful. (Bukhari 6406)',
    ),
    'la_hawla': CounterText(
      arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      transliteration: 'La hawla wa la quwwata illa billah',
      translation: 'There is no might nor power except with Allah.',
      virtue: 'A treasure from the treasures of Paradise. (Bukhari 6384)',
    ),
    'hasbunallah': CounterText(
      arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      transliteration: "Hasbunallahu wa ni'mal wakeel",
      translation: 'Allah is enough for us, and He is the best to rely on.',
      virtue: 'Said by Ibrahim when he was thrown into the fire, and by the Prophet ﷺ and his companions. (Quran 3:173, Bukhari 4563)',
    ),
    'dua_yunus': CounterText(
      arabic: 'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      transliteration: 'La ilaha illa anta, subhanaka, inni kuntu minaz-zalimeen',
      translation: 'There is no god but You. Glory be to You. I have been among the wrongdoers.',
      virtue: 'No Muslim calls on his Lord with it for anything but that He answers him. (Quran 21:87, Tirmidhi 3505)',
    ),
    'sayyid_istighfar': CounterText(
      arabic: _sayyidArabic,
      transliteration: _sayyidTranslit,
      translation: _sayyidTranslation,
      virtue: 'Whoever says it in the day with certainty and dies before evening is among the people of Paradise; likewise at night. (Bukhari 6306)',
    ),
    'leaving_home': CounterText(
      arabic: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      transliteration: 'Bismillah, tawakkaltu ala Allah, wa la hawla wa la quwwata illa billah',
      translation: 'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.',
      virtue: 'Whoever says it on leaving home is told: you are guided, defended and protected. (Abu Dawud 5095)',
    ),
    'bismillah': CounterText(
      arabic: 'بِسْمِ اللَّهِ',
      transliteration: 'Bismillah',
      translation: 'In the name of Allah. If you forget at the start: Bismillahi awwalahu wa akhirahu.',
      virtue: 'Mention the name of Allah before eating, and barakah comes into the food. (Bukhari 5376, Abu Dawud 3767)',
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
