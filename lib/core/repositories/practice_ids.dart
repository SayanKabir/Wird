/// Ids of the Sunnahs that reminders and the starting practice refer to.
/// They're slugs of category and title (see SunnahRepository), checked by a
/// test so a renamed Sunnah can't silently drop out.
class PracticeIds {
  const PracticeIds._();

  static const morningAzkar = 'dhikr_azkar_complete_morning_azkar';
  static const eveningAzkar = 'dhikr_azkar_complete_evening_azkar';
  static const sleepAzkar = 'dhikr_azkar_complete_before_sleep_azkar';
  static const sayyidIstighfar = 'dhikr_azkar_say_sayyid_al_istighfar_morning_and_evening';
  static const leavingHomeDua = 'miscellaneous_daily_sunnahs_say_the_dua_when_leaving_home';
  static const bismillah = 'eating_drinking_say_bismillah_before_eating';
  static const readQuran = 'knowledge_read_quran_daily';
  static const kahfFriday = 'knowledge_recite_surah_al_kahf_every_friday';
  static const ayatKursiSleep = 'sleep_waking_recite_ayat_al_kursi_before_sleep';
  static const mulkSleep = 'sleep_waking_recite_surah_al_mulk_before_sleeping';
  static const fastMonThu = 'fasting_fast_mondays_and_thursdays';
  static const fastWhiteDays = 'fasting_fast_3_white_days_13_14_15_lunar';

  /// A first practice: the daily azkar, two everyday duas, the master of
  /// istighfar, the Quran each day and al-Kahf on Fridays. Easy, authentic
  /// and spread through the day, so the reminders have something to offer.
  static const defaults = [
    morningAzkar,
    eveningAzkar,
    sleepAzkar,
    sayyidIstighfar,
    leavingHomeDua,
    bismillah,
    readQuran,
    kahfFriday,
  ];
}
