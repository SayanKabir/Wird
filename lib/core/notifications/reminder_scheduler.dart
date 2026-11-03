import 'package:flutter/foundation.dart';

import '../repositories/quran_progress_repository.dart';
import '../repositories/sunnah_progress_repository.dart';
import '../repositories/tasbih_repository.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import 'reminder_planner.dart';

/// Gathers today's state and (re)schedules the practice, Quran and fasting
/// reminders. Call it whenever something they depend on changes: prayer
/// times load, a Sunnah is ticked or joins the practice, a dhikr session
/// finishes, Quran is read, or a reminder setting flips. Cheap and safe to
/// call often; a failure only means today's reminders stay as they were.
class ReminderScheduler {
  const ReminderScheduler._();

  static Future<void>? _running;

  static Future<void> refresh() async {
    // Calls that land while one is running wait for it, then run once more,
    // so the last change always wins without stacking up work.
    final previous = _running;
    final next = () async {
      await previous;
      await _refresh();
    }();
    _running = next;
    return next;
  }

  static Future<void> _refresh() async {
    try {
      final storage = StorageService();
      if (!storage.isInitialized) return;
      final settings = storage.getSettings();
      final location = settings.location;
      final now = DateTime.now();
      if (location == null || !location.isValid) {
        await NotificationService().schedulePlannedReminders(const []);
        return;
      }

      final today = DateTime(now.year, now.month, now.day);
      final times = PrayerService().calculatePrayerTimes(
        date: today,
        location: location,
        calculationMethod: settings.calculationMethod,
        madhab: settings.madhab,
        includeTahajjud: false,
        includeIshraq: false,
        includeDuha: false,
      );
      final sessions = DhikrSessionStore();
      final quran = await QuranProgressRepository().getProgress();
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final quranStreak =
          quran.lastReadDateKey == todayKey || quran.lastReadDateKey == yesterdayKey ? quran.currentStreak : 0;

      final reminders = ReminderPlanner.plan(ReminderContext(
        now: now,
        times: times,
        settings: settings,
        progress: await SunnahProgressRepository().getProgress(),
        sessionsDoneToday: {
          for (final id in const ['morning', 'evening', 'before_sleep'])
            if (sessions.isDoneToday(id, now: now)) id,
        },
        quranReadToday: (quran.versesReadByDay[todayKey] ?? 0) > 0,
        quranStreak: quranStreak,
      ));
      await NotificationService().schedulePlannedReminders(reminders);
    } catch (e) {
      debugPrint('[Reminders] refresh failed: $e');
    }
  }
}
