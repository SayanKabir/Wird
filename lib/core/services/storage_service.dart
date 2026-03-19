import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/prayer.dart';
import '../../models/prayer_status.dart';
import '../../models/prayer_log.dart';
import '../../models/settings.dart';

/// Storage service for managing local data with Hive
class StorageService {
  static const String _settingsBoxName = 'settings';
  static const String _prayerLogsBoxName = 'prayer_logs';
  static const String _streaksBoxName = 'streaks';

  static const String _appSettingsKey = 'app_settings';
  static const String _streakDataKey = 'streak_data';

  Box<AppSettings>? _settingsBox;
  Box<PrayerLog>? _prayerLogsBox;
  Box<StreakData>? _streaksBox;

  /// Singleton instance
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Check if storage is initialized
  bool get isInitialized => 
      _settingsBox != null && 
      _prayerLogsBox != null && 
      _streaksBox != null;

  /// Initialize Hive and register adapters
  Future<void> init() async {
    await Hive.initFlutter();

    // Register type adapters
    _registerAdapters();

    // Open boxes
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
    _prayerLogsBox = await Hive.openBox<PrayerLog>(_prayerLogsBoxName);
    _streaksBox = await Hive.openBox<StreakData>(_streaksBoxName);
  }

  void _registerAdapters() {
    // Only register if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PrayerAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PrayerStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PrayerEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(PrayerLogAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(LocationDataAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(CalculationMethodTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(MadhabTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(PrayerNotificationSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(StreakDataAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(WeatherThemeAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(QuranScriptAdapter());
    }
  }

  // ============================================
  // SETTINGS OPERATIONS
  // ============================================

  /// Get app settings
  AppSettings getSettings() {
    return _settingsBox?.get(_appSettingsKey) ?? AppSettings.defaults();
  }

  /// Save app settings
  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox?.put(_appSettingsKey, settings);
  }

  /// Get settings listenable
  ValueListenable<Box<AppSettings>> getSettingsListenable() {
    return _settingsBox!.listenable(keys: [_appSettingsKey]);
  }

  /// Update a single setting
  Future<void> updateSetting<T>(T Function(AppSettings) update) async {
    final current = getSettings();
    // This is a simplified approach - in reality you'd pass a copyWith function
    await saveSettings(current);
  }

  /// Check if onboarding is completed
  bool isOnboardingCompleted() {
    return getSettings().onboardingCompleted;
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    final settings = getSettings().copyWith(onboardingCompleted: true);
    await saveSettings(settings);
  }

  // ============================================
  // PRAYER LOG OPERATIONS
  // ============================================

  /// Get prayer log for a specific date
  PrayerLog? getPrayerLog(DateTime date) {
    final key = _dateToKey(date);
    return _prayerLogsBox?.get(key);
  }

  /// Get today's prayer log
  PrayerLog? getTodaysPrayerLog() {
    return getPrayerLog(DateTime.now());
  }

  /// Save prayer log
  Future<void> savePrayerLog(PrayerLog log) async {
    final key = _dateToKey(log.date);
    await _prayerLogsBox?.put(key, log);
  }

  /// Update a single prayer in today's log
  Future<void> updatePrayerEntry(Prayer prayer, PrayerEntry entry) async {
    final today = DateTime.now();
    var log = getPrayerLog(today);
    
    if (log != null) {
      log = log.updatePrayer(prayer, entry);
      await savePrayerLog(log);
    }
  }

  /// Get prayer logs for a date range
  List<PrayerLog> getPrayerLogsForRange(DateTime start, DateTime end) {
    final logs = <PrayerLog>[];
    var current = start;
    
    while (!current.isAfter(end)) {
      final log = getPrayerLog(current);
      if (log != null) {
        logs.add(log);
      }
      current = current.add(const Duration(days: 1));
    }
    
    return logs;
  }

  /// Get prayer logs for the past N days
  List<PrayerLog> getRecentPrayerLogs(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    return getPrayerLogsForRange(start, end);
  }

  /// Delete prayer log for a specific date
  Future<void> deletePrayerLog(DateTime date) async {
    final key = _dateToKey(date);
    await _prayerLogsBox?.delete(key);
  }

  /// Clear all prayer logs
  Future<void> clearAllPrayerLogs() async {
    await _prayerLogsBox?.clear();
  }

  // ============================================
  // STREAK OPERATIONS
  // ============================================

  /// Get streak data
  StreakData getStreakData() {
    return _streaksBox?.get(_streakDataKey) ?? StreakData.empty();
  }

  /// Save streak data
  Future<void> saveStreakData(StreakData data) async {
    await _streaksBox?.put(_streakDataKey, data);
  }

  /// Update streak after prayer completion
  Future<void> updateStreak({
    required bool isPerfectDay,
    required Map<Prayer, bool> prayerOnTime,
  }) async {
    var streak = getStreakData();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (isPerfectDay) {
      // Check if last perfect day was yesterday (continuing streak)
      final lastPerfect = streak.lastPerfectDay;
      final yesterday = todayDate.subtract(const Duration(days: 1));
      
      if (lastPerfect != null && _isSameDay(lastPerfect, yesterday)) {
        // Continue streak
        streak = streak.copyWith(
          currentStreak: streak.currentStreak + 1,
          lastPerfectDay: todayDate,
        );
      } else if (lastPerfect == null || !_isSameDay(lastPerfect, todayDate)) {
        // Start new streak
        streak = streak.copyWith(
          currentStreak: 1,
          lastPerfectDay: todayDate,
        );
      }

      // Update longest streak
      if (streak.currentStreak > streak.longestStreak) {
        streak = streak.copyWith(longestStreak: streak.currentStreak);
      }
    } else {
      // Check if streak should reset
      final lastPerfect = streak.lastPerfectDay;
      if (lastPerfect != null && !_isSameDay(lastPerfect, todayDate)) {
        // Reset streak if we missed a day
        streak = streak.copyWith(currentStreak: 0);
      }
    }

    // Update prayer-specific streaks
    final prayerStreaks = Map<String, int>.from(streak.prayerStreaks ?? {});
    for (final entry in prayerOnTime.entries) {
      final prayerName = entry.key.name;
      final onTime = entry.value;
      
      if (onTime) {
        prayerStreaks[prayerName] = (prayerStreaks[prayerName] ?? 0) + 1;
      } else {
        prayerStreaks[prayerName] = 0;
      }
    }
    streak = streak.copyWith(prayerStreaks: prayerStreaks);

    await saveStreakData(streak);
  }

  /// Reset current streak
  Future<void> resetStreak() async {
    final streak = getStreakData().copyWith(currentStreak: 0);
    await saveStreakData(streak);
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Convert date to storage key
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Clear all data (for debugging/testing)
  Future<void> clearAllData() async {
    await _settingsBox?.clear();
    await _prayerLogsBox?.clear();
    await _streaksBox?.clear();
  }

  /// Close all boxes
  Future<void> close() async {
    await _settingsBox?.close();
    await _prayerLogsBox?.close();
    await _streaksBox?.close();
  }

  /// Get storage statistics
  Map<String, int> getStorageStats() {
    return {
      'settings_entries': _settingsBox?.length ?? 0,
      'prayer_logs': _prayerLogsBox?.length ?? 0,
      'streak_entries': _streaksBox?.length ?? 0,
    };
  }
}
