import 'package:hive/hive.dart';
import '../../models/sunnah.dart';

/// Unified repository for all Sunnah data including dhikr/azkar entries.
/// Replaces the old SunnahRepository + AzkarRepository with one enriched source.
class SunnahRepository {
  late final List<Sunnah> _sunnahs = _seeds.map((s) => s.toSunnah()).toList(growable: false);
  Box? _prefsBox;
  static const String _boxName = 'sunnah_prefs';
  static const String _keyWeeklyId = 'weekly_sunnah_id';
  static const String _keyWeekStart = 'week_start_timestamp';

  /// Initialize repository and open storage
  Future<void> init() async {
    _prefsBox = await Hive.openBox(_boxName);
  }

  // ───────────────────────────── public API ─────────────────────────────

  Future<List<Sunnah>> getAllSunnahs() async => _sunnahs;

  /// Synchronous access to the sunnah list (already eagerly computed).
  List<Sunnah> getAllSunnahsSync() => _sunnahs;

  Future<Sunnah?> getSunnahById(String id) async {
    try {
      return _sunnahs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Sunnah> getWeeklySunnah() async {
    if (_sunnahs.isEmpty) throw StateError('No Sunnahs available.');
    
    // Calculate start of current week (Monday)
    final now = DateTime.now();
    // Monday = 1, so subtract (weekday - 1)
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    final currentWeekStart = monday.millisecondsSinceEpoch;

    // Check stored week
    final storedWeekStart = _prefsBox?.get(_keyWeekStart) as int?;
    final storedId = _prefsBox?.get(_keyWeeklyId) as String?;

    // If new week or no stored data, pick a new random sunnah
    if (storedWeekStart != currentWeekStart || storedId == null) {
      final newSunnah = _pickRandomSunnah();
      
      await _prefsBox?.put(_keyWeekStart, currentWeekStart);
      await _prefsBox?.put(_keyWeeklyId, newSunnah.id);
      
      return newSunnah;
    }

    // Return stored sunnah, fallback to random if ID not found
    final sunnah = _sunnahs.firstWhere(
      (s) => s.id == storedId,
      orElse: () => _pickRandomSunnah(),
    );
    
    return sunnah;
  }

  /// Advances to the next sunnah for this week (manually shuffled by user).
  /// This persists the change so it stays for the rest of the week.
  Future<Sunnah> skipWeeklySunnah() async {
    final currentId = _prefsBox?.get(_keyWeeklyId) as String?;
    
    // Pick different one
    Sunnah newSunnah;
    do {
      newSunnah = _pickRandomSunnah();
    } while (newSunnah.id == currentId && _sunnahs.length > 1);

    await _prefsBox?.put(_keyWeeklyId, newSunnah.id);
    return newSunnah;
  }

  Sunnah _pickRandomSunnah() {
    return _sunnahs[DateTime.now().microsecondsSinceEpoch % _sunnahs.length];
  }

  // ───────────────────────────── seed data ──────────────────────────────

  static const _seeds = <_S>[
    // ━━━━━━━━━━━━━━━ EATING & DRINKING ━━━━━━━━━━━━━━━
    _S(cat: 'Eating & Drinking', t: 'Say Bismillah before eating', ref: 'Bukhari 5376, Muslim 2017', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "When any of you eats, let him mention the name of Allah." (Bukhari 5376)', vir: 'Starting meals with Bismillah invites barakah into your food.'),
    _S(cat: 'Eating & Drinking', t: 'Eat with the right hand', ref: 'Muslim 2020', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "When any of you eats, let him eat with his right hand." (Muslim 2020)', vir: 'Following the blessed manner of the Prophet ﷺ brings barakah.'),
    _S(cat: 'Eating & Drinking', t: 'Say Alhamdulillah after eating', ref: 'Abu Dawud 3850, Tirmidhi 3456', g: 'Hasan', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Whoever eats food and then says Alhamdulillah, his past sins will be forgiven." (Tirmidhi 3456)', vir: 'Gratitude after eating erases minor sins and invites more provision.'),
    _S(cat: 'Eating & Drinking', t: 'Drink while sitting', ref: 'Muslim 2024', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ forbade drinking while standing. (Muslim 2024)', vir: 'Drinking while sitting is healthier and follows the Prophetic way.'),
    _S(cat: 'Eating & Drinking', t: 'Share food with others', ref: 'Bukhari 2486', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Food for two is enough for three, and food for three is enough for four." (Bukhari 2486)', vir: 'Generosity in sharing food multiplies its barakah.'),
    _S(cat: 'Eating & Drinking', t: 'Eat suhoor (pre-dawn meal)', ref: 'Bukhari 1923, Muslim 1095', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Eat suhoor, for in suhoor there is barakah." (Bukhari 1923)', vir: 'Suhoor provides strength for fasting and is a blessed meal.'),
    _S(cat: 'Eating & Drinking', t: 'Break fast with dates', ref: 'Abu Dawud 2356, Tirmidhi 696', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ would break his fast with fresh dates; if not available, then dried dates; if not, then water. (Abu Dawud 2356)', vir: 'Dates provide natural sugars that quickly restore energy.'),

    // ━━━━━━━━━━━━━━━ PERSONAL HYGIENE ━━━━━━━━━━━━━━━
    _S(cat: 'Personal Hygiene', t: 'Use miswak (tooth stick)', ref: 'Bukhari 887, Muslim 252', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Were it not that I would make it difficult for my ummah, I would have commanded them to use the miswak for every prayer." (Bukhari 887)', vir: 'Pleases Allah and purifies the mouth — a simple, powerful sunnah.'),
    _S(cat: 'Personal Hygiene', t: 'Trim nails regularly', ref: 'Muslim 257', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.weekly, desc: 'Among the practices of the fitrah is trimming nails. (Muslim 257)', vir: 'Part of natural cleanliness (fitrah) enjoined by Islam.'),
    _S(cat: 'Personal Hygiene', t: 'Remove armpit hair', ref: 'Muslim 257', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.monthly, desc: 'Among the practices of the fitrah is plucking armpit hair. (Muslim 257)', vir: 'Following the fitrah maintains bodily cleanliness.'),
    _S(cat: 'Personal Hygiene', t: 'Remove pubic hair (within 40 days)', ref: 'Muslim 257', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.monthly, desc: 'Among the practices of the fitrah. The Prophet ﷺ set a maximum period of 40 days. (Muslim 257)', vir: 'Part of the natural practices of cleanliness.'),
    _S(cat: 'Personal Hygiene', t: 'Ghusl (bath) on Fridays', ref: 'Bukhari 877, Muslim 846', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.weekly, desc: 'The Prophet ﷺ said: "The bath on Friday is obligatory on every adult." (Bukhari 877)', vir: 'Prepares one for the best day of the week.'),
    _S(cat: 'Personal Hygiene', t: 'Apply perfume (for men)', ref: 'Bukhari 5929, Muslim 2252', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ loved good scent and would never refuse perfume. (Bukhari 5929)', vir: 'Good fragrance pleases those around you and is a sunnah.'),
    _S(cat: 'Personal Hygiene', t: 'Trim mustache short', ref: 'Bukhari 5892, Muslim 259', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.monthly, desc: 'The Prophet ﷺ said: "Trim the mustache and leave the beard." (Bukhari 5892)', vir: 'Part of the natural appearance enjoined in hadith.'),
    _S(cat: 'Personal Hygiene', t: 'Say dua entering bathroom', ref: 'Bukhari 142, Muslim 375', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ would say: "Allahumma inni a\'udhu bika minal-khubuthi wal-khaba\'ith." (Bukhari 142)', vir: 'Seeking Allah\'s protection from evil and unclean spirits.', arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ', translit: "Allahumma inni a'udhu bika minal-khubuthi wal-khaba'ith", transl: "O Allah, I seek refuge in You from male and female evil spirits."),
    _S(cat: 'Personal Hygiene', t: 'Wash private parts after urination', ref: 'Bukhari 150', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ once passed by two graves and said they are being punished — one for not taking care with urine splashes. (Bukhari 150)', vir: 'Avoiding urine splashes is crucial for prayer validity.'),

    _S(cat: 'Social Etiquette & Character', t: 'Give salam (greeting)', ref: 'Bukhari 6247, Muslim 2160', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Spread salam amongst yourselves." (Muslim 2160)', vir: 'Salam spreads love and peace among Muslims.'),
    _S(cat: 'Social Etiquette & Character', t: 'Smile when meeting others', ref: 'Tirmidhi 1956', g: 'Hasan', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Your smiling in the face of your brother is charity." (Tirmidhi 1956)', vir: 'A smile is the easiest form of sadaqah.'),
    _S(cat: 'Social Etiquette & Character', t: 'Shake hands when meeting', ref: 'Abu Dawud 5212, Tirmidhi 2727', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "When two Muslims meet and shake hands, their sins are forgiven before they part." (Abu Dawud 5212)', vir: 'Handshaking causes sins to fall away like leaves from a tree.'),
    _S(cat: 'Social Etiquette & Character', t: 'Visit the sick', ref: 'Bukhari 5649, Muslim 2568', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Visit the sick, feed the hungry, and free the captive." (Bukhari 5649)', vir: 'Seventy thousand angels make dua for you when visiting the sick.'),
    _S(cat: 'Social Etiquette & Character', t: 'Say Yarhamukallah when someone sneezes', ref: 'Bukhari 6224, Muslim 2991', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "When one of you sneezes and says Alhamdulillah, say Yarhamukallah." (Bukhari 6224)', vir: 'Responding to a sneeze is a right of a Muslim upon another.'),
    _S(cat: 'Social Etiquette & Character', t: 'Attend funerals', ref: 'Bukhari 1183, Muslim 945', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Whoever attends the funeral until the prayer has two qirats of reward." (Muslim 945)', vir: 'Attending funerals earns immense reward and reminds of the akhirah.'),
    _S(cat: 'Social Etiquette & Character', t: 'Keep promises', ref: 'Muslim 2769', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "The signs of a hypocrite are three: when he speaks he lies, when he promises he breaks it, when he is trusted he betrays." (Muslim 2769)', vir: 'Keeping promises builds trust and strengthens iman.'),
    _S(cat: 'Social Etiquette & Character', t: 'Speak the truth', ref: 'Bukhari 6094, Muslim 2607', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Truthfulness leads to righteousness, and righteousness leads to Paradise." (Bukhari 6094)', vir: 'Truthfulness is the foundation of good character.'),
    _S(cat: 'Social Etiquette & Character', t: 'Control anger', ref: 'Bukhari 6114, Muslim 2609', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "The strong man is not the one who can wrestle, but the one who controls himself at the time of anger." (Bukhari 6114)', vir: 'Controlling anger is true strength and earns Allah\'s pleasure.'),
    _S(cat: 'Social Etiquette & Character', t: 'Forgive others', ref: 'Bukhari 6853, Muslim 2588', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Allah increases a person in honor who forgives." (Muslim 2588)', vir: 'Forgiveness elevates your rank with Allah.'),
    _S(cat: 'Social Etiquette & Character', t: 'Be kind to neighbors', ref: 'Bukhari 6014, Muslim 47', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Jibril kept urging me about the neighbor until I thought he would make him an heir." (Bukhari 6014)', vir: 'Neighbors have immense rights in Islam.'),
    _S(cat: 'Social Etiquette & Character', t: 'Respect elders', ref: 'Abu Dawud 4843, Tirmidhi 2022', g: 'Hasan', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "He is not one of us who does not show mercy to the young and respect to the old." (Tirmidhi 2022)', vir: 'Respecting elders is a hallmark of the Muslim community.'),
    _S(cat: 'Social Etiquette & Character', t: 'Lower your gaze', ref: 'Quran 24:30, Muslim 2159', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: '"Say to the believing men to lower their gaze." (Quran 24:30)', vir: 'Lowering the gaze protects the heart from temptation.'),
    _S(cat: 'Social Etiquette & Character', t: 'Avoid backbiting', ref: 'Quran 49:12, Abu Dawud 4875', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: '"O you who believe! Avoid much suspicion... And do not backbite one another." (Quran 49:12)', vir: 'Avoiding backbiting protects your good deeds from being taken away.'),
    _S(cat: 'Social Etiquette & Character', t: "Don't be arrogant", ref: 'Muslim 91', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "No one who has an atom\'s weight of arrogance in his heart will enter Paradise." (Muslim 91)', vir: 'Humility is the garment of the believer.'),
    _S(cat: 'Social Etiquette & Character', t: 'Be generous', ref: 'Bukhari 1433, Muslim 2408', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ was the most generous of people, especially in Ramadan. (Bukhari 1433)', vir: 'Generosity invites Allah\'s generosity upon you.'),
    _S(cat: 'Social Etiquette & Character', t: 'Reconcile between people', ref: 'Abu Dawud 4919, Tirmidhi 2509', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Shall I not tell you what is better than fasting, prayer, and charity? — Reconciling between people." (Abu Dawud 4919)', vir: 'Reconciliation is better than extra fasting and prayer.'),
    _S(cat: 'Social Etiquette & Character', t: 'Keep good company', ref: 'Abu Dawud 4833, Tirmidhi 2378', g: 'Hasan', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "A person is upon the religion of his friend, so let each one of you look at whom he befriends." (Abu Dawud 4833)', vir: 'Good company strengthens your faith and character.'),
    _S(cat: 'Social Etiquette & Character', t: 'Make dua for others in their absence', ref: 'Muslim 2733', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "No Muslim servant makes dua for his brother in his absence except that the angel says: And for you the same." (Muslim 2733)', vir: 'Every dua you make for someone else returns to you through an angel.'),
    _S(cat: 'Social Etiquette & Character', t: 'Relieve hardship and conceal faults', ref: 'Muslim 2699', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Whoever relieves a believer of a hardship, Allah will relieve him of a hardship on the Day of Resurrection; and whoever conceals a Muslim, Allah will conceal him." (Muslim 2699)', vir: 'Allah deals with you exactly as you deal with His servants.'),
    _S(cat: 'Social Etiquette & Character', t: 'Visit graves to remember the Hereafter', ref: 'Muslim 976', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "I had forbidden you from visiting graves, but now visit them, for they remind you of the Hereafter." (Muslim 976)', vir: 'Little softens a hardened heart like standing before a grave.'),

    // ━━━━━━━━━━━━━━━ SLEEP & WAKING ━━━━━━━━━━━━━━━
    _S(cat: 'Sleep & Waking', t: 'Sleep on the right side', ref: 'Bukhari 247, Muslim 2710', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "When you go to bed, lie on your right side." (Bukhari 247)', vir: 'Sleeping on the right side is the Prophetic position.'),
    _S(cat: 'Sleep & Waking', t: 'Recite Ayat al-Kursi before sleep', ref: 'Bukhari 2311', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "If you recite Ayat al-Kursi before sleeping, Allah will send a guardian angel and no devil will come near you until morning." (Bukhari 2311)', vir: 'Protection throughout the night from evil.', arabic: 'اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ', translit: 'Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum...', transl: 'Allah - there is no god except Him, the Ever-Living, the Sustainer of all existence...'),
    _S(cat: 'Sleep & Waking', t: 'Recite last two verses of Al-Baqarah', ref: 'Bukhari 5009, Muslim 808', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him." (Bukhari 5009)', vir: 'These verses are sufficient protection for the entire night.'),
    _S(cat: 'Sleep & Waking', t: 'Blow in hands, recite 3 Quls, wipe body', ref: 'Bukhari 5017', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'Before sleeping, the Prophet ﷺ would cup his hands, blow into them, recite Surah Ikhlas, Falaq, and Nas, then wipe over his body. (Bukhari 5017)', vir: 'A powerful nightly protection combining three surahs.'),
    _S(cat: 'Sleep & Waking', t: 'Say sleep dua', ref: 'Bukhari 6324, Muslim 2714', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ would say before sleeping: "Bismika Allahumma amutu wa ahya" — In Your name, O Allah, I die and I live. (Bukhari 6324)', vir: 'Surrendering yourself to Allah before sleep.', arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', translit: 'Bismika Allahumma amutu wa ahya', transl: 'In Your name, O Allah, I die and I live.'),
    _S(cat: 'Sleep & Waking', t: 'Sleep early after Isha', ref: 'Bukhari 568', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ disliked sleeping before Isha and talking after it. (Bukhari 568)', vir: 'Early sleep ensures energy for Fajr and Tahajjud.'),
    _S(cat: 'Sleep & Waking', t: 'Say waking dua upon waking', ref: 'Bukhari 6312, Muslim 2711', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ would say upon waking: "Alhamdulillahilladhi ahyana ba\'da ma amatana wa ilayhin-nushur." (Bukhari 6312)', vir: 'Gratitude for waking is gratitude for a new life.', arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ', translit: "Alhamdulillahilladhi ahyana ba'da ma amatana wa ilayhin-nushur", transl: 'Praise is to Allah Who gave us life after He caused us to die, and to Him is the return.'),
    _S(cat: 'Sleep & Waking', t: 'Make wudu before sleep', ref: 'Bukhari 247, Muslim 2710', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "When you go to bed, perform wudu as for prayer." (Bukhari 247)', vir: 'Sleeping in purity brings angelic protection.'),
    _S(cat: 'Sleep & Waking', t: 'Recite Surah al-Mulk before sleeping', ref: 'Tirmidhi 2891, Abu Dawud 1400', g: 'Hasan', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "A surah of thirty verses interceded for a man until he was forgiven — it is Surah al-Mulk." (Tirmidhi 2891)', vir: 'A surah that intercedes for its reciter and guards him in the grave.'),

    _S(cat: 'Masjid & Prayer', t: 'Pray Sunnah Rawatib prayers', ref: 'Bukhari 1180, Muslim 728', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Whoever prays twelve rak\'ahs of Sunnah prayers, Allah will build a house for him in Paradise." (Muslim 728)', vir: 'A house in Paradise for the regular Sunnah prayers.'),
    _S(cat: 'Masjid & Prayer', t: 'Pray two rakah when entering masjid', ref: 'Bukhari 1163, Muslim 714', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "When any of you enters the masjid, let him not sit until he has prayed two rak\'ahs." (Bukhari 1163)', vir: 'Greeting the masjid with prayer shows reverence for the house of Allah.'),
    _S(cat: 'Masjid & Prayer', t: 'Enter masjid with right foot', ref: 'Hakim 1/218', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'Enter the masjid with the right foot while saying the dua of entry. (Hakim 1/218)', vir: 'The right side is preferred for all good and clean actions.'),
    _S(cat: 'Masjid & Prayer', t: 'Say dua when entering masjid', ref: 'Muslim 713', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ would say: "Allahumm-aftah li abwaba rahmatik" when entering the masjid. (Muslim 713)', vir: 'Asking Allah to open the doors of His mercy.', arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ', translit: 'Allahummaftah li abwaba rahmatik', transl: 'O Allah, open for me the doors of Your mercy.'),
    _S(cat: 'Masjid & Prayer', t: 'Exit masjid with left foot', ref: 'Hakim 1/218', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'Exit the masjid with the left foot while saying the dua of exit. (Hakim 1/218)', vir: 'Maintaining adab even when leaving the masjid.'),
    _S(cat: 'Masjid & Prayer', t: 'Sit in masjid after Fajr until sunrise', ref: 'Muslim 670', g: 'Sahih', diff: SunnahDifficulty.advanced, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ would sit in the masjid after Fajr until sunrise, then pray two rak\'ahs. "The reward is like a complete Hajj and Umrah." (Tirmidhi 586)', vir: 'Reward equivalent to a complete Hajj and Umrah.'),
    _S(cat: 'Masjid & Prayer', t: 'Go early to Friday prayer', ref: 'Bukhari 929, Muslim 850', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.weekly, desc: 'The Prophet ﷺ said: "Whoever goes early to Friday prayer, it is as if he offered a camel." (Bukhari 929)', vir: 'Going early earns immense reward — like offering animals in charity.'),
    _S(cat: 'Masjid & Prayer', t: 'Sit in first row', ref: 'Bukhari 615, Muslim 440', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "If people knew the reward of sitting in the first row, they would draw lots for it." (Bukhari 615)', vir: 'The first row has the greatest reward in congregation.'),
    _S(cat: 'Masjid & Prayer', t: 'Fill gaps in rows', ref: 'Bukhari 725, Muslim 436', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Straighten your rows and fill the gaps." (Bukhari 725)', vir: 'Aligned rows unite the hearts of the worshippers.'),
    _S(cat: 'Masjid & Prayer', t: 'Pray witr before sleeping', ref: 'Bukhari 998, Muslim 749', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Make witr your last prayer at night." (Bukhari 998)', vir: 'Witr seals the night prayers beautifully.'),
    _S(cat: 'Masjid & Prayer', t: 'Pray Tahajjud (night prayer)', ref: 'Bukhari 1127, Muslim 775', g: 'Sahih', diff: SunnahDifficulty.advanced, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "The best prayer after the obligatory prayers is the night prayer." (Muslim 1163)', vir: 'Night prayer is the closest a servant gets to Allah.'),
    _S(cat: 'Masjid & Prayer', t: 'Make dua in prostration', ref: 'Muslim 482', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "The closest a servant is to his Lord is when he is prostrating, so make much dua." (Muslim 482)', vir: 'Prostration is the moment of ultimate closeness to Allah.'),
    _S(cat: 'Masjid & Prayer', t: 'Pray Salat al-Duha (forenoon prayer)', ref: 'Muslim 720', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Each morning a charity is due for every joint of your body... and two rak\'ahs of Duha suffice for all of that." (Muslim 720)', vir: 'Two short rak\'ahs that discharge the charity owed by every joint in your body.'),
    _S(cat: 'Masjid & Prayer', t: 'Pray Istikharah before decisions', ref: 'Bukhari 1162', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ taught istikharah for every matter as he taught a surah of the Quran: pray two rak\'ahs, then make the dua of istikharah. (Bukhari 1162)', vir: 'Handing every decision back to the One who knows the outcome.'),
    _S(cat: 'Masjid & Prayer', t: 'Pray two rakah after wudu', ref: 'Bukhari 1149', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ told Bilal he had heard his footsteps in Paradise. Bilal said he never performed wudu without praying two rak\'ahs after it. (Bukhari 1149)', vir: 'The deed by which Bilal preceded others into Paradise.'),
    _S(cat: 'Masjid & Prayer', t: 'Say the shahadah after wudu', ref: 'Muslim 234', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Whoever performs wudu well and then says the shahadah, the eight gates of Paradise are opened for him to enter by whichever he wishes." (Muslim 234)', vir: 'All eight gates of Paradise opened for a few seconds of dhikr.', arabic: 'أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ', translit: 'Ashhadu an la ilaha illallahu wahdahu la sharika lah, wa ashhadu anna Muhammadan abduhu wa rasuluh', transl: 'I bear witness that there is no god but Allah alone, with no partner, and that Muhammad is His servant and Messenger.'),
    _S(cat: 'Masjid & Prayer', t: 'Repeat after the muadhin, then ask for al-Wasilah', ref: 'Muslim 384, Bukhari 614', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "When you hear the muadhin, say what he says, then ask Allah to grant me al-Wasilah — whoever asks that for me, my intercession becomes due for him." (Muslim 384, Bukhari 614)', vir: 'The intercession of the Prophet ﷺ made due for you five times a day.'),
    _S(cat: 'Masjid & Prayer', t: 'Make dua between adhan and iqamah', ref: 'Abu Dawud 521, Tirmidhi 212', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Dua made between the adhan and the iqamah is not rejected." (Abu Dawud 521)', vir: 'Five windows of answered dua every day that most people sit through unaware.'),
    _S(cat: 'Masjid & Prayer', t: 'Walk to the masjid for congregation', ref: 'Muslim 666', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Whoever purifies himself at home then walks to one of the houses of Allah — one step erases a sin and another raises him a degree." (Muslim 666)', vir: 'Every single step to the masjid erases a sin and raises a rank.'),
    _S(cat: 'Masjid & Prayer', t: 'Pray four rakah before Asr', ref: 'Tirmidhi 430', g: 'Hasan', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "May Allah have mercy on a man who prays four rak\'ahs before Asr." (Tirmidhi 430)', vir: 'A supplication of mercy from the Prophet ﷺ for whoever keeps to it.'),
    _S(cat: 'Masjid & Prayer', t: 'Make dua in the last third of the night', ref: 'Bukhari 1145, Muslim 758', g: 'Sahih', diff: SunnahDifficulty.advanced, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Our Lord descends to the lowest heaven when the last third of the night remains and says: Who is calling upon Me, that I may answer him?" (Bukhari 1145)', vir: 'The one hour of the night in which Allah Himself invites you to ask.'),
    _S(cat: 'Masjid & Prayer', t: 'Stand in night prayer through Ramadan', ref: 'Bukhari 37, Muslim 759', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Whoever stands in prayer during Ramadan out of faith and seeking reward will have his previous sins forgiven." (Bukhari 37)', vir: 'A month of night prayer that wipes out everything before it.'),

    // ━━━━━━━━━━━━━━━ FASTING ━━━━━━━━━━━━━━━
    _S(cat: 'Fasting', t: 'Fast Mondays and Thursdays', ref: 'Tirmidhi 745, Nasa\'i 2361', g: 'Hasan', diff: SunnahDifficulty.medium, freq: SunnahFrequency.weekly, desc: 'The Prophet ﷺ used to fast on Mondays and Thursdays and said: "Deeds are shown on Monday and Thursday, and I like my deeds to be shown while I am fasting." (Tirmidhi 745)', vir: 'Your deeds are presented to Allah while you are fasting.'),
    _S(cat: 'Fasting', t: 'Fast 3 white days (13,14,15 lunar)', ref: 'Abu Dawud 2449, Nasa\'i 2424', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.monthly, desc: 'The Prophet ﷺ commanded Abu Dharr to fast three days of each month — the 13th, 14th, and 15th. (Nasa\'i 2424)', vir: 'Fasting three days equals fasting the entire month.'),
    _S(cat: 'Fasting', t: 'Fast 6 days of Shawwal', ref: 'Muslim 1164', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Whoever fasts Ramadan and follows it with six days of Shawwal, it is as if he fasted the entire year." (Muslim 1164)', vir: 'Six days of Shawwal complete the reward of a full year of fasting.'),
    _S(cat: 'Fasting', t: 'Fast day of Arafah (9th Dhul Hijjah)', ref: 'Muslim 1162', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Fasting the day of Arafah expiates the sins of the previous and coming year." (Muslim 1162)', vir: 'Two years of sins forgiven for one day of fasting.'),
    _S(cat: 'Fasting', t: 'Fast Ashura (10th Muharram) + 9th', ref: 'Muslim 1162, Bukhari 2006', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Fasting the day of Ashura, I hope that Allah will expiate the sins of the year before it." (Muslim 1162)', vir: 'A year of sins expiated by fasting Ashura.'),
    _S(cat: 'Fasting', t: 'Delay suhoor', ref: 'Bukhari 1921, Muslim 1097', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ would delay his suhoor until close to Fajr. (Bukhari 1921)', vir: 'Delaying suhoor provides more energy for the day of fasting.'),
    _S(cat: 'Fasting', t: 'Hasten breaking fast', ref: 'Bukhari 1957, Muslim 1098', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "The people will remain upon goodness as long as they hasten to break their fast." (Bukhari 1957)', vir: 'Breaking fast promptly shows trust in Allah\'s timing.'),
    _S(cat: 'Fasting', t: 'Make dua when breaking fast', ref: 'Ibn Majah 1753', g: 'Hasan', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "The dua of the fasting person at iftar is not rejected." (Ibn Majah 1753)', vir: 'A guaranteed moment of accepted dua.'),

    _S(cat: 'Family & Relationships', t: 'Be kind to parents', ref: 'Quran 17:23-24, Bukhari 5971', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: '"And your Lord has decreed that you not worship except Him, and to parents, good treatment." (Quran 17:23)', vir: 'Treating parents well is among the greatest deeds after worship.'),
    _S(cat: 'Family & Relationships', t: 'Kiss and hug your children', ref: 'Bukhari 5997, Muslim 2318', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ kissed his grandchild and said: "He who is not merciful will not be shown mercy." (Bukhari 5997)', vir: 'Showing love to children invites Allah\'s mercy.'),
    _S(cat: 'Family & Relationships', t: 'Play with your children', ref: 'Ahmad 26566', g: 'Hasan', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ would play with his grandchildren Hasan and Husayn. (Ahmad 26566)', vir: 'Playing with children strengthens bonds and brings joy.'),
    _S(cat: 'Family & Relationships', t: 'Be kind to your wife/husband', ref: 'Tirmidhi 3895, Ibn Majah 1977', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "The best of you are those who are best to their families, and I am the best to my family." (Tirmidhi 3895)', vir: 'Good treatment of spouse is a benchmark of character.'),
    _S(cat: 'Family & Relationships', t: 'Help with housework', ref: 'Bukhari 6039', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'Aisha was asked what the Prophet ﷺ did at home. She said: "He would serve his family." (Bukhari 6039)', vir: 'Helping at home is a sunnah, not beneath anyone.'),
    _S(cat: 'Family & Relationships', t: 'Maintain ties of kinship', ref: 'Bukhari 5984, Muslim 2556', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Whoever wants his provision to be increased and lifespan extended, let him maintain ties of kinship." (Bukhari 5984)', vir: 'Maintaining family ties increases provision and lifespan.'),
    _S(cat: 'Family & Relationships', t: 'Teach children to pray at 7', ref: 'Abu Dawud 495', g: 'Hasan', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Command your children to pray at the age of seven." (Abu Dawud 495)', vir: 'Early nurturing of prayer builds lifelong devotion.'),
    _S(cat: 'Family & Relationships', t: 'Be equal among children', ref: 'Bukhari 2586, Muslim 1623', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Fear Allah and treat your children fairly." (Bukhari 2586)', vir: 'Fairness prevents jealousy and resentment among siblings.'),
    _S(cat: 'Family & Relationships', t: 'Give gifts to strengthen love', ref: 'Bukhari (al-Adab al-Mufrad 594)', g: 'Hasan', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Give gifts to one another, for gifts remove grudges." (Bukhari al-Adab al-Mufrad 594)', vir: 'Gifts dissolve ill feelings and strengthen bonds.'),
    _S(cat: 'Family & Relationships', t: 'Eat together as a family', ref: 'Abu Dawud 3764', g: 'Hasan', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Gather together for your meals and mention the name of Allah, and you will be blessed." (Abu Dawud 3764)', vir: 'Eating together invites barakah and strengthens family bonds.'),
    _S(cat: 'Family & Relationships', t: 'Make dua for your children', ref: 'Quran 25:74', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: '"Our Lord, grant us from among our wives and offspring comfort to our eyes." (Quran 25:74)', vir: 'Dua for children is an investment in the akhirah.'),
    _S(cat: 'Family & Relationships', t: 'Honor guests', ref: 'Bukhari 6018, Muslim 47', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Whoever believes in Allah and the Last Day, let him honor his guest." (Bukhari 6018)', vir: 'Hospitality is a sign of true faith.'),
    _S(cat: 'Family & Relationships', t: 'Consult family in decisions', ref: 'Quran 3:159', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: '"And consult them in affairs." (Quran 3:159)', vir: 'Shura in the family builds trust and unity.'),
    _S(cat: 'Family & Relationships', t: 'Say salam when entering home', ref: 'Quran 24:61, Abu Dawud 5096', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: '"When you enter houses, greet one another with a greeting from Allah." (Quran 24:61)', vir: 'Greeting your family fills the home with peace and barakah.'),
    _S(cat: 'Family & Relationships', t: "Honour your parents' friends after them", ref: 'Muslim 2552', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "The finest act of goodness is that a man maintains ties with the friends of his father after his father has passed away." (Muslim 2552)', vir: 'A way to keep honouring your parents long after they are gone.'),

    // ━━━━━━━━━━━━━━━ CHARITY & GENEROSITY ━━━━━━━━━━━━━━━
    _S(cat: 'Charity & Generosity', t: 'Give sadaqah daily', ref: 'Bukhari 1410, Muslim 1009', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Every Muslim must give charity." They asked: "What if he cannot?" He said: "Then a good word is charity." (Bukhari 1410)', vir: 'Charity is not limited to wealth — a smile, a word, removing harm are all charity.'),
    _S(cat: 'Charity & Generosity', t: 'Spend in secret', ref: 'Quran 2:271, Bukhari 660', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: '"If you disclose your charitable expenditures, that is good; but if you hide them and give to the poor, it is better." (Quran 2:271)', vir: 'Secret charity is shaded under Allah\'s throne on the Day of Judgment.'),
    _S(cat: 'Charity & Generosity', t: 'Feed the poor', ref: 'Bukhari 12, Muslim 39', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "Spread salam and feed people, you will enter Paradise in peace." (Bukhari 12)', vir: 'Feeding the hungry is one of the most rewarded acts.'),
    _S(cat: 'Charity & Generosity', t: 'Remove harm from the path', ref: 'Bukhari 652, Muslim 1914', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Removing a harmful thing from the road is charity." (Bukhari 652)', vir: 'Even the smallest good deed is a form of worship.'),
    _S(cat: 'Charity & Generosity', t: 'Give water to the thirsty', ref: 'Bukhari 2466, Muslim 2244', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ told of a man forgiven for giving water to a thirsty dog. (Bukhari 2466)', vir: 'Providing water earns immense reward.'),
    _S(cat: 'Charity & Generosity', t: 'Be charitable to animals', ref: 'Bukhari 2363, Muslim 2244', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "In every moist liver, there is reward." (Bukhari 2363)', vir: 'Kindness to animals is rewarded by Allah.'),
    _S(cat: 'Charity & Generosity', t: 'Sadaqah jariyah (ongoing charity)', ref: 'Muslim 1631', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ said: "When a person dies, his deeds come to an end except three: ongoing charity, knowledge benefited from, and a righteous child who prays for him." (Muslim 1631)', vir: 'A charity that keeps giving reward even after death.'),

    // ━━━━━━━━━━━━━━━ DHIKR & AZKAR ━━━━━━━━━━━━━━━
    _S(cat: 'Dhikr & Azkar', t: 'Complete Morning Azkar', ref: 'Hisn al-Muslim (Morning Adhkar)', g: 'Authenticated', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'Recite morning adhkar including Ayat al-Kursi (1x), Surah Ikhlas/Falaq/Nas (3x), and Sayyid al-Istighfar. (Hisn al-Muslim)', vir: 'Morning azkar form a shield of protection for the entire day.', tasbihId: 'morning_azkar', tips: ['Use the digital tasbih to track repeated adhkar.', 'Best recited between Fajr and sunrise.']),
    _S(cat: 'Dhikr & Azkar', t: 'Complete Evening Azkar', ref: 'Hisn al-Muslim (Evening Adhkar)', g: 'Authenticated', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'Recite evening adhkar including Ayat al-Kursi (1x), Surah Ikhlas/Falaq/Nas (3x), and protective duas. (Hisn al-Muslim)', vir: 'Evening azkar protect you through the night.', tasbihId: 'evening_azkar', tips: ['Use the digital tasbih to track repeated adhkar.', 'Best recited between Asr and Maghrib.']),
    _S(cat: 'Dhikr & Azkar', t: 'Complete Before-Sleep Azkar', ref: 'Hisn al-Muslim (Sleep Adhkar)', g: 'Authenticated', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'Before sleep recite: SubhanAllah (33x), Alhamdulillah (33x), and Allahu Akbar (34x), along with sleep adhkar. (Hisn al-Muslim)', vir: 'Sleep adhkar ensure protection and angelic guardianship.', tasbihId: 'before_sleep_azkar', tips: ['Use the digital tasbih to track repeated adhkar.', 'Combine with the sunnah of sleeping on the right side.']),
    _S(cat: 'Dhikr & Azkar', t: 'Say SubhanAllah 33 times after prayer', ref: 'Muslim 596', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Whoever says SubhanAllah 33 times, Alhamdulillah 33 times, Allahu Akbar 33 times, and completes 100 with La ilaha illAllah — his sins will be forgiven even if they are like the foam of the sea." (Muslim 596)', vir: 'All past sins forgiven — an effortless daily practice.', arabic: 'سُبْحَانَ اللَّهِ', translit: 'SubhanAllah', transl: 'Glory be to Allah', tasbihId: 'subhanallah', reps: 33, tips: ['Use the digital tasbih to track counts.', 'Say after each of the five daily prayers.']),
    _S(cat: 'Dhikr & Azkar', t: 'Say Alhamdulillah 33 times after prayer', ref: 'Muslim 596', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'Part of the post-prayer dhikr formula. (Muslim 596)', vir: 'Gratitude to Allah after every prayer purifies the soul.', arabic: 'الْحَمْدُ لِلَّهِ', translit: 'Alhamdulillah', transl: 'All praise is due to Allah', tasbihId: 'alhamdulillah', reps: 33, tips: ['Use the digital tasbih to track counts.', 'Say after each of the five daily prayers.']),
    _S(cat: 'Dhikr & Azkar', t: 'Say Allahu Akbar 34 times after prayer', ref: 'Muslim 596', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'Part of the post-prayer dhikr formula. (Muslim 596)', vir: 'Affirming Allah\'s greatness after every prayer.', arabic: 'اللَّهُ أَكْبَرُ', translit: 'Allahu Akbar', transl: 'Allah is the Greatest', tasbihId: 'allahuakbar', reps: 34, tips: ['Use the digital tasbih to track counts.', 'Say after each of the five daily prayers.']),
    _S(cat: 'Dhikr & Azkar', t: 'Istighfar 100 times daily', ref: 'Muslim 2702, Bukhari 6307', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "By Allah, I seek Allah\'s forgiveness more than seventy times a day." (Bukhari 6307)', vir: 'Regular istighfar opens doors of provision and relief.', arabic: 'أَسْتَغْفِرُ اللَّهَ', translit: 'Astaghfirullah', transl: 'I seek forgiveness from Allah', tasbihId: 'astaghfirullah', reps: 100, tips: ['Use the digital tasbih to track counts.', 'Split counts across the day to stay consistent.']),
    _S(cat: 'Dhikr & Azkar', t: 'Say La ilaha illAllah 100 times', ref: 'Bukhari 3293, Muslim 2691', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Whoever says La ilaha illAllah 100 times, he gets the reward of freeing ten slaves, 100 good deeds, 100 sins erased, and is protected from Shaytan." (Bukhari 3293)', vir: 'Protection from Shaytan and mountains of reward.', arabic: 'لَا إِلَـٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ', translit: "La ilaha illAllahu wahdahu la sharika lah", transl: 'There is no god but Allah alone, with no partner.', tasbihId: 'la_ilaha_illallah', reps: 100, tips: ['Use the digital tasbih to track counts.', 'Split counts across the day to stay consistent.']),
    _S(cat: 'Dhikr & Azkar', t: 'Send Salawat on the Prophet ﷺ', ref: 'Muslim 408, Tirmidhi 2457', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Whoever sends salawat upon me once, Allah sends blessings upon him ten times." (Muslim 408)', vir: 'Every salawat returns tenfold blessings from Allah.', arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ', translit: "Allahumma salli 'ala Muhammad wa 'ala ali Muhammad", transl: 'O Allah, send blessings on Muhammad and on the family of Muhammad.', tasbihId: 'salawat', tips: ['Use the digital tasbih to track counts.', 'Especially on Friday — it is presented to the Prophet ﷺ.']),
    _S(cat: 'Dhikr & Azkar', t: 'Say Sayyid al-Istighfar morning and evening', ref: 'Bukhari 6306', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ called this the finest way of seeking forgiveness: "Whoever says it during the day with certainty and dies before evening will be among the people of Paradise." (Bukhari 6306)', vir: 'The master of seeking forgiveness, with Paradise promised to whoever says it with conviction.', arabic: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ', translit: 'Allahumma anta Rabbi la ilaha illa anta, khalaqtani wa ana abduk', transl: 'O Allah, You are my Lord. There is no god but You. You created me and I am Your servant.'),
    _S(cat: 'Dhikr & Azkar', t: 'Say La hawla wa la quwwata illa billah', ref: 'Bukhari 6384, Muslim 2704', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said to Abu Musa: "Shall I not teach you a treasure from the treasures of Paradise? — La hawla wa la quwwata illa billah." (Bukhari 6384)', vir: 'A treasure of Paradise in a single phrase.', arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', translit: 'La hawla wa la quwwata illa billah', transl: 'There is no might nor power except with Allah.'),
    _S(cat: 'Dhikr & Azkar', t: 'Tasbih of Fatimah', ref: 'Bukhari 3113', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ taught Fatimah: SubhanAllah 33, Alhamdulillah 33, Allahu Akbar 34 — before sleeping. (Bukhari 3113)', vir: 'Better than having a servant — strength from dhikr.', tasbihId: 'subhanallah', tips: ['Use the digital tasbih to track counts.', 'Recite before sleeping for energy and strength.']),
    
    // ━━━━━━━━━━━━━━━ KNOWLEDGE ━━━━━━━━━━━━━━━
    _S(cat: 'Knowledge', t: 'Read Quran daily', ref: 'Muslim 804', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Read the Quran, for it will come on the Day of Judgment as an intercessor for its people." (Muslim 804)', vir: 'Every letter earns ten rewards — the Quran intercedes.'),
    _S(cat: 'Knowledge', t: 'Seek knowledge', ref: 'Ibn Majah 224', g: 'Hasan', diff: SunnahDifficulty.medium, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Seeking knowledge is an obligation upon every Muslim." (Ibn Majah 224)', vir: 'Knowledge is the foundation of righteous action.'),
    _S(cat: 'Knowledge', t: 'Memorize Quran', ref: 'Bukhari 5027', g: 'Sahih', diff: SunnahDifficulty.advanced, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "The best of you are those who learn the Quran and teach it." (Bukhari 5027)', vir: 'Memorizing Quran elevates your rank in both worlds.'),
    _S(cat: 'Knowledge', t: 'Recite Surah al-Kahf every Friday', ref: 'Hakim, Bayhaqi', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.weekly, desc: 'The Prophet ﷺ said: "Whoever recites Surah al-Kahf on the day of Jumu\'ah, a light will shine for him between the two Fridays." (Hakim, Bayhaqi — graded Sahih by al-Albani)', vir: 'A light lasting the whole week, and protection from the trial of the Dajjal.'),

    _S(cat: 'Travel', t: 'Say travel dua when setting out', ref: 'Muslim 1342, Tirmidhi 3447', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ would say: "SubhanAlladhi sakhkhara lana hadha..." when starting a journey. (Muslim 1342)', vir: 'Travel dua invites Allah\'s protection on your journey.', arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَـٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ', translit: 'SubhanAlladhi sakhkhara lana hadha wa ma kunna lahu muqrinin', transl: 'Glory to Him Who has subjected this to us, and we could never have it by our efforts.'),
    _S(cat: 'Travel', t: 'Shorten prayers while traveling', ref: 'Bukhari 1080, Muslim 686', g: 'Sahih', diff: SunnahDifficulty.medium, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ would shorten the four-rak\'ah prayers to two while traveling. (Bukhari 1080)', vir: 'Allah\'s mercy in making worship easier during travel.'),
    _S(cat: 'Travel', t: 'Make dua when returning from travel', ref: 'Bukhari 1797, Muslim 1344', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ would say: "Ayibuna ta\'ibuna \'abiduna li Rabbina hamidun" upon returning. (Bukhari 1797)', vir: 'Returning home with gratitude and worship.'),
    _S(cat: 'Travel', t: 'Pray two rakah upon returning home', ref: 'Bukhari 443, Muslim 716', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ would start by praying in the masjid upon returning from travel. (Bukhari 443)', vir: 'Returning to prayer first shows gratitude for a safe journey.'),

    // ━━━━━━━━━━━━━━━ MISCELLANEOUS ━━━━━━━━━━━━━━━
    _S(cat: 'Miscellaneous Daily Sunnahs', t: 'Say dua when wearing new clothes', ref: 'Abu Dawud 4020, Tirmidhi 3560', g: 'Hasan', diff: SunnahDifficulty.easy, freq: SunnahFrequency.occasional, desc: 'The Prophet ﷺ would say: "Alhamdulillahilladhi kasani hadha wa razaqanihi..." when wearing new clothes. (Abu Dawud 4020)', vir: 'Thanking Allah for provision and clothing.'),
    _S(cat: 'Miscellaneous Daily Sunnahs', t: 'Keep environment clean', ref: 'Muslim 223', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said: "Cleanliness is half of faith." (Muslim 223)', vir: 'A clean environment reflects a clean heart.'),
    _S(cat: 'Miscellaneous Daily Sunnahs', t: 'Say the dua when leaving home', ref: 'Abu Dawud 5095, Tirmidhi 3426', g: 'Sahih', diff: SunnahDifficulty.easy, freq: SunnahFrequency.daily, desc: 'The Prophet ﷺ said that whoever says this on leaving his house is told: "You are guided, defended and protected," and Shaytan turns away from him. (Abu Dawud 5095)', vir: 'Guidance, sufficiency and protection every time you step outside.', arabic: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', translit: 'Bismillah, tawakkaltu ala Allah, wa la hawla wa la quwwata illa billah', transl: 'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.'),
  ];
}

// ──────────────────────────── seed helper ────────────────────────────

class _S {
  final String cat, t, ref, g, desc, vir;
  final SunnahDifficulty diff;
  final SunnahFrequency freq;
  final String? arabic, translit, transl, tasbihId;
  final int? reps;
  final List<String> tips;

  const _S({
    required this.cat,
    required this.t,
    required this.ref,
    required this.g,
    required this.diff,
    required this.freq,
    required this.desc,
    required this.vir,
    this.arabic,
    this.translit,
    this.transl,
    this.tasbihId,
    this.reps,
    this.tips = const [],
  });

  Sunnah toSunnah() {
    final baseId = _slug('${cat}_$t');
    return Sunnah(
      id: baseId,
      title: t,
      category: cat,
      difficulty: diff,
      frequency: freq,
      description: desc,
      arabic: arabic,
      transliteration: translit,
      translation: transl,
      virtue: vir,
      reference: {'hadith': ref, 'book': _extractBook(ref), 'grade': g},
      tips: tips,
      tasbihId: tasbihId,
      repetitions: reps,
    );
  }

  static String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String _extractBook(String reference) {
    final firstPart = reference.split(',').first.trim();
    final match = RegExp(r"^[A-Za-z'\- ]+").firstMatch(firstPart);
    final book = match?.group(0)?.trim();
    return (book == null || book.isEmpty) ? 'Hadith Reference' : book;
  }
}
