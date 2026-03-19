import 'package:flutter/material.dart';

import 'hijri_date.dart';

enum IslamicEventType {
  eidAlFitr,
  eidAlAdha,
  ramadan,
  jummah,
  arafah,
  ashura,
  isra,

  laylatAlQadr,
  dhulHijjah,
  ayyamAlBeed,
}

class IslamicDayMessage {
  final IslamicEventType type;
  final String title;
  final String subtitle;
  final String virtue;
  final String duration;
  final List<String> recommendedSunnahs;

  const IslamicDayMessage({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.virtue,
    required this.duration,
    required this.recommendedSunnahs,
  });
}

class IslamicDayUtils {
  IslamicDayUtils._();

  static bool isRamadanDate(DateTime date, {DateTime? maghribTime}) {
    final hijri = maghribTime != null
        ? HijriDate.fromDateTime(date, maghribTime: maghribTime)
        : HijriDate.fromGregorian(date);
    return hijri.month == 9;
  }

  static int? daysUntilNextRamadan(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    if (isRamadanDate(start)) return 0;
    for (var offset = 1; offset <= 420; offset++) {
      final candidate = start.add(Duration(days: offset));
      final hijri = HijriDate.fromGregorian(candidate);
      if (hijri.month == 9 && hijri.day == 1) return offset;
    }
    return null;
  }

  // =========================================================================
  // messageForDate — returns the highest-priority event for a single date.
  // Preserved for backward compatibility (home_screen, today card, day cell).
  // =========================================================================

  static IslamicDayMessage? messageForDate(DateTime date, {DateTime? maghribTime}) {
    final hijri = maghribTime != null
        ? HijriDate.fromDateTime(date, maghribTime: maghribTime)
        : HijriDate.fromGregorian(date);
    final isFriday = date.weekday == DateTime.friday;

    // --- Eid al-Fitr (1 Shawwal) ---
    if (hijri.month == 10 && hijri.day == 1) {
      return const IslamicDayMessage(
        type: IslamicEventType.eidAlFitr,
        title: 'Eid al-Fitr',
        subtitle: 'May Allah accept your fasting and deeds.',
        duration: '1 Shawwal',
        virtue: 'A day of gratitude, joy, and communal worship after Ramadan.',
        recommendedSunnahs: [
          'Recite takbir from the night until Eid prayer',
          'Eat an odd number of dates before Eid salah',
          'Use one route to prayer and return by another',
          'Pay Zakat al-Fitr before Eid salah',
        ],
      );
    }

    // --- Eid al-Adha (10 Dhul Hijjah) ---
    if (hijri.month == 12 && hijri.day == 10) {
      return const IslamicDayMessage(
        type: IslamicEventType.eidAlAdha,
        title: 'Eid al-Adha',
        subtitle: 'May Allah accept your sacrifice and worship.',
        duration: '10 Dhul Hijjah',
        virtue: 'A day of sacrifice and remembrance of the obedience of Ibrahim.',
        recommendedSunnahs: [
          'Recite takbir frequently throughout the day',
          'Attend Eid salah and listen to the khutbah',
          'Offer udhiyah if able',
          'Share food and charity with others',
        ],
      );
    }

    // --- Day of Arafah (9 Dhul Hijjah) ---
    if (hijri.month == 12 && hijri.day == 9) {
      return const IslamicDayMessage(
        type: IslamicEventType.arafah,
        title: 'Day of Arafah',
        subtitle: 'A day of immense mercy and forgiveness.',
        duration: '9 Dhul Hijjah',
        virtue: 'For non-pilgrims, fasting this day expiates sins of the previous and coming year.',
        recommendedSunnahs: [
          'Fast on the Day of Arafah if not performing Hajj',
          'Increase tahlil, takbir, and tahmid',
          'Make abundant dua with sincerity',
        ],
      );
    }

    // --- First 10 of Dhul Hijjah (1–8 Dhul Hijjah, excluding Arafah & Eid) ---
    if (hijri.month == 12 && hijri.day >= 1 && hijri.day <= 8) {
      return IslamicDayMessage(
        type: IslamicEventType.dhulHijjah,
        title: 'Blessed Days of Dhul Hijjah',
        subtitle: 'Day ${hijri.day} of 10 — increase good deeds.',
        duration: '1–10 Dhul Hijjah',
        virtue: 'No days in which righteous deeds are more beloved to Allah than these ten days.',
        recommendedSunnahs: const [
          'Fast the first 9 days, especially Day of Arafah',
          'Increase takbir, tahlil, and tahmid',
          'Give extra charity',
          'Perform extra voluntary prayers',
        ],
      );
    }

    // --- Laylat al-Qadr (Odd nights of the last 10 days of Ramadan) ---
    if (hijri.month == 9 && hijri.day >= 21 && hijri.day % 2 != 0) {
      return IslamicDayMessage(
        type: IslamicEventType.laylatAlQadr,
        title: 'Laylat al-Qadr (Expected)',
        subtitle: 'Seek the Night of Decree in the odd nights of the last ten.',
        duration: '${hijri.day} Ramadan',
        virtue: 'Worship on this night is better than worship of a thousand months.',
        recommendedSunnahs: const [
          'Pray Tahajjud and make abundant dua',
          'Recite: Allahumma innaka afuwwun tuhibbul afwa fa\'fu anni',
          'Increase Quran recitation',
          'Give charity on this night',
        ],
      );
    }

    // --- Ramadan (entire month, but messageForDate still returns for each day) ---
    if (hijri.month == 9) {
      return IslamicDayMessage(
        type: IslamicEventType.ramadan,
        title: 'Ramadan Kareem',
        subtitle: isFriday
            ? 'Jumu\'ah in Ramadan — increase your dua and recitation.'
            : 'Blessed month of Ramadan — increase Quran, dua, and dhikr.',
        duration: '1–29/30 Ramadan',
        virtue: 'The month of mercy and forgiveness in which rewards are multiplied.',
        recommendedSunnahs: const [
          'Take suhoor close to Fajr',
          'Break the fast promptly at Maghrib',
          'Increase Quran recitation and night prayer',
          'Give charity consistently',
        ],
      );
    }

    // --- Ashura (10 Muharram) ---
    if (hijri.month == 1 && hijri.day == 10) {
      return const IslamicDayMessage(
        type: IslamicEventType.ashura,
        title: 'Ashura',
        subtitle: 'A day of gratitude and devotion.',
        duration: '10 Muharram',
        virtue: 'Fasting Ashura expiates sins of the previous year.',
        recommendedSunnahs: [
          'Fast Ashura and add the 9th or 11th',
          'Increase gratitude and remembrance of Allah',
          'Renew sincere intention and tawbah',
        ],
      );
    }

    // --- Isra wal Mi'raj (27 Rajab) ---
    if (hijri.month == 7 && hijri.day == 27) {
      return const IslamicDayMessage(
        type: IslamicEventType.isra,
        title: 'Isra\' wal Mi\'raj',
        subtitle: 'The Night Journey and Ascension of the Prophet ﷺ.',
        duration: '27 Rajab',
        virtue: 'A miraculous night when the five daily prayers were prescribed.',
        recommendedSunnahs: [
          'Reflect on the story of the journey',
          'Pray extra voluntary prayers',
          'Make abundant dua and dhikr',
        ],
      );
    }



    // --- Ayyam al-Beed (13, 14, 15 of every Hijri month) ---
    if (hijri.day >= 13 && hijri.day <= 15) {
      return IslamicDayMessage(
        type: IslamicEventType.ayyamAlBeed,
        title: 'Ayyam al-Beed',
        subtitle: 'The White Days — a sunnah to fast.',
        duration: '13–15 ${hijri.monthNameEnglish}',
        virtue: 'Fasting three days each month is like fasting the entire year.',
        recommendedSunnahs: const [
          'Fast these three days',
          'Increase dhikr and gratitude',
          'Make dua during the fast',
        ],
      );
    }

    // --- Jumu'ah ---
    if (isFriday) {
      return const IslamicDayMessage(
        type: IslamicEventType.jummah,
        title: 'Jumu\'ah',
        subtitle: 'Send abundant salawat and make heartfelt dua.',
        duration: 'Every Friday',
        virtue: 'The best day of the week with a special hour in which dua is accepted.',
        recommendedSunnahs: [
          'Send abundant salawat on the Prophet ﷺ',
          'Recite Surah Al-Kahf',
          'Take ghusl, wear clean clothes, and use fragrance',
          'Go early and listen attentively to khutbah',
        ],
      );
    }

    return null;
  }

  // =========================================================================
  // eventsForMonth — returns deduplicated events for the month.
  // Used by the calendar's "THIS MONTH'S EVENTS" section.
  // =========================================================================

  static List<MonthEvent> eventsForMonth(DateTime month) {
    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    final seen = <String>{};
    final results = <MonthEvent>[];

    for (var day = 1; day <= totalDays; day++) {
      final date = DateTime(month.year, month.month, day);
      final event = messageForDate(date);
      if (event == null) continue;

      // Skip Jumu'ah — too frequent for a monthly list
      if (event.type == IslamicEventType.jummah) continue;

      // Deduplicate multi-day events (Ramadan, Dhul Hijjah, Ayyam al-Beed)
      final key = '${event.type.name}_${event.title}';
      if (seen.contains(key)) continue;
      seen.add(key);

      results.add(MonthEvent(
        date: date,
        message: event,
      ));
    }

    return results;
  }

  // =========================================================================
  // Styling helpers
  // =========================================================================

  static IconData iconForType(IslamicEventType type) {
    switch (type) {
      case IslamicEventType.eidAlFitr:
      case IslamicEventType.eidAlAdha:
        return Icons.celebration_rounded;
      case IslamicEventType.ramadan:
        return Icons.nightlight_round;
      case IslamicEventType.jummah:
        return Icons.mosque_rounded;
      case IslamicEventType.arafah:
        return Icons.landscape_rounded;
      case IslamicEventType.ashura:
        return Icons.auto_awesome_rounded;
      case IslamicEventType.isra:
        return Icons.flight_rounded;

      case IslamicEventType.laylatAlQadr:
        return Icons.star_rounded;
      case IslamicEventType.dhulHijjah:
        return Icons.terrain_rounded;
      case IslamicEventType.ayyamAlBeed:
        return Icons.wb_sunny_outlined;
    }
  }

  static Color accentColor(IslamicEventType type) {
    switch (type) {
      case IslamicEventType.eidAlFitr:
      case IslamicEventType.eidAlAdha:
        return const Color(0xFFFFD27D);
      case IslamicEventType.ramadan:
        return const Color(0xFF9BE7C4);
      case IslamicEventType.jummah:
        return const Color(0xFF80CBC4);
      case IslamicEventType.arafah:
        return const Color(0xFFAED581);
      case IslamicEventType.ashura:
        return const Color(0xFF90CAF9);
      case IslamicEventType.isra:
        return const Color(0xFFCE93D8);

      case IslamicEventType.laylatAlQadr:
        return const Color(0xFFFFE082);
      case IslamicEventType.dhulHijjah:
        return const Color(0xFFA5D6A7);
      case IslamicEventType.ayyamAlBeed:
        return const Color(0xFFE0E0E0);
    }
  }

  // =========================================================================
  // nextImportantEvent — finds the next significant event from today.
  // Skips Jummah, Ayyam al-Beed, and multi-day events already in progress
  // (e.g. mid-Ramadan). Returns null if nothing found within ~400 days.
  // =========================================================================

  static const _countdownTypes = {
    IslamicEventType.eidAlFitr,
    IslamicEventType.eidAlAdha,
    IslamicEventType.ramadan,
    IslamicEventType.arafah,
    IslamicEventType.ashura,
    IslamicEventType.isra,
    IslamicEventType.laylatAlQadr,
    IslamicEventType.dhulHijjah,
  };

  static NextEventInfo? nextImportantEvent(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);

    // If currently in a multi-day event (Ramadan, Dhul Hijjah), skip past it
    // by checking today's event and advancing past it.
    final todayEvent = messageForDate(start);
    final skipType = todayEvent != null && _countdownTypes.contains(todayEvent.type)
        ? todayEvent.type
        : null;

    for (var offset = 1; offset <= 400; offset++) {
      final candidate = start.add(Duration(days: offset));
      final event = messageForDate(candidate);
      if (event == null) continue;
      if (!_countdownTypes.contains(event.type)) continue;

      // Skip same multi-day event we're currently in
      if (skipType != null && event.type == skipType) continue;

      return NextEventInfo(
        event: event,
        date: candidate,
        daysUntil: offset,
      );
    }
    return null;
  }
}

/// A deduplicated month event entry, used by the calendar's event list.
class MonthEvent {
  final DateTime date;
  final IslamicDayMessage message;
  const MonthEvent({required this.date, required this.message});
}

/// Info about the next upcoming important Islamic event.
class NextEventInfo {
  final IslamicDayMessage event;
  final DateTime date;
  final int daysUntil;
  const NextEventInfo({
    required this.event,
    required this.date,
    required this.daysUntil,
  });
}
