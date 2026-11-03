import '../../models/prayer.dart';
import '../../models/settings.dart';
import '../../models/sunnah_progress.dart';
import '../repositories/practice_ids.dart';
import '../services/prayer_service.dart';
import '../utils/hijri_date.dart';

/// Which notification channel a reminder goes out on.
enum ReminderKind { practice, quran, fasting }

/// One reminder to schedule. [target] says what tapping it opens:
/// `session:<id>`, `quran:<surah>` or `sunnah`.
class PlannedReminder {
  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String target;
  final ReminderKind kind;

  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.target,
    required this.kind,
  });

  @override
  String toString() => 'PlannedReminder($id @ $at: $title)';
}

/// What the planner needs to know about today.
class ReminderContext {
  final DateTime now;
  final Map<Prayer, PrayerTimeData> times;
  final AppSettings settings;
  final SunnahProgress progress;

  /// Guided dhikr sessions finished today ('morning', 'evening', ...).
  final Set<String> sessionsDoneToday;
  final bool quranReadToday;
  final int quranStreak;

  const ReminderContext({
    required this.now,
    required this.times,
    required this.settings,
    required this.progress,
    this.sessionsDoneToday = const {},
    this.quranReadToday = false,
    this.quranStreak = 0,
  });
}

/// Decides the day's practice, Quran and fasting reminders. Pure, so every
/// rule can be tested without a phone; NotificationService schedules what
/// it returns.
///
/// Gentle by design: each reminder is for something in the user's practice
/// (fasting on the great days aside), skipped once it's done, and placed in
/// the window the Sunnah itself names.
class ReminderPlanner {
  const ReminderPlanner._();

  static const int morningId = 400;
  static const int eveningId = 401;
  static const int sleepId = 402;
  static const int quranId = 403;
  static const int kahfId = 404;
  static const int streakId = 405;
  static const int fastingId = 406;

  /// Every id the planner may use, cancelled before each reschedule.
  static const List<int> allIds = [morningId, eveningId, sleepId, quranId, kahfId, streakId, fastingId];

  static List<PlannedReminder> plan(ReminderContext c) {
    final s = c.settings;
    if (!s.notificationsEnabled) return const [];
    final out = <PlannedReminder>[];
    void add(PlannedReminder? r) {
      if (r != null && r.at.isAfter(c.now)) out.add(r);
    }

    if (s.practiceRemindersEnabled) {
      add(_morning(c));
      add(_evening(c));
      add(_sleep(c));
      add(_kahf(c));
      add(_streak(c));
    }
    if (s.quranRemindersEnabled) add(_quran(c));
    if (s.fastingRemindersEnabled) add(_fasting(c));
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  // ── Practice ──────────────────────────────────────────────────────────

  static bool _wants(ReminderContext c, String id) =>
      c.progress.isInPractice(id) && !c.progress.isPracticedToday(id, now: c.now);

  /// [at], or null when it falls outside [start, end).
  static DateTime? _within(DateTime at, DateTime start, DateTime end) =>
      !at.isBefore(start) && at.isBefore(end) ? at : null;

  static PlannedReminder? _morning(ReminderContext c) {
    final fajr = c.times[Prayer.fajr];
    if (fajr == null || !_wants(c, PracticeIds.morningAzkar) || c.sessionsDoneToday.contains('morning')) return null;
    // Between Fajr and sunrise, once the prayer itself has had its time.
    final at = _within(fajr.startTime.add(const Duration(minutes: 20)), fajr.startTime,
        fajr.endTime.subtract(const Duration(minutes: 5)));
    if (at == null) return null;
    return PlannedReminder(
      id: morningId,
      at: at,
      title: 'Morning azkar',
      body: _pick(c.now, const [
        'A few minutes before sunrise to keep you through the day.',
        'Begin the day in the remembrance of Allah.',
        'Ayat al-Kursi, the three Quls and Sayyid al-Istighfar are waiting.',
      ]),
      target: 'session:morning',
      kind: ReminderKind.practice,
    );
  }

  static PlannedReminder? _evening(ReminderContext c) {
    final asr = c.times[Prayer.asr];
    final maghrib = c.times[Prayer.maghrib];
    if (asr == null || maghrib == null) return null;
    if (!_wants(c, PracticeIds.eveningAzkar) || c.sessionsDoneToday.contains('evening')) return null;
    final at = _within(asr.startTime.add(const Duration(minutes: 30)), asr.startTime,
        maghrib.startTime.subtract(const Duration(minutes: 5)));
    if (at == null) return null;
    return PlannedReminder(
      id: eveningId,
      at: at,
      title: 'Evening azkar',
      body: _pick(c.now, const [
        'The evening remembrance protects you through the night.',
        'A quiet few minutes of dhikr before Maghrib.',
        'Close the day the way you began it.',
      ]),
      target: 'session:evening',
      kind: ReminderKind.practice,
    );
  }

  static PlannedReminder? _sleep(ReminderContext c) {
    final isha = c.times[Prayer.isha];
    if (isha == null) return null;
    final azkar = _wants(c, PracticeIds.sleepAzkar) && !c.sessionsDoneToday.contains('before_sleep');
    final kursi = _wants(c, PracticeIds.ayatKursiSleep);
    final mulk = _wants(c, PracticeIds.mulkSleep);
    if (!azkar && !kursi && !mulk) return null;
    final at = _within(isha.startTime.add(const Duration(minutes: 75)), isha.startTime,
        isha.endTime.subtract(const Duration(minutes: 10)));
    if (at == null) return null;
    final parts = [
      if (azkar) 'the sleep azkar',
      if (kursi) 'Ayat al-Kursi',
      if (mulk) 'Surah al-Mulk',
    ];
    return PlannedReminder(
      id: sleepId,
      at: at,
      title: 'Before you sleep',
      body: 'Remember ${_list(parts)} before you rest.',
      target: azkar ? 'session:before_sleep' : (mulk && !kursi ? 'quran:67' : 'sunnah'),
      kind: ReminderKind.practice,
    );
  }

  static PlannedReminder? _kahf(ReminderContext c) {
    final fajr = c.times[Prayer.fajr];
    if (c.now.weekday != DateTime.friday || fajr == null || !_wants(c, PracticeIds.kahfFriday)) return null;
    // Mid-morning, after sunrise and well before Jumuah.
    return PlannedReminder(
      id: kahfId,
      at: fajr.endTime.add(const Duration(hours: 2, minutes: 30)),
      title: "It's Friday",
      body: 'Recite Surah al-Kahf: a light between this Friday and the next.',
      target: 'quran:18',
      kind: ReminderKind.practice,
    );
  }

  static PlannedReminder? _streak(ReminderContext c) {
    final isha = c.times[Prayer.isha];
    final p = c.progress;
    if (isha == null || p.practiceIds.isEmpty) return null;
    final streak = p.liveStreak(now: c.now);
    final keptToday = p.lastPracticeDateKey == SunnahProgress.dateKey(c.now);
    if (streak < 2 || keptToday) return null;
    return PlannedReminder(
      id: streakId,
      at: isha.startTime.add(const Duration(minutes: 20)),
      title: 'Keep your $streak-day streak',
      body: 'One Sunnah from your practice today keeps it going.',
      target: 'sunnah',
      kind: ReminderKind.practice,
    );
  }

  // ── Quran ─────────────────────────────────────────────────────────────

  static PlannedReminder? _quran(ReminderContext c) {
    final maghrib = c.times[Prayer.maghrib];
    if (maghrib == null || c.quranReadToday) return null;
    if (!c.progress.isInPractice(PracticeIds.readQuran) && c.quranStreak == 0) return null;
    final at = _within(maghrib.startTime.add(const Duration(minutes: 40)), maghrib.startTime, maghrib.endTime) ??
        maghrib.endTime.add(const Duration(minutes: 30));
    return PlannedReminder(
      id: quranId,
      at: at,
      title: c.quranStreak >= 2 ? 'Keep your ${c.quranStreak}-day Quran streak' : 'Time with the Quran',
      body: _pick(c.now, const [
        'Even a few ayahs today. Pick up where you left off.',
        'A page tonight keeps the habit alive.',
        'The best of you are those who learn the Quran and teach it.',
      ]),
      target: 'quran:last',
      kind: ReminderKind.quran,
    );
  }

  // ── Fasting ───────────────────────────────────────────────────────────

  /// The evening before a fasting day: one reminder, for the most important
  /// reason tomorrow has.
  static PlannedReminder? _fasting(ReminderContext c) {
    final maghrib = c.times[Prayer.maghrib];
    if (maghrib == null) return null;
    final today = DateTime(c.now.year, c.now.month, c.now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final h = HijriDate.fromGregorian(tomorrow);
    final inRamadan = h.month == 9;

    String? title;
    String? body;
    if (h.month == 9 && h.day == 1) {
      title = 'Ramadan begins tomorrow';
      body = 'Depending on the moon. Set your intention and plan suhoor.';
    } else if (h.month == 12 && h.day == 9) {
      title = 'Tomorrow is the Day of Arafah';
      body = 'Fasting it expiates the sins of the year before and the year after.';
    } else if (h.month == 1 && (h.day == 9 || h.day == 10)) {
      title = h.day == 10 ? 'Tomorrow is Ashura' : 'Ashura is the day after tomorrow';
      body = 'Fast the 9th and 10th of Muharram, as the Prophet ﷺ intended.';
    } else if (!inRamadan &&
        h.day == 13 &&
        c.progress.isInPractice(PracticeIds.fastWhiteDays)) {
      title = 'The white days start tomorrow';
      body = 'Fast the 13th, 14th and 15th: like fasting the whole month.';
    } else if (!inRamadan &&
        (tomorrow.weekday == DateTime.monday || tomorrow.weekday == DateTime.thursday) &&
        c.progress.isInPractice(PracticeIds.fastMonThu)) {
      final day = tomorrow.weekday == DateTime.monday ? 'Monday' : 'Thursday';
      title = 'Tomorrow is $day';
      body = 'A sunnah fast: deeds are presented to Allah on Mondays and Thursdays.';
    }
    if (title == null) return null;
    return PlannedReminder(
      id: fastingId,
      at: maghrib.startTime.add(const Duration(minutes: 90)),
      title: title,
      body: body!,
      target: 'sunnah',
      kind: ReminderKind.fasting,
    );
  }

  // ── Wording ───────────────────────────────────────────────────────────

  /// The same line all day, a different one tomorrow.
  static String _pick(DateTime now, List<String> lines) =>
      lines[DateTime(now.year, now.month, now.day).difference(DateTime(2024)).inDays % lines.length];

  static String _list(List<String> parts) => switch (parts.length) {
        1 => parts.first,
        2 => '${parts[0]} and ${parts[1]}',
        _ => '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}',
      };
}
