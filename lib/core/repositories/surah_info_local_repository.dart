class SurahInfoData {
  final int surahId;
  final String title;
  final String revelation;
  final String period;
  final String background;
  final String themes;
  final String virtues;

  const SurahInfoData({
    required this.surahId,
    required this.title,
    required this.revelation,
    required this.period,
    required this.background,
    required this.themes,
    required this.virtues,
  });
}

class SurahInfoLocalRepository {
  static const Map<int, SurahInfoData> _data = {
    1: SurahInfoData(
      surahId: 1,
      title: 'Al-Fatihah (The Opening)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Al-Fatihah is the first Surah of the Quran and the most recited chapter. It is known as the "Mother of the Book" (Umm al-Kitab). It was revealed early in Mecca when the Prophet ﷺ first began his mission. It serves as a comprehensive prayer for guidance, mercy, and the straight path, encompassing the core essence of Islam.',
      themes:
      '• The Oneness and Mercy of Allah.\n• Acknowledgment of Allah as the Master of the Day of Judgment.\n• A declaration of exclusive worship and seeking help from Him alone.\n• A prayer for guidance to the straight path, away from those who have strayed.',
      virtues:
      'The Prophet ﷺ said, "By Him in Whose Hand is my soul, nothing like it has been revealed in the Torah, the Gospel, the Psalms, or the Quran. It is the Seven Oft-Repeated Verses and the Great Quran which I have been given." (Tirmidhi)',
    ),
    2: SurahInfoData(
      surahId: 2,
      title: 'Al-Baqarah (The Cow)',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'Al-Baqarah is the longest Surah in the Quran. It was largely revealed shortly after the Hijrah (migration) to Medina, making it one of the earliest Medinan Surahs. It covers a vast array of topics necessary for building the new Islamic society, establishing laws, confronting hypocrites, and addressing the People of the Book (Jews and Christians) living in Medina.',
      themes:
      '• Comprehensive laws regarding prayer, fasting (Ramadan), pilgrimage, charity, and commerce.\n• The stories of previous prophets, highlighting the story of Musa (Moses) and the Israelites (the incident of the Cow).\n• Clear distinction between belief, disbelief, and hypocrisy.\n• The shifting of the Qibla from Jerusalem to Mecca.',
      virtues:
      'The Prophet ﷺ said: "Do not turn your houses into graves. Indeed, Satan flees from the house in which Surah Al-Baqarah is recited." (Muslim)',
    ),
    3: SurahInfoData(
      surahId: 3,
      title: 'Ali \'Imran (The Family of Imran)',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'Revealed in Medina, this Surah addresses the Christian delegation from Najran who came to debate the Prophet ﷺ about the nature of Jesus (Isa). It was also revealed in the aftermath of the Battle of Uhud (3 AH) to comfort and strengthen the believers after their setback. It continues many themes from Al-Baqarah, particularly dialogues with the People of the Book.',
      themes:
      '• The nature of Jesus (Isa) as a prophet and servant of Allah, not divine.\n• Lessons from the Battle of Uhud: patience, obedience to the Prophet ﷺ, and trusting in Allah.\n• The story of Maryam (Mary) and the birth of Isa.\n• The virtue of firm faith and standing firm against adversity.',
      virtues:
      'The Prophet ﷺ said: "Recite Al-Baqarah and Ali \'Imran, for they will come on the Day of Resurrection like two clouds, or two shades, or two flocks of birds, pleading for their companions." (Muslim)',
    ),
    4: SurahInfoData(
      surahId: 4,
      title: 'An-Nisa\' (The Women)',
      revelation: 'Medina',
      period: 'Early to Middle Medinan Period',
      background:
      'Revealed in Medina, this Surah was largely revealed after the Battle of Uhud (3 AH) and deals extensively with the social reorganization of the Muslim community. It addresses the large number of orphans and widows created by the wars, establishing laws to protect the vulnerable, particularly women and orphans.',
      themes:
      '• Detailed laws of inheritance, marriage, and the treatment of women and orphans.\n• Rules of conduct in war and dealing with hypocrites.\n• The prohibition of usurping the rights of the weak.\n• Laws governing family life and justice.',
      virtues:
      'This Surah is of immense legal importance and is frequently referenced in Islamic jurisprudence. Ibn Abbas said it contains ten verses, each of which is better for this Ummah than all that is in the world.',
    ),
    5: SurahInfoData(
      surahId: 5,
      title: 'Al-Ma\'idah (The Table Spread)',
      revelation: 'Medina',
      period: 'Late Medinan Period',
      background:
      'One of the last Surahs to be revealed, Al-Ma\'idah was largely revealed in the 10th year of Hijrah, around the time of the Farewell Pilgrimage. It finalizes many of the Islamic laws and deals with the completion of the religion. It addresses the treaties and obligations of the believers, and the final stance on the People of the Book.',
      themes:
      '• The completion and perfection of the Islamic religion.\n• Dietary laws (halal and haram foods), including the prohibition of intoxicants.\n• Laws regarding oaths and justice.\n• The story of the Table (Ma\'idah) requested by the disciples of Jesus.\n• Stern warnings against those who break covenants.',
      virtues:
      'Umar ibn al-Khattab reported that the Prophet ﷺ said: "Al-Ma\'idah is the last Surah to be revealed, so treat as permissible what it treats as permissible and treat as forbidden what it treats as forbidden." (Ahmad)',
    ),
    6: SurahInfoData(
      surahId: 6,
      title: 'Al-An\'am (The Cattle)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Al-An\'am is one of the few Surahs revealed entirely in one sitting in Mecca, according to many scholars. It was revealed when the Prophet ﷺ was under intense pressure from the Quraysh, who pressured him to compromise on monotheism. It is a powerful and comprehensive refutation of paganism, idolatry, and polytheism using rational and logical arguments.',
      themes:
      '• Proofs of Allah\'s existence, uniqueness, and absolute power through His creation.\n• The futility and irrationality of idol worship.\n• The long history of prophets and the consistent rejection they faced.\n• The story of Ibrahim (Abraham) seeking the truth and rejecting his people\'s idols.',
      virtues:
      'It is reported that this Surah was revealed accompanied by seventy thousand angels, and the sky resounded with glorification of Allah. It is a Surah of profound theological depth.',
    ),
    7: SurahInfoData(
      surahId: 7,
      title: 'Al-A\'raf (The Heights)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed in the late Meccan period, Al-A\'raf is one of the longer Meccan Surahs. It details the stories of past nations and their prophets to draw lessons for the Quraysh, warning them of the fate that befell those who rejected their messengers. It also describes the Day of Judgment and the barrier (Al-A\'raf) between Paradise and Hell.',
      themes:
      '• Stories of prophets: Adam, Nuh (Noah), Hud, Salih, Lut, Shu\'ayb, and Musa.\n• The fate of nations that rejected their prophets.\n• The barrier (Al-A\'raf) and its people on the Day of Judgment.\n• The primordial covenant (Mithaq) that Allah took from all of Adam\'s descendants.',
      virtues:
      'Al-A\'raf is one of the most detailed accounts of the stories of the prophets in the Quran, serving as a comprehensive warning and lesson for all generations.',
    ),
    8: SurahInfoData(
      surahId: 8,
      title: 'Al-Anfal (The Spoils of War)',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'Revealed shortly after the Battle of Badr (2 AH), the first major military victory of the Muslims. It addresses questions that arose among the companions about the distribution of the spoils of war. It also analyses why the believers were victorious, linking it to their faith and obedience to Allah and His Messenger ﷺ.',
      themes:
      '• The rules governing the spoils of war (Ghanimah).\n• Lessons and analysis of the Battle of Badr.\n• The importance of faith, unity, and obedience during times of conflict.\n• Instructions on treaties and the conduct of war and peace.',
      virtues:
      'This Surah contains the verse of Tawakkul (reliance on Allah): "And if they intend to deceive you, then sufficient for you is Allah." It is a primary Surah in Islamic military ethics.',
    ),
    9: SurahInfoData(
      surahId: 9,
      title: 'At-Tawbah (The Repentance)',
      revelation: 'Medina',
      period: 'Late Medinan Period',
      background:
      'The only Surah of the Quran that does not begin with Bismillah. It was revealed in the 9th year of Hijrah. Scholars differ on the reason for the missing Bismillah; the most common view is that its severe, declaratory tone signals it as a continuation of Al-Anfal. It deals with the dissolution of treaties with polytheists who broke their agreements and addresses the hypocrites in Medina who refused to participate in the Battle of Tabuk.',
      themes:
      '• Annulment of treaties with idolaters who violated their oaths.\n• Severe condemnation and exposure of the hypocrites (Munafiqun).\n• The obligation of Jihad (striving in the way of Allah).\n• The virtue of the companions who participated in the Battle of Tabuk and the story of the three who stayed behind.',
      virtues:
      'This Surah, along with Al-Baqarah, contains the most detailed exposé of hypocrisy (Nifaq) in the Quran, and is an essential study for understanding the challenges the early Muslim community faced.',
    ),
    10: SurahInfoData(
      surahId: 10,
      title: 'Yunus (Jonah)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed in Mecca when the Prophet ﷺ faced consistent rejection and mockery. It consoles him by recounting the stories of previous prophets, especially Yunus (Jonah). It emphasizes that guidance is in Allah\'s hands, and the Prophet\'s role is only to convey the message clearly.',
      themes:
      '• Allah\'s absolute power and wisdom in managing the universe.\n• The stories of Nuh, Musa, and Yunus as examples of patience and reliance on Allah.\n• The nature of disbelief and the rejection of the truth.\n• The mercy of Allah and His acceptance of repentance.',
      virtues:
      'The Surah contains one of the most significant verses on repentance: "Then has there not been a [single] city that believed and its faith benefited it except the people of Yunus?" (10:98)',
    ),
    11: SurahInfoData(
      surahId: 11,
      title: 'Hud',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed in Mecca, this Surah is named after the Prophet Hud, though it contains the stories of several prophets. The Prophet ﷺ reportedly said this Surah and its sisters (Yunus, Al-Waqi\'ah, Al-Mursalat, An-Naba\', and At-Takwir) caused him to age, due to the profound weight of the command to "stand firm as you have been commanded" (11:112).',
      themes:
      '• Stories of Nuh, Hud, Salih, Ibrahim, Lut, Shu\'ayb, and Musa — their call to faith and the destruction of their peoples.\n• The command for istiqamah (steadfastness) in following the Straight Path.\n• The certainty of divine punishment for those who persist in wrongdoing.',
      virtues:
      'The Prophet ﷺ said about this Surah and its sisters: "They have made me old." (Tirmidhi) This reflects the immense weight of its commands and warnings.',
    ),
    12: SurahInfoData(
      surahId: 12,
      title: 'Yusuf (Joseph)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed in Mecca during the "Year of Sorrow" (10th year of Prophethood), when the Prophet ﷺ lost both his wife Khadijah and uncle Abu Talib. Allah revealed the story of Yusuf to console the Prophet ﷺ, as Yusuf also faced family betrayal, false accusation, and imprisonment, yet remained patient and was ultimately triumphant.',
      themes:
      '• The complete story of Yusuf: betrayal by his brothers, slavery in Egypt, the seduction by the minister\'s wife, imprisonment, and his rise to power.\n• Patience (Sabr) in the face of trials.\n• The truth that Allah\'s plan is always for the best, no matter how difficult the circumstances appear.',
      virtues:
      'Allah describes it as "the best of stories" (12:3). Its narrative is considered the most complete and morally instructive story in the Quran, encompassing themes of faith, patience, family, and forgiveness.',
    ),
    13: SurahInfoData(
      surahId: 13,
      title: 'Ar-Ra\'d (The Thunder)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed in Mecca, Ar-Ra\'d takes its name from the verse about thunder glorifying Allah\'s praise. It addresses the persistent demand of the Quraysh for miracles as proof of prophethood, and responds by drawing their attention to the natural wonders of creation as sufficient signs.',
      themes:
      '• Signs of Allah in nature: the heavens, rivers, fruits, and thunder.\n• The function of angels in recording deeds.\n• The invincibility of truth against falsehood.\n• The concept of Qadar (divine decree) and that Allah does not change the condition of a people until they change themselves.',
      virtues:
      'Contains the famous verse: "Indeed, Allah will not change the condition of a people until they change what is in themselves." (13:11) — one of the most quoted verses on social responsibility and self-improvement.',
    ),
    14: SurahInfoData(
      surahId: 14,
      title: 'Ibrahim (Abraham)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed in Mecca, this Surah is named after the Prophet Ibrahim (Abraham). It focuses on the role of the prophets in bringing people from darkness to light, and uses Ibrahim\'s supplication for Mecca and his family as a model of devotion and trust in Allah.',
      themes:
      '• The universal mission of prophets to guide people from darkness to light.\n• The blessing of divine speech (the Quran) as a light.\n• Ibrahim\'s prayer for Mecca, his descendants, and its people.\n• A vivid contrast between the good word (like a tree with firm roots) and the evil word (like a tree uprooted).',
      virtues:
      'Contains the profound parable of the good word and the evil word (14:24-26), and Ibrahim\'s heartfelt supplications — one of the most beautiful examples of du\'a in the Quran.',
    ),
    15: SurahInfoData(
      surahId: 15,
      title: 'Al-Hijr (The Rocky Tract)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca and named after Al-Hijr, the rocky land of the Thamud tribe. It consoles the Prophet ﷺ against the mockery of the Quraysh by reminding him that previous prophets were also mocked and rejected, yet Allah\'s plan prevailed.',
      themes:
      '• The guarding of the Quran from corruption by Allah Himself.\n• The story of Iblis (Satan) refusing to bow to Adam and his vow to mislead humanity.\n• The story of the people of Lut and their destruction.\n• The people of Al-Hijr (Thamud) and their fate after rejecting their prophet.',
      virtues:
      'Contains the great divine guarantee: "Indeed, it is We who sent down the Quran and indeed, We will be its guardian." (15:9)',
    ),
    16: SurahInfoData(
      surahId: 16,
      title: 'An-Nahl (The Bee)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed in Mecca, An-Nahl takes its name from the remarkable verse about the bee and the honey it produces. The Surah catalogs Allah\'s countless blessings upon humanity, from natural phenomena to domestic animals, as an argument for gratitude and monotheism.',
      themes:
      '• Enumeration of Allah\'s blessings: cattle, water, rivers, ships, night, day, stars, mountains.\n• The miracle of the bee and the healing in honey.\n• The prohibition of what Allah has forbidden (carrion, blood, swine) and the concept of halal/haram.\n• A call to wisdom (hikmah), good preaching (maw\'izah), and fair debate.',
      virtues:
      'Contains the famous verse on wisdom and beautiful preaching: "Invite to the way of your Lord with wisdom and good instruction, and argue with them in a way that is best." (16:125)',
    ),
    17: SurahInfoData(
      surahId: 17,
      title: 'Al-Isra\' (The Night Journey)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Also known as Bani Isra\'il (Children of Israel), this Surah was revealed after the miraculous Night Journey (Isra\') of the Prophet ﷺ from Mecca to Jerusalem and his Ascension (Mi\'raj) to the heavens. It contains a comprehensive moral code sometimes called the "Ten Commandments of Islam."',
      themes:
      '• The miracle of the Night Journey (Isra\' wal-Mi\'raj).\n• A comprehensive moral code: respect for parents, prohibition of killing, protecting orphans, honesty in dealings.\n• The story of Bani Isra\'il (Children of Israel) and their two periods of corruption.\n• The nobility of the human being and the enmity of Shaytan.',
      virtues:
      'Contains the ten commandments of Islam (17:22-38) and the verse: "And your Lord has decreed that you not worship except Him, and to parents, good treatment." (17:23)',
    ),
    18: SurahInfoData(
      surahId: 18,
      title: 'Al-Kahf (The Cave)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca at a time when the Muslims were facing severe persecution from the Quraysh. The Quraysh, advised by Jewish scholars, tested the Prophet ﷺ with three questions to prove his prophethood: The youth of the cave, the great traveler (Dhul-Qarnayn), and the nature of the soul. This Surah answered them perfectly, offering deep lessons on faith versus materialism.',
      themes:
      '• The story of the Sleepers of the Cave (Trials of Faith).\n• The story of the owner of the two gardens (Trials of Wealth).\n• The story of Musa and Khidr (Trials of Knowledge).\n• The story of Dhul-Qarnayn (Trials of Power).',
      virtues:
      'The Prophet ﷺ said: "Whoever recites Surah Al-Kahf on Friday, it will illuminate him with light from one Friday to the next." (Al-Hakim)',
    ),
    19: SurahInfoData(
      surahId: 19,
      title: 'Maryam (Mary)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca. When the first Muslims emigrated to Abyssinia, Ja\'far ibn Abi Talib recited verses from this Surah before the Christian king Negus, moving him to tears. It establishes the miraculous birth of Jesus through his virgin mother Mary, correcting Christian and Jewish misconceptions about them both.',
      themes:
      '• The miraculous birth of Yahya (John the Baptist) to the aged Zakariyya.\n• The miraculous birth of Isa (Jesus) to the virgin Maryam.\n• The stories of Ibrahim and his father, Musa, Isma\'il, and Idris.\n• The nature of Isa as a prophet and servant of Allah, not the son of God.',
      virtues:
      'This Surah was instrumental in convincing the Negus of Abyssinia to grant asylum to the early Muslim refugees, showing the power of Quranic recitation in conveying truth.',
    ),
    20: SurahInfoData(
      surahId: 20,
      title: 'Ta-Ha',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, this is the Surah whose recitation led Umar ibn al-Khattab to embrace Islam. Tradition holds that Umar, on his way to kill the Prophet ﷺ, heard his sister reciting these verses and was so moved by them that his heart softened and he converted. It focuses on the story of Musa as a source of strength for the Prophet ﷺ.',
      themes:
      '• The detailed story of Musa (Moses): his early life, his mission to Pharaoh, and the crossing of the Red Sea.\n• The story of the golden calf during Musa\'s absence on Mount Sinai.\n• The story of Adam and Eve in the Garden and the enmity of Iblis.\n• Allah\'s direct words to Musa: "And I have chosen you, so listen to what is revealed to you." (20:13)',
      virtues:
      'The famous story of Umar\'s conversion after hearing this Surah makes it one of the most historically significant Surahs in the Quran.',
    ),
    21: SurahInfoData(
      surahId: 21,
      title: 'Al-Anbiya\' (The Prophets)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, this Surah draws together brief accounts of many of Allah\'s prophets, highlighting their shared message of monotheism (Tawhid) and their perseverance in the face of disbelief. It serves as a reminder that the Prophet Muhammad ﷺ is part of a long, noble chain of prophets.',
      themes:
      '• Stories of Ibrahim, Lut, Nuh, Dawud, Sulayman, Ayyub, Yunus, Zakariyya, and Maryam.\n• The universal message of all prophets: "Worship none but Allah."\n• The reality of the Day of Judgment.\n• Mercy to all the worlds (Rahmatan lil-\'Alamin) as the Prophet\'s ﷺ mission.',
      virtues:
      'Contains the verse that defines the Prophet\'s ﷺ entire mission: "And We have not sent you, [O Muhammad], except as a mercy to the worlds." (21:107)',
    ),
    22: SurahInfoData(
      surahId: 22,
      title: 'Al-Hajj (The Pilgrimage)',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'A unique Surah in that it contains characteristics of both Meccan and Medinan revelations, leading scholars to consider it a mixed Surah or fully Medinan. It was revealed around the time the obligation of Hajj was legislated. It describes the rituals of Hajj and their spiritual significance, and contains the first verse permitting Muslims to fight in defense.',
      themes:
      '• The dramatic terror of the Day of Resurrection and the scenes of Judgment.\n• The history and rituals of Hajj, and the significance of the Ka\'bah.\n• The first Quranic permission for defensive warfare.\n• The sacrifice of animals and its spiritual dimensions.',
      virtues:
      'Contains the first verse granting permission to fight in self-defense (22:39), a landmark verse in Islamic history.',
    ),
    23: SurahInfoData(
      surahId: 23,
      title: 'Al-Mu\'minun (The Believers)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, this Surah paints a vivid portrait of the true believer (Mu\'min), their qualities and the reward awaiting them. Ibn Kathir reports that the early Muslims loved to be described by its opening verses. It also recaps the stories of several prophets to show the consistency of the divine message.',
      themes:
      '• The qualities of the successful believers: humility in prayer, avoidance of idle talk, giving Zakat, chastity, and trustworthiness.\n• The stages of human creation (embryology) as a sign of Allah\'s power.\n• Stories of Nuh, Hud, Musa, and Isa as a chain of messengers.\n• The oneness of this Ummah (nation).',
      virtues:
      'Umar ibn al-Khattab reported that when this Surah was revealed, the Prophet ﷺ said: "Ten verses have been revealed to me, and whoever acts upon them will enter Paradise." He then recited the opening verses. (Tirmidhi)',
    ),
    24: SurahInfoData(
      surahId: 24,
      title: 'An-Nur (The Light)',
      revelation: 'Medina',
      period: 'Middle Medinan Period',
      background:
      'Revealed after the incident of the false accusation (Ifk) against Aisha, the Prophet\'s wife, around 5-6 AH. It establishes laws to protect the honor and reputation of individuals, particularly women, and contains many ethical instructions for the Islamic household and community.',
      themes:
      '• The laws against slander (Qathf) and the punishment for false accusation of chastity.\n• The exoneration of Aisha from the false accusation.\n• The famous verse of divine Light (Ayat an-Nur): "Allah is the Light of the heavens and the earth..." (24:35)\n• Rules of modesty, entering homes, and lowering the gaze.',
      virtues:
      'Aisha said: "The first thing to be revealed was a Surah from the Mufassal, mentioning Paradise and Hellfire. Then the halal and haram were revealed. If \'do not drink wine\' had been the first thing revealed, they would have said we will never abandon it." (Bukhari)',
    ),
    25: SurahInfoData(
      surahId: 25,
      title: 'Al-Furqan (The Criterion)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, Al-Furqan (The Criterion) refers to the Quran itself as the standard for distinguishing truth from falsehood. It responds to the objections of the Quraysh who mocked the Prophet ﷺ for being a human messenger, not an angel.',
      themes:
      '• The Quran as the divine criterion between right and wrong.\n• Refuting the claim that a prophet should be an angel or have material wealth.\n• The futility of the idols who can neither help nor harm.\n• A description of the qualities of \'Ibad ar-Rahman (the servants of the Most Merciful).',
      virtues:
      'The Surah ends with one of the most beautiful and comprehensive descriptions of the ideal Muslim — the servants of the Most Merciful (\'Ibad ar-Rahman) — concluding with 25:63-77.',
    ),
    26: SurahInfoData(
      surahId: 26,
      title: 'Ash-Shu\'ara\' (The Poets)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, this Surah tells the stories of seven prophets in succession, all following a similar narrative structure: the prophet conveys the message, his people reject it, and punishment descends. It ends by addressing the accusation that the Quran was composed by a poet, distinguishing prophetic revelation from poetry.',
      themes:
      '• Stories of Musa, Ibrahim, Nuh, Hud, Salih, Lut, and Shu\'ayb — all facing the same pattern of rejection and divine rescue.\n• A defense of the Quran against claims of being mere poetry.\n• The distinction between true prophets and poets or soothsayers.',
      virtues:
      'The structural repetition of Allah\'s might and mercy throughout the stories ("And your Lord is the Exalted in Might, the Merciful") creates a powerful literary rhythm emphasizing divine justice tempered by mercy.',
    ),
    27: SurahInfoData(
      surahId: 27,
      title: 'An-Naml (The Ant)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, An-Naml takes its name from the verse about an ant who warned her colony of the approaching army of Sulayman (Solomon). It focuses on the stories of Musa and, more extensively, Sulayman — his kingdom, his army of jinn and birds, and his encounter with the Queen of Sheba.',
      themes:
      '• Sulayman\'s great kingdom, his understanding of the language of animals, and his wise judgment.\n• The story of the Queen of Sheba (Bilqis) and her conversion to Islam.\n• The story of Salih and the people of Thamud.\n• Signs of the Day of Judgment and the ten major signs (Ashraat as-Sa\'ah).',
      virtues:
      'Contains the verse of prostration (Sajda): "And [He is] the Lord of the East and the West..." (27:26). Also contains Sulayman\'s famous prayer (27:19): "My Lord, enable me to be grateful for Your favor which You have bestowed upon me and upon my parents."',
    ),
    28: SurahInfoData(
      surahId: 28,
      title: 'Al-Qasas (The Story)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed in Mecca, Al-Qasas gives the most detailed account of the story of Musa in the entire Quran, from his birth to his flight from Egypt and his return. It was also revealed to console the Prophet ﷺ as he was forced to leave his beloved Mecca, paralleling Musa\'s forced departure from Egypt.',
      themes:
      '• The most complete narrative of Musa\'s life: his birth, upbringing in Pharaoh\'s palace, his killing of an Egyptian, his flight to Madyan, his marriage, and his return as a prophet.\n• The story of Qarun (Korah), a wealthy Israelite who was destroyed by his arrogance.\n• Consolation to the Prophet ﷺ that Mecca would be restored to him.',
      virtues:
      'Contains the promise of return to the Prophet ﷺ: "Indeed, [He] who imposed upon you the Quran will take you back to a place of return." (28:85) — interpreted by scholars as a prophecy of the Conquest of Mecca.',
    ),
    29: SurahInfoData(
      surahId: 29,
      title: 'Al-\'Ankabut (The Spider)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed in Mecca during a period of intense persecution of the early Muslims. It opens with a declaration that all believers will be tested, and uses the stories of previous prophets to illustrate that trials and tribulations are an inseparable part of the path of faith.',
      themes:
      '• The certainty of trials as a test of faith: "Do people think that they will be left to say, \'We believe,\' and they will not be tested?" (29:2)\n• Stories of Ibrahim, Lut, Nuh, and Shu\'ayb as examples of patience through trials.\n• The weakness of those who rely on other than Allah (like the spider\'s web).\n• The reward of those who strive for Allah\'s sake.',
      virtues:
      'The parable of the spider\'s web (29:41) is one of the most famous metaphors in the Quran, illustrating the fragility of all protection other than Allah\'s.',
    ),
    30: SurahInfoData(
      surahId: 30,
      title: 'Ar-Rum (The Romans)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed when the Persian Sassanids had just defeated the Byzantine (Roman) Christians. The Quraysh, who were polytheists, were pleased as they saw it as a defeat for the "People of the Book." This Surah predicted that the Byzantines would defeat the Persians within 3-9 years — a prophecy that was fulfilled exactly.',
      themes:
      '• The remarkable prophecy of the Byzantine victory over the Persians.\n• Signs of Allah in creation: day and night, creation from dust, sleep, lightning, and the diversity of languages.\n• The natural disposition (Fitrah) that Allah created humans upon.\n• The consequences for the corrupt and the reward for the righteous.',
      virtues:
      'This Surah contains one of the most famous fulfilled prophecies in the Quran (30:2-4), cited by scholars as evidence of the Quran\'s divine origin.',
    ),
    31: SurahInfoData(
      surahId: 31,
      title: 'Luqman',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, this Surah takes its name from Luqman, a wise man (believed by most scholars to not be a prophet) who is mentioned in the Quran for his profound wisdom. It presents his advice to his son as a model of parenting, faith, and morality.',
      themes:
      '• The advice of Luqman to his son: the prohibition of Shirk (associating partners with Allah), gratitude to parents, the knowledge of Allah, establishing prayer, enjoining good and forbidding evil, and humility.\n• The Quran as a guide to wisdom.\n• The five things known only to Allah (the Keys of the Unseen).',
      virtues:
      'Luqman\'s advice (31:13-19) is considered a complete curriculum of moral and spiritual upbringing, frequently cited by Islamic scholars and educators.',
    ),
    32: SurahInfoData(
      surahId: 32,
      title: 'As-Sajdah (The Prostration)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, As-Sajdah addresses the Quraysh\'s denial that the Quran is from Allah. It proves the truth of divine revelation through signs in creation and the stages of human creation, and contrasts the fate of believers and disbelievers.',
      themes:
      '• Proof of the Quran\'s divine origin.\n• The stages of human creation and the certainty of resurrection.\n• The contrast between the fear-filled humble believers and the arrogant wrongdoers.\n• The hideous torment awaiting those who deny the truth.',
      virtues:
      'The Prophet ﷺ would recite As-Sajdah and Al-Insan on the Fajr prayer of Fridays. (Muslim) This Surah is regularly recited in the Fajr prayer of Friday by practicing Muslims.',
    ),
    33: SurahInfoData(
      surahId: 33,
      title: 'Al-Ahzab (The Combined Forces)',
      revelation: 'Medina',
      period: 'Middle Medinan Period',
      background:
      'Revealed in Medina, primarily addressing events surrounding the Battle of the Trench (Ahzab, 5 AH), when the combined forces of Arabia laid siege to Medina. It also addresses significant personal and social matters including the Prophet\'s marriages, the rules concerning his wives (Mothers of the Believers), and the abolition of the practice of Zihar and adoption as a blood relationship.',
      themes:
      '• The miraculous Muslim defense of Medina (the Trench strategy).\n• The exposure and punishment of the hypocrites and the Banu Qurayza tribe.\n• Rules specific to the Prophet\'s household and the status of his wives as Mothers of the Believers.\n• The divine command of Hijab (modest dress) for Muslim women.',
      virtues:
      'Contains the verse of sending blessings upon the Prophet ﷺ: "Indeed, Allah and His angels send blessings upon the Prophet. O you who have believed, ask [Allah to confer] blessing upon him and ask [Allah to grant him] peace." (33:56)',
    ),
    34: SurahInfoData(
      surahId: 34,
      title: 'Saba\' (Sheba)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, this Surah is named after the kingdom of Sheba (present-day Yemen), which was destroyed due to its ingratitude to Allah. It uses this historical example to warn the Quraysh against the same fate and to assert the certainty of Resurrection and Judgment.',
      themes:
      '• The story of the kingdom of Saba\' (Sheba) and the flooding of their garden (\'Arim) as divine punishment for ingratitude.\n• The story of Dawud and Sulayman and their blessings.\n• A refutation of those who denied the resurrection and the afterlife.\n• The truth of prophethood and the futility of wealth and power without faith.',
      virtues:
      'Contains the verse of Dawud\'s and Sulayman\'s gratitude to Allah, presenting them as models of grateful, powerful leadership.',
    ),
    35: SurahInfoData(
      surahId: 35,
      title: 'Fatir (The Originator)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Also known as "Al-Mala\'ikah" (The Angels), this Surah was revealed in Mecca. It emphasizes Allah\'s unique power as the creator of everything, contrasting it with the complete powerlessness of idols. It draws attention to the diversity in creation as signs of the one Creator.',
      themes:
      '• Allah as the sole Creator and Originator (Fatir) of the heavens and earth.\n• The angels as messengers with multiple wings.\n• The diversity of creation — colors, mountains, humans, animals — as signs of Allah.\n• Three categories of people regarding the Quran: those who wrong themselves, the lukewarm, and those who outdo in good deeds.',
      virtues:
      'Contains the inspiring verse about the inheritance of the Quran: "Then We caused to inherit the Book those We have chosen of Our servants; and among them is he who wrongs himself, and among them is he who is moderate, and among them is he who is foremost in good deeds." (35:32)',
    ),
    36: SurahInfoData(
      surahId: 36,
      title: 'Ya-Sin',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Often referred to as the "Heart of the Quran," Ya-Sin was revealed in Mecca. It forcefully establishes the core tenets of Islamic belief: the Prophethood of Muhammad ﷺ, the truth of the Quran, and the certainty of Resurrection and the Afterlife. It was revealed to strengthen the resolve of the Prophet and the early believers against Quraysh mockers.',
      themes:
      '• Proofs of Allah\'s creation and His power to resurrect the dead.\n• The narrative of the "People of the City" and the messengers sent to them.\n• Clear warnings to the disbelievers and glad tidings to the believers regarding the Day of Judgment.',
      virtues:
      'The Prophet ﷺ said, "Everything has a heart, and the heart of the Quran is Ya-Sin; whoever reads it, it is as if he has read the Quran ten times." (Tirmidhi)',
    ),
    37: SurahInfoData(
      surahId: 37,
      title: 'As-Saffat (Those Ranged in Ranks)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, As-Saffat begins with a vivid oath by the angels arrayed in ranks, who glorify Allah and guard against evil. It powerfully affirms the Oneness of Allah and refutes the pagan belief that the angels were daughters of Allah.',
      themes:
      '• The angels arrayed in ranks as witnesses to divine majesty.\n• Refutation of the claim that the angels are daughters of Allah.\n• Stories of Ibrahim, Isma\'il (the sacrifice), Musa, Ilyas, and Yunus.\n• Vivid descriptions of the bliss of Paradise and the torment of Hell.',
      virtues:
      'Contains the story of Ibrahim\'s willingness to sacrifice his son Isma\'il — a defining narrative of submission and faith, celebrated annually at Eid al-Adha.',
    ),
    38: SurahInfoData(
      surahId: 38,
      title: 'Sad',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in the middle Meccan period, Surah Sad was revealed when the Quraysh chiefs boycotted and mocked the Prophet ﷺ. It uses the stories of Dawud (David) and Sulayman (Solomon) — two prophets who were also kings — to illustrate that power, glory, and beauty all belong to Allah alone.',
      themes:
      '• The story of Dawud: his wisdom in judgment, his temporary error, his repentance and forgiveness.\n• The story of Sulayman: his command over jinn, wind, and horses.\n• The story of Ayyub (Job) and his patience in extreme suffering.\n• The story of Iblis\'s rebellion and his vow to mislead humanity.',
      virtues:
      'Contains a verse of Sajdah (prostration) in verse 38:24 when recounting Dawud\'s repentance, making it one of the obligatory prostration verses for the reciter.',
    ),
    39: SurahInfoData(
      surahId: 39,
      title: 'Az-Zumar (The Groups)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed in Mecca, Az-Zumar takes its name from the verse describing how people will be led to Hell and then Paradise in "groups" on the Day of Judgment. It is a Surah of powerful contrasts: sincere vs. hypocritical worship, the grateful vs. the ungrateful, and the fate of believers vs. disbelievers.',
      themes:
      '• The command to worship Allah sincerely (Ikhlas) and alone.\n• The hypocrisy of worshipping Allah and others simultaneously.\n• The expansiveness of Allah\'s mercy and His call to repent.\n• Vivid scenes of the Day of Judgment: the blowing of the trumpet, the grouping of mankind.',
      virtues:
      'Contains the famous verse on divine mercy: "Say, \'O My servants who have transgressed against themselves [by sinning], do not despair of the mercy of Allah. Indeed, Allah forgives all sins.\'" (39:53)',
    ),
    40: SurahInfoData(
      surahId: 40,
      title: 'Ghafir (The Forgiver)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Also known as Al-Mu\'min (The Believer), this is the first of the "Ha-Mim" series of Surahs (40-46), all beginning with the letters Ha-Mim. It tells the story of a believing man from Pharaoh\'s household who secretly believed in Musa and stood up to defend him, risking his life.',
      themes:
      '• The story of the believer from Pharaoh\'s family who secretly defended Musa.\n• The power of du\'a (supplication) and Allah\'s promise to answer it.\n• The arrogance of Pharaoh and the futility of worldly power against divine truth.\n• Scenes of the Day of Judgment and the intercession of the angels.',
      virtues:
      'Contains the profound verse: "And your Lord says: \'Call upon Me; I will respond to you.\'" (40:60) — the primary Quranic basis for the obligation and power of du\'a.',
    ),
    41: SurahInfoData(
      surahId: 41,
      title: 'Fussilat (Explained in Detail)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Part of the Ha-Mim series, Fussilat (meaning "detailed") refers to the Quran itself, whose verses have been made clear and detailed. A notable story in its background is that when Abu Jahl heard the Prophet ﷺ reciting it, he was so affected that he asked him to stop, but then secretly listened at night.',
      themes:
      '• The Quran as a detailed, clear book — a source of healing and mercy for believers.\n• The fate of \'Ad and Thamud who rejected their messengers.\n• The fact that a person\'s own limbs will testify against them on the Day of Judgment.\n• The angels descending upon the believers at death with words of comfort.',
      virtues:
      'Contains the verse of steadfastness: "Indeed, those who say: \'Our Lord is Allah,\' then remain firm — the angels will descend upon them." (41:30)',
    ),
    42: SurahInfoData(
      surahId: 42,
      title: 'Ash-Shura (The Consultation)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Part of the Ha-Mim series, Ash-Shura emphasizes the concept of Shura (consultation) as a fundamental principle of Islamic governance and community life. It highlights the unity of all divine religions and the common message brought by all prophets.',
      themes:
      '• The concept of consultation (Shura) as a principle of governance.\n• The unity of divine religion through all prophets from Nuh to Muhammad ﷺ.\n• The three modes by which Allah speaks to His prophets: directly, from behind a veil, or through an angel.\n• Forgiveness, patience, and reliance on Allah in the face of oppression.',
      virtues:
      'Contains the verse: "And those who, when tyranny strikes them, they defend themselves." (42:39) — establishing the right to defend one\'s rights while preferring forgiveness.',
    ),
    43: SurahInfoData(
      surahId: 43,
      title: 'Az-Zukhruf (The Ornaments of Gold)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Part of the Ha-Mim series, Az-Zukhruf refutes the Quraysh\'s claim that if the Quran were truly from Allah, it would have been revealed to a great man of wealth. It also corrects their false beliefs about the angels being daughters of Allah and the concept of angelic intercession.',
      themes:
      '• Refutation of the pagan glorification of wealth ("ornaments of gold") as the measure of honor.\n• The idolatry of the Quraysh as inherited from their forefathers.\n• The story of Ibrahim\' refuting his father\'s paganism.\n• The story of Musa and Pharaoh, and the story of Isa — and the claim that he is not divine.',
      virtues:
      'Contains the remarkable verse about Isa: "And indeed, Jesus will be [a sign for] knowledge of the Hour, so be not in doubt of it." (43:61) — indicating his return before the Day of Judgment.',
    ),
    44: SurahInfoData(
      surahId: 44,
      title: 'Ad-Dukhan (The Smoke)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Part of the Ha-Mim series, Ad-Dukhan refers to a smoke (Dukhan) that will appear as one of the signs of the Day of Judgment, causing widespread suffering. It was revealed during a period of severe drought (or potential punishment) and uses the history of Pharaoh and his people as a warning.',
      themes:
      '• The revelation of the Quran on the blessed night (Laylat al-Qadr).\n• The smoke (Dukhan) as a major sign of the approaching Day of Judgment.\n• The story of Musa, Pharaoh, and the Israelites.\n• The bliss of Paradise and the horrors of Hell.',
      virtues:
      'The Prophet ﷺ said: "Whoever recites Ha-Mim Ad-Dukhan on the night of Friday, seventy thousand angels will seek forgiveness for him." (Tirmidhi)',
    ),
    45: SurahInfoData(
      surahId: 45,
      title: 'Al-Jathiyah (The Kneeling)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Part of the Ha-Mim series, Al-Jathiyah (meaning "kneeling") refers to the scene on the Day of Judgment when every nation will be on its knees before Allah. The Surah addresses those who follow their desires and deny the signs of Allah scattered throughout the universe.',
      themes:
      '• Signs of Allah in creation: the sky, the earth, animals, winds, and rain.\n• The arrogance of those who follow their own desires (Hawa) over divine guidance.\n• The Bani Isra\'il and their blessings and subsequent ingratitude.\n• The terrifying scene of every nation kneeling before Allah on the Day of Judgment.',
      virtues:
      'Contains the warning to those who take desires as their god (45:23) — one of the most powerful verses about the danger of following whims over divine guidance.',
    ),
    46: SurahInfoData(
      surahId: 46,
      title: 'Al-Ahqaf (The Wind-Curved Sandhills)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'The last of the Ha-Mim series, Al-Ahqaf is named after the sand dunes of the region inhabited by the \'Ad people, who were destroyed for their arrogance. It also recounts the story of a group of Jinn who listened to the Quran and converted to Islam.',
      themes:
      '• The story of the \'Ad and their destruction by a wind (the Ahqaf region).\n• The group of Jinn who heard the Quran and believed, then returned to call their people to Islam.\n• The command to treat parents with kindness and the prayer for righteous offspring.\n• Consolation to the Prophet ﷺ that all prophets before him faced similar rejection.',
      virtues:
      'Contains the beloved prayer taught to the believer: "My Lord, enable me to be grateful for Your favor which You have bestowed upon me and upon my parents and to do righteousness of which You approve and make righteous for me my offspring." (46:15)',
    ),
    47: SurahInfoData(
      surahId: 47,
      title: 'Muhammad',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'Revealed in Medina shortly after the Hijrah, this Surah addresses the newly obligated rules of warfare. It was revealed at a critical time when the Muslims needed clear guidance on how to conduct themselves in armed conflict, including rules for prisoners of war.',
      themes:
      '• The nullification of the deeds of those who disbelieve in the Quran.\n• Rules of warfare: fighting, taking prisoners, and releasing them (by grace or ransom).\n• A warning to the hypocrites who opposed the call to Jihad.\n• The rivers of Paradise as a motivating incentive for the believers.',
      virtues:
      'Also called "Surah Al-Qital" (The Fighting), it is the primary Surah on the ethics and rules of armed conflict in Islam.',
    ),
    48: SurahInfoData(
      surahId: 48,
      title: 'Al-Fath (The Victory)',
      revelation: 'Medina',
      period: 'Middle Medinan Period',
      background:
      'Revealed after the Treaty of Hudaybiyyah (6 AH), which initially appeared to be a compromise but was declared by Allah as a "clear victory." The Prophet ﷺ and his companions had attempted to perform Umrah but were turned back by the Quraysh; this treaty, though initially seeming like a setback, opened the door to the conquest of Mecca.',
      themes:
      '• The Treaty of Hudaybiyyah as a manifest victory from Allah.\n• The pledge of allegiance (Bay\'at ar-Ridwan) under the tree and Allah\'s pleasure with those who gave it.\n• The promise of future victories and the Conquest of Mecca.\n• The description of the Prophet ﷺ and his companions in the Torah and Gospel.',
      virtues:
      'The Prophet ﷺ said: "A Surah has been revealed to me tonight that is dearer to me than all that the sun rises upon." He then recited Surah Al-Fath. (Bukhari)',
    ),
    49: SurahInfoData(
      surahId: 49,
      title: 'Al-Hujurat (The Rooms)',
      revelation: 'Medina',
      period: 'Late Medinan Period',
      background:
      'Revealed in the final years of the Prophet\'s life in Medina, Al-Hujurat (named after the rooms of the Prophet\'s wives adjacent to the mosque) establishes the etiquette of the Islamic community. It was revealed in response to various incidents involving improper behavior by some companions.',
      themes:
      '• Etiquette with the Prophet ﷺ: not raising one\'s voice above his, not calling out to him from behind rooms.\n• The obligation to verify news before acting on it.\n• The prohibition of mockery, backbiting, and calling others by offensive nicknames.\n• The true meaning of brotherhood in Islam: "The believers are but brothers." (49:10)',
      virtues:
      'Often called the "Surah of Manners" (Surah al-Adab), it is foundational for Islamic ethics and social behavior, containing some of the most practical guidelines for Muslim community life.',
    ),
    50: SurahInfoData(
      surahId: 50,
      title: 'Qaf',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, Qaf was reportedly recited by the Prophet ﷺ every Friday during the Khutbah (sermon). It is a Surah of powerful impact, dealing with resurrection, the recording of deeds, and the scenes of the Day of Judgment.',
      themes:
      '• Proof of resurrection: creation itself is evidence of Allah\'s power to recreate.\n• The recording of every deed by two angels.\n• The scenes of death, the blowing of the trumpet, and the gathering on the Day of Judgment.\n• Paradise and Hellfire and the command of their filling.',
      virtues:
      'Umm Hisham bint Harithah reported: "I only memorized Surah Qaf from the mouth of the Messenger of Allah ﷺ, for he used to recite it every Friday from the pulpit." (Muslim)',
    ),
    51: SurahInfoData(
      surahId: 51,
      title: 'Adh-Dhariyat (The Winnowing Winds)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, Adh-Dhariyat opens with oaths by various natural phenomena — the winds, the clouds, the ships, and the angels — building to the central declaration of the absolute truth of Judgment Day. It emphasizes the purpose of creation and human existence.',
      themes:
      '• Oaths by natural forces pointing to divine power.\n• The story of Ibrahim\'s guests (angels who came to announce Ishaq and destroy Lut\'s people).\n• The stories of Fir\'awn (Pharaoh) and the \'Ad and Thamud.\n• The fundamental purpose of creation: "And I did not create the jinn and mankind except to worship Me." (51:56)',
      virtues:
      'Contains the most fundamental statement of human purpose in the Quran (51:56), making it essential for understanding Islamic theology and the meaning of life.',
    ),
    52: SurahInfoData(
      surahId: 52,
      title: 'At-Tur (The Mount)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, At-Tur begins with a series of powerful oaths — by the mountain, the written book, the frequented house (Bayt al-Ma\'mur), the roof (the sky), the sea — all bearing witness to the certainty of divine punishment for the deniers.',
      themes:
      '• Powerful oaths affirming the certainty of divine punishment.\n• A vivid description of the terrors of the Day of Judgment.\n• Descriptions of the bliss of Paradise.\n• Refutation of the accusations against the Prophet ﷺ (that he is a poet, a soothsayer, or mad).',
      virtues:
      'Jubayr ibn Mut\'im reported that he heard the Prophet ﷺ recite At-Tur during the Maghrib prayer. He said: "When he reached the verses \'Were they created by nothing, or were they the creators? Or did they create the heavens and earth?\' (52:35-36), my heart almost flew out." (Bukhari)',
    ),
    53: SurahInfoData(
      surahId: 53,
      title: 'An-Najm (The Star)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the earliest Surahs revealed in Mecca, An-Najm begins with an oath by a star. When the Prophet ﷺ recited this Surah, he prostrated at the end and all who were present — Muslims and polytheists alike — prostrated with him, overcome by its power. It directly addresses the claims that the Prophet ﷺ spoke from personal desire.',
      themes:
      '• Confirmation that the Prophet ﷺ does not speak from personal whim — the Quran is divine revelation.\n• The description of the Prophet\'s night journey (Mi\'raj) and his sighting of Jibril.\n• Refutation of the pagan idols Al-Lat, Al-Uzza, and Manat.\n• The truth that everything belongs to Allah alone.',
      virtues:
      'This is the Surah whose recitation caused the historic first mass prostration, witnessed by both believers and non-believers in Mecca.',
    ),
    54: SurahInfoData(
      surahId: 54,
      title: 'Al-Qamar (The Moon)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, Al-Qamar begins with a reference to the splitting of the moon (Shaqq al-Qamar), one of the miracles performed by the Prophet ﷺ. Despite witnessing this, the Quraysh dismissed it as "magic." The Surah then recounts the fates of peoples who rejected their prophets.',
      themes:
      '• The splitting of the moon as a sign and the disbelievers\' rejection of it.\n• Stories of Nuh, \'Ad, Thamud, Lut, and Pharaoh — all destroyed for rejection.\n• A recurring refrain: "And We have certainly made the Quran easy for remembrance, so is there any who will remember?" (54:17, 22, 32, 40).\n• The Day of Judgment and the reward of the righteous.',
      virtues:
      'The Prophet ﷺ used to recite this Surah along with Surah Qaf in the Friday prayer or the Eid prayer. Its repeated refrain inviting remembrance is considered one of the most powerful motivators for Quran memorization.',
    ),
    55: SurahInfoData(
      surahId: 55,
      title: 'Ar-Rahman (The Most Merciful)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Named after one of Allah\'s greatest names — Ar-Rahman (The Most Merciful) — this Surah celebrates the blessings of Allah with unparalleled beauty. It is the only Surah in the Quran that directly addresses both jinn and mankind, and its famous refrain "So which of the favors of your Lord will you deny?" appears 31 times.',
      themes:
      '• The blessings of creation: the Quran, human creation, the balance (Mizan), the earth, the sea, the heavens.\n• The twin paradises described with immense beauty and detail.\n• A direct and repeated call to jinn and mankind to acknowledge divine favor.\n• The majesty of Allah\'s face that endures when all else perishes.',
      virtues:
      'The Prophet ﷺ said: "Everything has a bride, and the bride of the Quran is Ar-Rahman." (Bayhaqi) It is called the "Bride of the Quran" for its unmatched beauty and lyricism.',
    ),
    56: SurahInfoData(
      surahId: 56,
      title: 'Al-Waqi\'ah (The Inevitable)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, Al-Waqi\'ah (The Inevitable Event) deals powerfully with the reality of the Day of Resurrection and divides humanity into three groups: the forerunners, the companions of the right, and the companions of the left. The Prophet ﷺ is reported to have recited it in the Fajr prayer.',
      themes:
      '• The three groups of humanity on the Day of Judgment: the Forerunners (as-Sabiqun), the Companions of the Right (Ashab al-Yamin), and the Companions of the Left (Ashab ash-Shimal).\n• Vivid descriptions of Paradise for the Forerunners and Companions of the Right.\n• Vivid descriptions of Hell for the Companions of the Left.\n• Proofs of resurrection from creation.',
      virtues:
      'The Prophet ﷺ said: "Whoever recites Surah Al-Waqi\'ah every night will never be afflicted by poverty." (Bayhaqi) Ibn Mas\'ud recited it every night.',
    ),
    57: SurahInfoData(
      surahId: 57,
      title: 'Al-Hadid (The Iron)',
      revelation: 'Medina',
      period: 'Middle Medinan Period',
      background:
      'Revealed in Medina, Al-Hadid calls on the believers to spend in the way of Allah and not to be stingy with their wealth. It draws a stark contrast between the light of the believers and the darkness of the hypocrites on the Day of Judgment. The mention of iron (Hadid) — sent down by Allah for strength and benefit — symbolizes the power of divine blessing.',
      themes:
      '• The absolute sovereignty and omniscience of Allah.\n• The call to spend in the way of Allah and the promise of manifold reward.\n• The contrast between the light of believers and the darkness of hypocrites on the Day of Resurrection.\n• The mention of iron as a blessing sent down from above.\n• The world as a fleeting play and decoration.',
      virtues:
      'Contains one of the most poetic descriptions of the worldly life: "Know that the life of this world is but amusement and diversion and adornment and boasting..." (57:20)',
    ),
    58: SurahInfoData(
      surahId: 58,
      title: 'Al-Mujadila (The Pleading Woman)',
      revelation: 'Medina',
      period: 'Middle Medinan Period',
      background:
      'Revealed in Medina in response to the complaint of Khawlah bint Tha\'labah, who came to the Prophet ﷺ after her husband divorced her through the pre-Islamic practice of Zihar (declaring her as forbidden as his mother\'s back). Allah responded to her plea and abolished this unjust practice.',
      themes:
      '• Abolition of Zihar (a pre-Islamic form of unjust divorce) and its expiation.\n• The prohibition of secret conspiracies (Najwa) against the believers.\n• The etiquette of gatherings and making room for one another.\n• A description of the hypocrites who allied with the enemies of Islam and the punishment awaiting them.',
      virtues:
      'Aisha said: "Blessed is Allah who hears all things. I was in the room when Khawlah pleaded with the Prophet ﷺ about her husband, and some of her words escaped me, and Allah revealed: \'Indeed Allah has heard the speech of the one who argues with you...\'." (Ahmad)',
    ),
    59: SurahInfoData(
      surahId: 59,
      title: 'Al-Hashr (The Exile)',
      revelation: 'Medina',
      period: 'Middle Medinan Period',
      background:
      'Revealed in Medina after the expulsion of the Banu Nadir Jewish tribe (4 AH), who had betrayed their treaty with the Prophet ﷺ and conspired to assassinate him. The Surah describes their humiliating exile from Medina and ends with the celebrated names of Allah.',
      themes:
      '• The expulsion of the Banu Nadir and the lessons therein.\n• The distribution of the Fay\' (spoils gained without fighting).\n• The qualities of the true believers (Muhajirun and Ansar).\n• Concludes with some of the most majestic verses describing the Names and Attributes of Allah.',
      virtues:
      'The last three verses (59:22-24) contain some of the most beautiful Names and Attributes of Allah in the Quran. The Prophet ﷺ recommended reciting them in the morning and evening.',
    ),
    60: SurahInfoData(
      surahId: 60,
      title: 'Al-Mumtahanah (She Who Is Examined)',
      revelation: 'Medina',
      period: 'Late Medinan Period',
      background:
      'Revealed after the Treaty of Hudaybiyyah, Al-Mumtahanah addresses the case of Muslim women migrating from Mecca to Medina. It deals with the question of whether Muslim women married to polytheist husbands could remain with them, and establishes the rules for examining (testing) them.',
      themes:
      '• The prohibition of allying with the enemies of Allah and Islam, even if they are relatives.\n• Ibrahim as a model: his complete disavowal of his people\'s paganism.\n• The procedure for examining Muslim women who migrated (the Bai\'ah).\n• The rule that Muslim women cannot return to their disbelieving husbands and that polytheist men are not lawful for believing women.',
      virtues:
      'Establishes the profound principle of loyalty and disavowal (Al-Wala\' wal-Bara\') in Islam, and contains the only detailed account of the women\'s oath of allegiance (Bay\'at an-Nisa\').',
    ),
    61: SurahInfoData(
      surahId: 61,
      title: 'As-Saf (The Ranks)',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'Revealed in Medina, As-Saf was revealed in response to some companions who had promised to be the most obedient if they were told what deeds Allah loved most, but then fell short. It emphasizes that Allah loves those who fight in His cause as though they are a solid structure.',
      themes:
      '• The importance of consistency: saying what one does.\n• The prophecy of Jesus (Isa) about the coming of the Prophet Muhammad ﷺ (Ahmad).\n• The command to believe and strive in the way of Allah.\n• The glad tidings of victory in this world and the next for those who give precedence to Allah\'s religion.',
      virtues:
      'Contains the prophecy of Isa (Jesus) about the coming of Ahmad (another name of Prophet Muhammad ﷺ): "And [mention] when Jesus, the son of Mary, said, \'O children of Israel, indeed I am the messenger of Allah to you...and bringing good tidings of a messenger to come after me, whose name is Ahmad.\'" (61:6)',
    ),
    62: SurahInfoData(
      surahId: 62,
      title: 'Al-Jumu\'ah (Friday)',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'Revealed in Medina, Al-Jumu\'ah (Friday) establishes the obligation of the Friday prayer (Salat al-Jumu\'ah). It was revealed after an incident where a trade caravan arrived during the Friday Khutbah, causing most of the congregation to rush out to it, leaving the Prophet ﷺ almost alone.',
      themes:
      '• The divine blessing of sending the Prophet ﷺ to the unlettered Arabs.\n• Criticism of the Jews who were given the Torah but did not act on it (like a donkey carrying books).\n• The obligation of Friday prayer and the prohibition of engaging in trade at the time of the Friday call to prayer.',
      virtues:
      'Contains the divine command for Friday prayer: "O you who have believed, when [the adhan] is called for the prayer on the day of Jumu\'ah [Friday], then proceed to the remembrance of Allah and leave trade." (62:9)',
    ),
    63: SurahInfoData(
      surahId: 63,
      title: 'Al-Munafiqun (The Hypocrites)',
      revelation: 'Medina',
      period: 'Middle Medinan Period',
      background:
      'Revealed in Medina after a specific incident during the campaign to Banu al-Mustaliq (5 AH), when the hypocrite leader Abdullah ibn Ubayy insulted the Ansar and the Muhajirun, saying "when we return to Medina, the more honorable will expel the humbler." His son, a true believer, reported this and the Surah exposed the hypocrites.',
      themes:
      '• The nature of hypocrisy: verbal profession of faith concealing disbelief in the heart.\n• The recognizable signs of hypocrites: lying, taking oaths as a shield, and barring from the path of Allah.\n• The hardening of the hearts of the hypocrites.\n• A call to spend in the way of Allah before death arrives.',
      virtues:
      'This Surah is the primary Quranic text for understanding hypocrisy (Nifaq) and the characteristics of the hypocrites, and is essential for social and spiritual self-examination.',
    ),
    64: SurahInfoData(
      surahId: 64,
      title: 'At-Taghabun (The Mutual Disillusion)',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'Revealed in Medina, At-Taghabun deals with the theme of mutual loss and gain — who truly gains and who loses — on the Day of Judgment. It also deals with the concept that one\'s family can be either an ally or an enemy in terms of distracting from the path of Allah.',
      themes:
      '• The certainty of resurrection and the scene of mutual disillusion on Judgment Day.\n• Trials as a divine test: "Your wealth and your children are but a trial." (64:15)\n• Warning that some spouses and children can be enemies to your faith.\n• The command to fear Allah, obey Him, and spend in His cause.',
      virtues:
      'Contains the important reminder: "So fear Allah as much as you are able and listen and obey and spend [in the way of Allah]; it is better for your souls." (64:16)',
    ),
    65: SurahInfoData(
      surahId: 65,
      title: 'At-Talaq (Divorce)',
      revelation: 'Medina',
      period: 'Late Medinan Period',
      background:
      'Revealed after a specific incident where Ibn Umar divorced his wife during her menstrual period, which violated the proper procedure. The Prophet ﷺ commanded him to take her back, and this Surah was revealed to clarify the laws of divorce, \'iddah (waiting period), and maintenance.',
      themes:
      '• Detailed laws of Talaq (divorce) and the proper waiting period (\'Iddah).\n• The rights of divorced women regarding accommodation and maintenance.\n• The command to maintain witnesses for divorce and taking back.\n• The reminder that those who disobey Allah\'s laws will face severe consequences.',
      virtues:
      'One of the most important Surahs in Islamic family law, establishing the ethical and legal framework for ending a marriage with justice and fairness.',
    ),
    66: SurahInfoData(
      surahId: 66,
      title: 'At-Tahrim (The Prohibition)',
      revelation: 'Medina',
      period: 'Middle Medinan Period',
      background:
      'Revealed in response to an incident in the Prophet\'s household, where he prohibited himself from something lawful (believed by many scholars to be honey) to please one of his wives, and a secret was disclosed. It addresses the Prophet ﷺ directly and commands him not to make unlawful what Allah has made lawful.',
      themes:
      '• The prohibition against making unlawful what Allah has made lawful out of marital appeasement.\n• A rebuke to the Prophet\'s wives who conspired against him.\n• The obligation of sincere repentance (Tawbah Nasuhah).\n• Contrasting examples of righteous women (Asiyah and Maryam) and disbelieving women (wives of Nuh and Lut) as lessons for all believers.',
      virtues:
      'Contains the call to Tawbah Nasuhah (sincere, pure repentance) (66:8), one of the most important concepts in Islamic spiritual practice.',
    ),
    67: SurahInfoData(
      surahId: 67,
      title: 'Al-Mulk (The Sovereignty)',
      revelation: 'Mecca',
      period: 'Middle Meccan Period',
      background:
      'Revealed in Mecca, Al-Mulk focuses entirely on the absolute sovereignty and majesty of Allah. It draws the reader\'s attention to the perfection of the universe as undeniable proof of a Creator. It issues a stark warning about the Hellfire while promising immense reward to those who fear their Lord unseen.',
      themes:
      '• The perfection of the heavens and the earth.\n• The purpose of life and death as a test of deeds.\n• The terrifying reality of Hell for those who reject the truth.\n• Allah\'s encompassing knowledge of all things, hidden or apparent.',
      virtues:
      'The Prophet ﷺ said: "There is a Surah in the Quran consisting of thirty verses which intercedes for a man until he is forgiven. It is \'Blessed is He in whose hand is the dominion\' (Surah Al-Mulk)." (Abu Dawud)',
    ),
    68: SurahInfoData(
      surahId: 68,
      title: 'Al-Qalam (The Pen)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the earliest Surahs revealed, Al-Qalam was revealed to defend the Prophet ﷺ against the Quraysh\'s claim that he was mad (majnun). It begins with an oath by the pen — emphasizing the power of writing and knowledge — and proclaims the Prophet\'s noble character.',
      themes:
      '• An oath by the pen and what it inscribes — affirming the value of knowledge.\n• A defense of the Prophet\'s ﷺ noble character (Khuluq Azim).\n• The parable of the owners of the garden who were greedy and were punished.\n• A warning to those who oppose the Quran.',
      virtues:
      'Contains the description of the Prophet ﷺ as having "a magnificent character" (68:4) — the Quranic basis for studying the Prophet\'s character (Seerah and Shama\'il).',
    ),
    69: SurahInfoData(
      surahId: 69,
      title: 'Al-Haqqah (The Inevitable Reality)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, Al-Haqqah describes the Day of Judgment as "the Inevitable Reality" — a certainty that no one can escape. It opens by asking three times "What is the Inevitable Reality?", creating a sense of suspense and awe.',
      themes:
      '• The Inevitable Reality (Haqqah) as a name for the Day of Judgment.\n• The fates of \'Ad, Thamud, Pharaoh, and Lut — destroyed by various divine punishments.\n• The blowing of the trumpet and the great cataclysm.\n• The book of deeds given to the right hand (believers) and the left or behind the back (disbelievers).',
      virtues:
      'Ali ibn Abi Talib reported that the Prophet ﷺ loved this Surah greatly, and that it presents the Day of Judgment with a unique combination of terror and detailed description.',
    ),
    70: SurahInfoData(
      surahId: 70,
      title: 'Al-Ma\'arij (The Ascending Stairways)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca, Al-Ma\'arij opens with a pagan\'s challenge asking for divine punishment to be hastened. It addresses the nature of time and punishment — a day with Allah is like fifty thousand years — and describes the character of the human being when afflicted or blessed.',
      themes:
      '• The nature of the Day of Judgment: a day equal to fifty thousand years.\n• The human being\'s natural impatience and ingratitude.\n• The qualities of the righteous believers (constant in prayer, givers of Zakat, truthful, chaste).\n• The terror of the Day and the humiliation of those who disbelieved.',
      virtues:
      'Contains one of the Quran\'s most detailed descriptions of the believers\' qualities in opposition to human weakness (70:19-35), serving as a practical spiritual checklist.',
    ),
    71: SurahInfoData(
      surahId: 71,
      title: 'Nuh (Noah)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca to console the Prophet ﷺ, who was experiencing persistent rejection from the Quraysh. It recounts the entire story of Nuh (Noah), who called his people for 950 years with almost no success, yet never gave up. It serves as a powerful precedent for perseverance in da\'wah.',
      themes:
      '• Nuh\'s 950 years of calling his people to monotheism, day and night, publicly and privately.\n• His people\'s arrogant refusal and insistence on their idols.\n• The flood and the salvation of the believers.\n• Nuh\'s prayer against the disbelievers and his prayer for forgiveness for the believers.',
      virtues:
      'This entire Surah is a meditation on patience in da\'wah (calling to Allah). It teaches that the measure of success is not in numbers but in sincerity and perseverance.',
    ),
    72: SurahInfoData(
      surahId: 72,
      title: 'Al-Jinn',
      revelation: 'Mecca',
      period: 'Early to Middle Meccan Period',
      background:
      'Revealed in Mecca after a group of jinn who had heard the Prophet ﷺ reciting the Quran during the night prayer converted to Islam and returned to call their community. This happened during the Prophet\'s journey to Ta\'if, one of the lowest points of his mission.',
      themes:
      '• The account of the jinn who heard the Quran and believed.\n• The jinn\'s declaration of the Quran\'s guidance and their call to their community.\n• The nature of the jinn: some are righteous and some are not.\n• The fact that the jinn used to eavesdrop on the heavens but were then barred by flames.',
      virtues:
      'The conversion of the jinn, narrated in this Surah and in Al-Ahqaf (46:29-32), is a profound reminder that the Quran\'s guidance extends beyond humanity to the entire world of sentient beings.',
    ),
    73: SurahInfoData(
      surahId: 73,
      title: 'Al-Muzzammil (The Enshrouded One)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the earliest Surahs revealed, Al-Muzzammil was addressed to the Prophet ﷺ when he was wrapping himself in a cloak after the first revelation. It establishes the practice of Qiyam al-Layl (night prayer) as a spiritual foundation for the Prophet and the early believers, preparing them for the heavy responsibility of the Quran.',
      themes:
      '• The command to stand in prayer at night (Qiyam al-Layl).\n• The Quran as a "weighty word" (Qawlan Thaqila) requiring spiritual preparation.\n• The importance of reciting the Quran in a measured, careful way (Tartil).\n• Trust and reliance on Allah as the believer\'s anchor.',
      virtues:
      'Establishes the sunnah of Tahajjud (voluntary night prayer), one of the most beloved and spiritually enriching acts of worship in Islam.',
    ),
    74: SurahInfoData(
      surahId: 74,
      title: 'Al-Muddaththir (The Covered One)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Among the very first Surahs revealed, Al-Muddaththir marks the beginning of the Prophet\'s public mission. After the first revelation (the beginning of Al-\'Alaq), the Prophet wrapped himself in a cloak and this Surah commanded him to arise and warn his people. It also addresses al-Walid ibn al-Mughirah, a chief of the Quraysh who listened to the Quran and acknowledged its beauty but denied it out of arrogance.',
      themes:
      '• The divine command to the Prophet ﷺ to arise and warn all of humanity.\n• The command to magnify Allah, purify oneself, and leave all that is filthy.\n• A description of the nineteen guardians of Hellfire (Zabaniyah).\n• The story of the arrogant man (al-Walid) who knew the truth but rejected it.',
      virtues:
      'Marks the beginning of the active prophetic mission. This Surah transformed the Prophet ﷺ from a recipient of private revelation to a public warner to all of mankind.',
    ),
    75: SurahInfoData(
      surahId: 75,
      title: 'Al-Qiyamah (The Resurrection)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca, Al-Qiyamah directly addresses the human soul\'s deep-seated denial of resurrection. It uses oath by the Day of Resurrection itself and the "self-reproaching soul" to argue for the certainty of the afterlife.',
      themes:
      '• An oath by the Day of Resurrection and by the self-reproaching soul (nafs lawwamah).\n• A detailed description of the Last Day and the terror it will bring.\n• Allah\'s guarantee that the collection and recitation of the Quran is His responsibility.\n• The stages of the human being from a humble drop of fluid to the denial of accountability.',
      virtues:
      'Contains the divine promise about the Quran: "Indeed, upon Us is its collection and its recitation." (75:17) — reassuring the Prophet ﷺ about the preservation of revelation.',
    ),
    76: SurahInfoData(
      surahId: 76,
      title: 'Al-Insan (The Human)',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'Also known as Ad-Dahr (Time) and Al-Abrar (The Righteous), this Surah is debated as either Meccan or Medinan. It was traditionally recited by the Prophet ﷺ in the Fajr prayer on Fridays along with As-Sajdah. It deals with the creation of man from nothing and the need for gratitude.',
      themes:
      '• The humble origin of man from a drop of sperm — yet he is given sight and hearing and shown the way.\n• The rewards of the righteous (Al-Abrar) in Paradise: cool drinks, silk, reclining couches.\n• The patience, prayer, and charity of the righteous as the basis of their reward.\n• The absolute sovereignty of Allah\'s will.',
      virtues:
      'The Prophet ﷺ regularly recited this Surah in the Fajr prayer on Fridays (Muslim), making it part of the Sunnah. It is also believed to relate to the story of the Ahlul-Bayt\'s three-day fast for the sake of Allah.',
    ),
    77: SurahInfoData(
      surahId: 77,
      title: 'Al-Mursalat (Those Sent Forth)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, Al-Mursalat opens with a series of oaths by angels (or winds) sent in succession. It was being recited by the Prophet ﷺ in a cave when Jinn passed by and listened, as mentioned in the companion Ibn Mas\'ud\'s account. Its refrain "Woe that Day to the deniers!" is repeated ten times.',
      themes:
      '• Oaths by divine agents that testify to the truth of Judgment.\n• Vivid descriptions of the Day of Judgment and its terrors.\n• Scenes of the bliss of Paradise.\n• The recurring refrain warning the deniers: "Woe, that Day, to the deniers!"',
      virtues:
      'Ibn Mas\'ud reported: "We were with the Prophet ﷺ in a cave when Al-Mursalat was revealed to him. He was reciting it and I was taking it from his mouth when a snake came out at us." (Bukhari) — marking the memorable circumstances of its revelation.',
    ),
    78: SurahInfoData(
      surahId: 78,
      title: 'An-Naba\' (The Tidings)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca, An-Naba\' addresses the "great tidings" (Naba\' Azim) that the Meccans disputed — the Day of Resurrection. It answers their denial with a series of rhetorical questions about the wonders of Allah\'s creation, leading to a powerful affirmation of the Day of Judgment.',
      themes:
      '• The "great tidings" of the Day of Resurrection that the disbelievers dispute.\n• Signs of Allah\'s power in creation: the earth, mountains, sleep, night, day, and rain.\n• Scenes of the Day of Judgment: the blowing of the trumpet and the grouping of mankind.\n• A description of the gardens of Paradise and the torments of Hell.',
      virtues:
      'One of the most widely memorized Surahs from the Mufassal (shorter surahs), frequently recited in prayers for its powerful, rhythmic imagery of the Day of Judgment.',
    ),
    79: SurahInfoData(
      surahId: 79,
      title: 'An-Nazi\'at (Those Who Drag Forth)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca, An-Nazi\'at opens with oaths by different categories of angels — those who pluck souls violently from disbelievers and those who take the souls of believers gently — building to a description of the Day of Judgment and the story of Musa and Pharaoh.',
      themes:
      '• Oaths by types of angels and their roles in taking souls and executing divine commands.\n• The story of Musa and Pharaoh: the divine mission, Pharaoh\'s rejection, and his drowning.\n• The scenes of the Day of Judgment when the "greatest catastrophe" occurs.\n• Two groups: those who feared Allah and those who preferred the worldly life.',
      virtues:
      'The story of Musa and Pharaoh (79:15-26) is one of the most concise yet complete accounts in the Quran, containing the entire drama in just twelve verses.',
    ),
    80: SurahInfoData(
      surahId: 80,
      title: '\'Abasa (He Frowned)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed when the Prophet ﷺ frowned and turned away from a blind man, Abdullah ibn Umm Maktum, who had interrupted his conversation with an important Qurayshi chief. Allah gently corrected the Prophet ﷺ, establishing that no human, however humble, should ever be turned away from seeking knowledge.',
      themes:
      '• A gentle but firm divine rebuke of the Prophet ﷺ for turning away from a sincere seeker.\n• The principle that those who are self-sufficient do not deserve more attention than those who are poor but eager to learn.\n• The stages of human creation and the ingratitude of man.\n• Scenes of the Day of Judgment.',
      virtues:
      'Remarkable for being a direct correction to the Prophet ﷺ, showing that even the best of humanity is held to the highest standards of justice and compassion in Islamic ethics.',
    ),
    81: SurahInfoData(
      surahId: 81,
      title: 'At-Takwir (The Overthrowing)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, At-Takwir (The Folding Up) describes the cataclysmic events of the Day of Judgment in vivid, rapid imagery — the sun being folded, stars falling, mountains swept away — creating an overwhelming sense of the end of the known world.',
      themes:
      '• A rapid series of cosmic catastrophes on the Day of Judgment.\n• The questioning of the female infant buried alive (Maw\'udah) — a condemnation of the pre-Islamic practice of burying infant daughters.\n• An affirmation of the Quran\'s divine origin, communicated through the trustworthy angel Jibril.\n• A warning about the deception of Shaytan.',
      virtues:
      'The Prophet ﷺ said: "Whoever wishes to look at the Day of Resurrection as if he is seeing it with his own eyes, let him read At-Takwir, Al-Infitar, and Al-Inshiqaq." (Tirmidhi)',
    ),
    82: SurahInfoData(
      surahId: 82,
      title: 'Al-Infitar (The Cleaving)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, Al-Infitar describes the breaking open of the sky, the scattering of stars, the emptying of seas, and the overthrowing of graves on the Day of Judgment. It is one of the three Surahs that paints the Day of Judgment in graphic, sensory detail.',
      themes:
      '• The breaking open of the sky and the overturning of the universe.\n• The two noble angels recording every deed.\n• The ingratitude of mankind despite Allah\'s blessings.\n• The absolute justice of the Day of Judgment.',
      virtues:
      'The Prophet ﷺ said: "Whoever wishes to look at the Day of Resurrection as if he is seeing it with his own eyes, let him read At-Takwir, Al-Infitar, and Al-Inshiqaq." (Tirmidhi)',
    ),
    83: SurahInfoData(
      surahId: 83,
      title: 'Al-Mutaffifin (The Defrauders)',
      revelation: 'Mecca',
      period: 'Late Meccan Period',
      background:
      'Revealed toward the end of the Meccan period, Al-Mutaffifin is said to have been among the first Surahs recited publicly in Medina after the Hijrah. It opens with a severe condemnation of those who cheat in weights and measures — a prevalent form of corruption in Meccan commerce.',
      themes:
      '• A condemnation of those who demand full measure for themselves but cheat others.\n• The book of deeds of the wicked (Sijjin) and the righteous (\'Illiyyin).\n• The state of the wicked on the Day of Judgment: cut off from divine mercy.\n• The reward of the righteous: couches of dignity and rivers of pure drink.',
      virtues:
      'This Surah establishes the Islamic principle of commercial and social justice, and extends the concept of "fraud" beyond business to all forms of moral cheating in one\'s dealings.',
    ),
    84: SurahInfoData(
      surahId: 84,
      title: 'Al-Inshiqaq (The Sundering)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, Al-Inshiqaq describes the splitting of the sky on the Day of Judgment and the presentation of every person\'s book of deeds. It contains a verse upon which a Sajdah (prostration) is performed.',
      themes:
      '• The splitting of the sky and the obedience of the heavens and earth to their Lord.\n• The presentation of every soul\'s book: to the right hand for the believers and behind their back for the disbelievers.\n• The journey of the human soul through stages (adwar) toward ultimate meeting with Allah.\n• A warning against those who refuse to prostrate when the Quran is recited to them.',
      virtues:
      'The Prophet ﷺ said: "Whoever wishes to look at the Day of Resurrection as if he is seeing it with his own eyes, let him read At-Takwir, Al-Infitar, and Al-Inshiqaq." (Tirmidhi)',
    ),
    85: SurahInfoData(
      surahId: 85,
      title: 'Al-Buruj (The Mansions of the Stars)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed in Mecca to console the Muslims who were being persecuted, Al-Buruj recounts the story of "the People of the Trench" (Ukhdud), believers who were burned alive in ditches by a tyrant for refusing to abandon their faith. It was a direct parallel to the suffering of the early Muslims.',
      themes:
      '• The story of the People of the Trench — believers martyred for their faith.\n• The absolute knowledge and power of Allah who is watching over His servants.\n• The punishment awaiting the tormentors of believers.\n• The invincibility of the Quran: it is preserved on a guarded tablet.',
      virtues:
      'A Surah of immense spiritual power, comforting persecuted Muslims throughout history by affirming that Allah witnesses every injustice and will bring full recompense.',
    ),
    86: SurahInfoData(
      surahId: 86,
      title: 'At-Tariq (The Morning Star)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the short early Meccan Surahs, At-Tariq begins with a majestic oath by the sky and the piercing star (the morning star), reminding the human being that every soul has an appointed guardian angel watching over it, and that resurrection after death is as certain as creation from humble fluid.',
      themes:
      '• An oath by the sky and the piercing night star, establishing divine authority.\n• The watchful guardian appointed over every human soul.\n• Human creation from a humble fluid — proof of Allah\'s power to resurrect.\n• The Quran as a decisive word, not mere entertainment.',
      virtues:
      'A Surah often recited in Fajr prayer, reminding the worshipper of the constant divine observation (Muraqabah) — the cornerstone of the state of Ihsan.',
    ),
    87: SurahInfoData(
      surahId: 87,
      title: 'Al-A\'la (The Most High)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the earliest Surahs revealed, Al-A\'la was reportedly the first Surah about which the Prophet ﷺ said "Subhana Rabbi al-A\'la" (Glory be to my Lord, the Most High). It was reportedly a favorite Surah of the Prophet ﷺ, who would recite it in the Friday and Eid prayers.',
      themes:
      '• The command to glorify the name of Allah, the Most High.\n• Allah\'s complete wisdom in creating, proportioning, and guiding His creation.\n• The promise that the Prophet ﷺ will not forget the Quran — it will be made easy for him.\n• A reminder that the Hereafter is better and more lasting than this world.',
      virtues:
      'The Prophet ﷺ would recite Al-A\'la in the Witr prayer and in the Friday and Eid prayers (Muslim). It contains one of the first direct commands to the Prophet ﷺ regarding worship.',
    ),
    88: SurahInfoData(
      surahId: 88,
      title: 'Al-Ghashiyah (The Overwhelming)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca, Al-Ghashiyah (The Overwhelming Event) refers to the Day of Judgment that will "overwhelm" all of humanity. It was regularly recited by the Prophet ﷺ in the Friday and Eid prayers, often paired with Al-A\'la.',
      themes:
      '• The humiliated faces of those in Hellfire: exhausted, suffering, in scorching heat.\n• The radiant faces of those in Paradise: joyful, pleased, in lofty gardens.\n• Rhetorical questions inviting reflection: "Do they not look at the camels, the sky, the mountains, the earth?"\n• The limits of the Prophet\'s role — only to remind, not to compel.',
      virtues:
      'The Prophet ﷺ recited Al-A\'la and Al-Ghashiyah together in the Friday prayer (Muslim), making this pair among the most recited Surahs in Islamic tradition.',
    ),
    89: SurahInfoData(
      surahId: 89,
      title: 'Al-Fajr (The Dawn)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca, Al-Fajr opens with a series of oaths by sacred times and phenomena. It recounts the destruction of \'Ad, Thamud, and Pharaoh as warnings to the Quraysh, and then addresses the contradictory nature of human beings who feel abandoned by Allah when tested with hardship but forget Allah when blessed.',
      themes:
      '• Sacred oaths by the Dawn, the ten nights, and alternating phenomena.\n• The destruction of \'Ad (Iram), Thamud, and Pharaoh for their tyranny.\n• The human contradiction: calling Allah when tested, but becoming arrogant when given wealth.\n• The address to the tranquil soul (nafs mutma\'innah) to return to its Lord with honor.',
      virtues:
      'Contains the beautiful address to the soul at peace: "O tranquil soul, return to your Lord, well-pleased and well-pleasing [to Him]. And enter among My [righteous] servants and enter My Paradise." (89:27-30)',
    ),
    90: SurahInfoData(
      surahId: 90,
      title: 'Al-Balad (The City)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, Al-Balad opens with an oath by the sacred city of Mecca (Al-Balad). It emphasizes the difficulty and struggle inherent in human life, and presents the choice between two paths: the steep uphill path of virtue and charity versus the easy downward path of selfishness.',
      themes:
      '• An oath by the sacred city of Mecca and the Prophet\'s noble presence within it.\n• The difficulty of human life is by design — we are created "in hardship."\n• The two paths: the steep path of righteousness (freeing slaves, feeding the hungry, enjoining patience) versus the path of selfishness.\n• The companions of the right hand versus the companions of the left.',
      virtues:
      'Presents the "steep path" (Al-\'Aqabah) as a metaphor for all righteous deeds that require effort and sacrifice, challenging the believer to choose elevation over ease.',
    ),
    91: SurahInfoData(
      surahId: 91,
      title: 'Ash-Shams (The Sun)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, Ash-Shams opens with a remarkable series of eleven oaths — by the sun, the moon, the day, the night, the sky, the earth, and finally by the human soul — all building to the central lesson: the one who purifies the soul succeeds, and the one who corrupts it fails.',
      themes:
      '• Eleven oaths by natural phenomena leading to an oath by the human soul.\n• The two paths given to the soul: wickedness and righteousness.\n• Success for the one who purifies the soul (tazkiyah) and failure for the one who corrupts it.\n• The story of Thamud and the she-camel as a warning against corruption.',
      virtues:
      'Contains the most direct Quranic statement on the soul (Nafs) and Tazkiyah (purification), making it foundational to the Islamic science of spiritual purification.',
    ),
    92: SurahInfoData(
      surahId: 92,
      title: 'Al-Layl (The Night)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, Al-Layl uses the contrast between night and day as a metaphor for the contrast between the generous and the miserly, and the paths they choose. It was reportedly revealed in relation to Abu Bakr As-Siddiq, who freed many slaves.',
      themes:
      '• The contrast between the night and day, male and female, as a reflection of divergent human choices.\n• Two contrasting types of people: those who give generously and fear Allah, and those who are miserly and deny His blessings.\n• The easy path (Al-Yusra) granted to those who give and believe, and the difficult path (Al-\'Usra) for those who withhold.\n• The promise that the generous one will be made satisfied.',
      virtues:
      'It is narrated that this Surah was revealed specifically regarding Abu Bakr\'s generosity in freeing slaves. It is a cornerstone text on the virtue of generosity (Jud) in Islam.',
    ),
    93: SurahInfoData(
      surahId: 93,
      title: 'Ad-Duha (The Morning Brightness)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed during a period of pause (Fatrah) in revelation, when the Prophet ﷺ was distressed and some Quraysh mocked him saying "Your Lord has abandoned you." Allah revealed this Surah to console the Prophet ﷺ, reminding him of His past blessings and His enduring care.',
      themes:
      '• Allah\'s assurance that He has not abandoned the Prophet ﷺ nor is He displeased with him.\n• Reminders of past blessings: finding him an orphan and sheltering him, finding him lost and guiding him, finding him poor and enriching him.\n• Commands flowing from gratitude: not oppressing the orphan, not turning away the beggar, and proclaiming Allah\'s blessings.',
      virtues:
      'The Prophet ﷺ reportedly wept upon its revelation, and Khadijah said she had never seen him cry like that before. It is one of the most comforting Surahs for believers going through hardship.',
    ),
    94: SurahInfoData(
      surahId: 94,
      title: 'Ash-Sharh (The Relief)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Closely linked to Ad-Duha in theme and timing, Ash-Sharh was also revealed as a consolation to the Prophet ﷺ during the hardship of early Mecca. It asks him to reflect on the blessings Allah had already given him: the expansion of his breast, the removal of his burden, and the elevation of his mention.',
      themes:
      '• Rhetorical questions: "Did We not expand your breast?", "Did We not relieve you of your burden?"\n• The elevation of the Prophet\'s mention alongside Allah\'s in the Adhan and Shahadah.\n• The profound promise: "With every hardship comes ease" — repeated twice for emphasis.\n• The command to turn to his Lord as soon as worldly work is complete.',
      virtues:
      'Contains one of the most beloved verses of consolation in Islam: "For indeed, with hardship [will be] ease. Indeed, with hardship [will be] ease." (94:5-6)',
    ),
    95: SurahInfoData(
      surahId: 95,
      title: 'At-Tin (The Fig)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, At-Tin begins with oaths by four sacred symbols — the fig, the olive, Mount Sinai, and the sacred city of Mecca. These are believed to represent the prophets \'Isa, Ibrahim, Musa, and Muhammad ﷺ and the lands associated with them.',
      themes:
      '• Oaths by four sacred symbols representing the blessed lands of the prophets.\n• The creation of human beings in the "best of forms" (Ahsan Taqwim).\n• The tragic reduction of the human to the "lowest of the low" through disbelief and bad deeds.\n• The exception: those who believe and do righteous deeds — their reward is unending.',
      virtues:
      'Contains one of the most uplifting declarations about humanity: "We have certainly created man in the best of forms." (95:4) — the Quranic basis for human dignity and Islamic humanism.',
    ),
    96: SurahInfoData(
      surahId: 96,
      title: 'Al-\'Alaq (The Clot)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'The first five verses of Al-\'Alaq were the very first words of the Quran ever revealed to the Prophet ﷺ in the Cave of Hira, beginning with "Iqra\'" (Read!). This marks the beginning of divine revelation and the Islamic civilization built on knowledge. The remainder of the Surah was revealed later, addressing Abu Jahl\'s arrogant attempts to prevent the Prophet from praying.',
      themes:
      '• The command to read/recite (Iqra\') in the name of Allah.\n• The creation of man from a clinging clot (\'Alaq).\n• Allah as the teacher of knowledge by the pen.\n• Condemnation of arrogance and those who prevent worship.',
      virtues:
      'The most historically significant Surah in Islam — its first five verses constitute the very first divine revelation. It establishes knowledge and learning as the foundation of Islamic civilization.',
    ),
    97: SurahInfoData(
      surahId: 97,
      title: 'Al-Qadr (The Night of Decree)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed in Mecca, Al-Qadr celebrates the Night of Decree (Laylat al-Qadr), the night in Ramadan when the Quran was first sent down to the lowest heaven. It is the most blessed night of the year, better than a thousand months.',
      themes:
      '• The Quran was revealed on the Night of Decree (Laylat al-Qadr).\n• This night is better than a thousand months of worship.\n• The angels and Jibril descend with every decree during this night.\n• The night is peace until the break of dawn.',
      virtues:
      'The Prophet ﷺ said: "Whoever spends the Night of Decree in prayer out of faith and seeking reward will have all his previous sins forgiven." (Bukhari) The entire Surah celebrates this most blessed of nights.',
    ),
    98: SurahInfoData(
      surahId: 98,
      title: 'Al-Bayyinah (The Clear Proof)',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'Revealed in Medina, Al-Bayyinah addresses the response of the People of the Book to the Prophet Muhammad ﷺ. Despite having prophecies about him, many of them refused to believe even after the "clear evidence" (Bayyinah) of the Quran came to them.',
      themes:
      '• The People of the Book and the polytheists remained divided until the clear proof came.\n• The Quran and the purified scriptures were the clear proof.\n• The pure religion is Islam: sincere worship, prayer, and Zakat.\n• The best of creation are those who believe and do good deeds.',
      virtues:
      'Contains the description of the believers as "the best of creation" (khayrul-bariyyah) (98:7), one of the most honored titles given to the companions and the righteous in Islamic theology.',
    ),
    99: SurahInfoData(
      surahId: 99,
      title: 'Az-Zalzalah (The Earthquake)',
      revelation: 'Medina',
      period: 'Early Medinan Period',
      background:
      'Revealed in Medina, Az-Zalzalah describes the earth\'s violent shaking on the Day of Judgment and the testimony of the earth itself regarding what was done upon it. Its final verses deliver one of the most precise and motivating statements about accountability in the entire Quran.',
      themes:
      '• The earth will convulse with its final earthquake on the Day of Judgment.\n• The earth will "throw out" its burdens and "speak" about what was done on it.\n• Every person will see their deeds: "Whoever does an atom\'s weight of good will see it, and whoever does an atom\'s weight of evil will see it."',
      virtues:
      'The Prophet ﷺ said this Surah is worth reciting in equivalent of half the Quran. (Tirmidhi) Its final two verses (99:7-8) are among the most important verses on accountability and the importance of small deeds.',
    ),
    100: SurahInfoData(
      surahId: 100,
      title: 'Al-\'Adiyat (The Courser)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca, Al-\'Adiyat opens with a vivid oath by war horses charging into battle at dawn — their hooves striking sparks, their breath panting, their charge raising dust. This powerful imagery is used to confront human ingratitude.',
      themes:
      '• Oaths by galloping war horses, their sounds and sparks, as witnesses to human endeavor.\n• The ingratitude of the human being toward his Lord.\n• The human\'s intense love for wealth.\n• A reminder that when the graves are overturned and hearts are exposed, nothing will remain hidden.',
      virtues:
      'The strong imagery of war horses at dawn serves as a shock-awakening for the believer, jolting them out of complacency about their ingratitude and attachment to worldly wealth.',
    ),
    101: SurahInfoData(
      surahId: 101,
      title: 'Al-Qari\'ah (The Calamity)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'One of the early Meccan Surahs, Al-Qari\'ah (The Striking Calamity) asks three times "What is the Striking Calamity?" before giving a terrifying description of the Day of Judgment — when people will be like scattered moths and mountains like carded wool.',
      themes:
      '• The terrible striking calamity (Qari\'ah) of the Day of Judgment.\n• Mankind scattered like moths around a lamp, mountains like carded wool.\n• The weighing of deeds: heavy scales lead to a pleasant life, and light scales lead to the crushing pit of Hawiyah (Hell).',
      virtues:
      'A powerful and concise reminder of the Day of Judgment\'s reality, making it one of the most frequently used Surahs to awaken heedlessness.',
    ),
    102: SurahInfoData(
      surahId: 102,
      title: 'At-Takathur (The Rivalry for World Increase)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed in Mecca, At-Takathur addresses the all-consuming competition among humans to accumulate more — wealth, children, status — until death comes. It was reportedly revealed about two clans of Quraysh who competed in boasting about their number of living members, then their dead.',
      themes:
      '• A condemnation of the rivalry in accumulation that distracts from what truly matters.\n• The warning: "Until you visit the graveyards" — only death ends this competition.\n• The certainty of divine knowledge and the questioning about worldly distractions.\n• The reality of Hell as a visual experience for those who are heedless.',
      virtues:
      'The Prophet ﷺ said: "The son of Adam says \'my wealth, my wealth\' — but do you have of your wealth except what you ate and consumed, or what you wore and wore out, or what you gave as charity and sent ahead?" (Muslim)',
    ),
    103: SurahInfoData(
      surahId: 103,
      title: 'Al-\'Asr (The Declining Day)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Despite being only three verses, Al-\'Asr contains a complete philosophy of life according to Imam Shafi\'i, who said: "If people reflected deeply on Surah Al-\'Asr alone, it would be sufficient for them." The oath is by time itself — or the afternoon prayer — and presents the four conditions of human success.',
      themes:
      '• An oath by time — witness to humanity\'s loss.\n• All of humanity is in loss, except those who: believe, do righteous deeds, counsel each other to truth, and counsel each other to patience.\n• Four conditions of salvation: Iman, \'Amal Salih, Tawasi bil-Haqq, Tawasi bis-Sabr.',
      virtues:
      'Imam Shafi\'i said: "If Allah had only revealed this Surah as a proof against His creation, it would have been sufficient." The Companions used to recite it to one another whenever they parted ways. (Tabarani)',
    ),
    104: SurahInfoData(
      surahId: 104,
      title: 'Al-Humazah (The Slanderer)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca, Al-Humazah condemns a type of character — the wealthy slanderer who mocks people with words and gestures, and believes his wealth will protect him forever. It was reportedly revealed about one of the wealthy enemies of the Prophet ﷺ, though its lesson is universal.',
      themes:
      '• Condemnation of every slanderer and backbiter who mocks with words and gestures.\n• The delusion of thinking that wealth grants immortality.\n• The punishment of Hutamah — a fire that pierces hearts and is sealed over those therein.',
      virtues:
      'One of the most powerful Quranic warnings against the sins of the tongue — backbiting, slander, and mockery — especially when combined with arrogance of wealth.',
    ),
    105: SurahInfoData(
      surahId: 105,
      title: 'Al-Fil (The Elephant)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed in Mecca, Al-Fil refers to the miraculous event of the Year of the Elephant (approximately 570 CE, the year of the Prophet\'s birth), when Abraha, the Christian ruler of Yemen, marched with an army including war elephants to destroy the Ka\'bah. Allah destroyed the entire army using flocks of birds carrying stones.',
      themes:
      '• Allah\'s protection of the Ka\'bah from Abraha\'s army.\n• Birds (Ababil) carrying stones of baked clay.\n• The army left like "eaten straw" — a complete and miraculous annihilation.',
      virtues:
      'A historical miracle known to all Arabs that preceded the Prophet\'s birth, establishing the sacredness of Mecca and the Ka\'bah before the Prophet ﷺ was born. Its occurrence in the Year of the Elephant marks the beginning of a new era.',
    ),
    106: SurahInfoData(
      surahId: 106,
      title: 'Quraysh',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed in Mecca, Surah Quraysh is considered by some scholars to be linked with Al-Fil (105) as one Surah. It reminds the Quraysh tribe of Allah\'s blessings upon them: the security of Mecca and their two annual trade caravans, enabled by the miraculous defeat of Abraha\'s army.',
      themes:
      '• Allah\'s favor in making the Quraysh safe for their two journeys (summer to Syria, winter to Yemen).\n• A call to worship the Lord of this house (the Ka\'bah) who provided them with food and security.',
      virtues:
      'A direct call to the most influential tribe of Arabia — the Quraysh — to acknowledge that their prosperity and safety came from Allah alone, not their idols.',
    ),
    107: SurahInfoData(
      surahId: 107,
      title: 'Al-Ma\'un (Small Kindnesses)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed early in Mecca, Al-Ma\'un defines who truly denies the religion (Ad-Din) — not the overtly impious, but those who push away orphans, ignore the needy, and pray only for show. It connects social responsibility directly to faith.',
      themes:
      '• The definition of the one who denies the religion: pushes away the orphan and does not encourage feeding the poor.\n• The condemnation of those who pray but are heedless — those who pray to be seen.\n• The prohibition of withholding even small acts of kindness (Ma\'un).',
      virtues:
      'A foundational Surah on the inseparability of social compassion and genuine faith in Islam. The Prophet ﷺ emphasized that caring for orphans and the poor is as important as prayer.',
    ),
    108: SurahInfoData(
      surahId: 108,
      title: 'Al-Kawthar (The Abundance)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'The shortest Surah in the Quran (three verses), Al-Kawthar was revealed to console the Prophet ﷺ after the death of his sons, when his enemies (particularly Al-\'As ibn Wa\'il) called him "Abtar" (one who is cut off — without male heirs). Allah promised him Al-Kawthar (a river in Paradise, or an abundance of good) instead.',
      themes:
      '• Allah has given the Prophet ﷺ immense abundance (Al-Kawthar).\n• A command to pray to Allah and sacrifice to Him alone.\n• The one who hates the Prophet ﷺ will be the one who is cut off (Abtar) — his legacy will perish.',
      virtues:
      'The Prophet ﷺ said he was shown the river of Al-Kawthar in Paradise — whiter than milk, sweeter than honey, with banks of pearls. (Muslim) This Surah is the shortest Surah in the Quran and among the most frequently recited.',
    ),
    109: SurahInfoData(
      surahId: 109,
      title: 'Al-Kafirun (The Disbelievers)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed when the Quraysh leaders proposed a compromise: they would worship Allah for a year if the Prophet ﷺ worshipped their idols for a year. This Surah was the absolute, unequivocal rejection of that proposal and of any compromise in matters of worship.',
      themes:
      '• An absolute rejection of any form of compromise or syncretism in matters of worship.\n• A clear declaration of the unbridgeable difference between Islamic monotheism and polytheism.\n• "To you is your religion, and to me is my religion." (109:6)',
      virtues:
      'The Prophet ﷺ called it "the Surah that frees from Shirk" and recommended reciting it before sleeping. He would recite it in the Fajr sunnah prayer and in the Witr prayer. (Abu Dawud)',
    ),
    110: SurahInfoData(
      surahId: 110,
      title: 'An-Nasr (The Divine Support)',
      revelation: 'Medina',
      period: 'Late Medinan Period',
      background:
      'Revealed at the time of the Conquest of Mecca or during the Farewell Pilgrimage, An-Nasr was understood by the senior companions, particularly Abu Bakr and Ibn Abbas, as an indication that the Prophet\'s mission was complete and that his death was near.',
      themes:
      '• The victory of Islam and the entry of people into it in multitudes.\n• The command to glorify and seek forgiveness from Allah at the time of victory.\n• Understood by the companions as a prophecy of the Prophet\'s imminent passing.',
      virtues:
      'Ibn Abbas wept when he heard this Surah, understanding it as the announcement of the Prophet\'s ﷺ approaching death. It teaches the believer to respond to success with humility and increased worship, not pride. (Bukhari)',
    ),
    111: SurahInfoData(
      surahId: 111,
      title: 'Al-Masad (The Palm Fiber)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed after Abu Lahab, the Prophet\'s own uncle, publicly cursed him and threw stones at him when the Prophet ﷺ called his people on Mount Safa. It is the only Surah that mentions a specific named opponent of the Prophet ﷺ and prophesies his damnation — a prophecy that was fulfilled when Abu Lahab died as a disbeliever.',
      themes:
      '• The perishing of Abu Lahab (lit. "Father of Flame") and his wealth.\n• His wife, the carrier of firewood (a thorny woman who spread slander), will have a rope of palm fiber around her neck in Hell.\n• A fulfilled prophecy — Abu Lahab died as a disbeliever two weeks after the Battle of Badr.',
      virtues:
      'This Surah is itself a miracle: the Prophet ﷺ proclaimed it about someone still living, and Abu Lahab could easily have disproved it by pretending to convert. His failure to do so, and his death as a disbeliever, is cited as evidence of Quranic prophecy.',
    ),
    112: SurahInfoData(
      surahId: 112,
      title: 'Al-Ikhlas (Sincerity)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Revealed in response to the Quraysh\'s demand that the Prophet ﷺ describe his Lord. It is a complete, four-verse definition of Islamic monotheism (Tawhid), negating all false conceptions of God. It refutes the idea that Allah has children (as Christians believed), was born (as Jews believed in Uzayr), or has any equal.',
      themes:
      '• Allah is One (Ahad) — absolutely without any partner or parallel.\n• Allah is As-Samad — the Self-Sufficient Master upon Whom all depend.\n• He neither begets nor was He begotten.\n• There is none equivalent to Him.',
      virtues:
      'The Prophet ﷺ said: "By Him in Whose Hand my soul is, it is equal to one-third of the Quran." (Bukhari) He said this is because it contains a complete and pure description of Allah\'s Oneness.',
    ),
    113: SurahInfoData(
      surahId: 113,
      title: 'Al-Falaq (The Daybreak)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'Part of the "Al-Mu\'awwidhatayn" (The Two Cloaks of Protection) along with An-Nas. Revealed in Mecca (or Medina according to some scholars), the two Surahs were revealed together when the Prophet ﷺ was afflicted by a spell of black magic by a man named Labid ibn al-A\'sam.',
      themes:
      '• Seeking refuge in the Lord of the Daybreak from all created evils.\n• Protection from the evil of the darkness when it settles.\n• Protection from those who blow on knots (witchcraft).\n• Protection from the evil of an envier when they envy.',
      virtues:
      'Uqbah ibn \'Amir reported: "The Prophet ﷺ said: \'Verses have been revealed to me tonight the like of which has never been seen: Al-Falaq and An-Nas.\'" (Muslim) He used to recite them every morning, evening, and before sleeping.',
    ),
    114: SurahInfoData(
      surahId: 114,
      title: 'An-Nas (Mankind)',
      revelation: 'Mecca',
      period: 'Early Meccan Period',
      background:
      'The final Surah of the Quran and the second of the "Al-Mu\'awwidhatayn," An-Nas seeks refuge in the Lord, Sovereign, and God of Mankind from the whispering of the hidden Shaytan (the devil). It is a perfect seal of the Quran, reminding the believer to constantly seek divine protection from internal and external evil.',
      themes:
      '• Seeking refuge with the Lord (Rabb), King (Malik), and God (Ilah) of Mankind.\n• Protection from the whispering of the retreating whisperer (Shaytan).\n• The whisperer whispers in the chests of both jinn and humans.\n• A threefold appeal to Allah\'s attributes: Lord, King, and God.',
      virtues:
      'Together with Al-Falaq, the Prophet ﷺ said there are no other Surahs like them for seeking protection. He recommended reciting both three times morning and evening and before sleeping. (Abu Dawud)',
    ),
  };

  SurahInfoData? getInfo(int surahId) {
    return _data[surahId];
  }
}