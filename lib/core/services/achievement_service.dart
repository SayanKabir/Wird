import 'package:flutter/material.dart';
import '../../models/prayer.dart';
import '../../models/prayer_log.dart';
import '../../models/prayer_status.dart';
import '../../models/settings.dart';
import 'storage_service.dart';

/// Achievement definitions with unlock criteria
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final double progress; // 0.0 to 1.0
  final String progressText;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedDate,
    this.progress = 0.0,
    this.progressText = '',
  });

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedDate,
    double? progress,
    String? progressText,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      progress: progress ?? this.progress,
      progressText: progressText ?? this.progressText,
    );
  }
}

/// Service for calculating achievements based on actual prayer data
class AchievementService {
  final StorageService _storageService;

  AchievementService({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  /// Achievement definitions - the base data before unlock calculation
  static final List<Achievement> _achievementDefinitions = [
    const Achievement(
      id: 'fajr_7',
      title: 'Dawn Walker',
      description: 'Pray Fajr on time for 7 consecutive days',
      icon: Icons.wb_twilight_rounded,
    ),
    const Achievement(
      id: 'streak_7',
      title: 'Week of Devotion',
      description: 'Maintain a 7-day prayer streak',
      icon: Icons.calendar_today_rounded,
    ),
    const Achievement(
      id: 'streak_30',
      title: 'Istiqamah',
      description: 'Maintain a 30-day prayer streak',
      icon: Icons.local_fire_department_rounded,
    ),
    const Achievement(
      id: 'jamaah_10',
      title: 'Congregation Starter',
      description: 'Perform 10 prayers in Jama\'ah',
      icon: Icons.group_rounded,
    ),
    const Achievement(
      id: 'jamaah_50',
      title: 'Community Pillar',
      description: 'Perform 50 prayers in Jama\'ah',
      icon: Icons.groups_rounded,
    ),
    const Achievement(
      id: 'all_fardh_day',
      title: 'Perfect Day',
      description: 'Complete all 5 Fardh prayers on time in a single day',
      icon: Icons.verified_rounded,
    ),
    const Achievement(
      id: 'all_sunnah',
      title: 'Sunnah Reviver',
      description: 'Perform all enabled Sunnah prayers in a single day',
      icon: Icons.star_rounded,
    ),
    const Achievement(
      id: 'night_owl',
      title: 'Night Vigil',
      description: 'Wake up for Tahajjud 3 times in a week',
      icon: Icons.nights_stay_rounded,
    ),
    const Achievement(
      id: 'asr_30',
      title: 'Guardian of Asr',
      description: 'Pray Asr on time for 30 consecutive days',
      icon: Icons.shield_rounded,
    ),
    const Achievement(
      id: 'isha_7',
      title: 'Night Prayer Champion',
      description: 'Pray Isha on time for 7 consecutive days',
      icon: Icons.bedtime_rounded,
    ),
    const Achievement(
      id: 'first_prayer',
      title: 'First Step',
      description: 'Complete your first prayer',
      icon: Icons.emoji_events_rounded,
    ),
    const Achievement(
      id: 'week_complete',
      title: 'Weekly Warrior',
      description: 'Complete all prayers for an entire week',
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  /// Calculate achievements based on actual stored data
  List<Achievement> calculateAchievements() {
    final streakData = _storageService.getStreakData();
    final recentLogs = _storageService.getRecentPrayerLogs(30); // Get 30 days for analysis
    final allTimeLogs = _storageService.getRecentPrayerLogs(365); // Get up to a year for counting

    final achievements = <Achievement>[];

    for (final definition in _achievementDefinitions) {
      final achievement = _evaluateAchievement(definition, streakData, recentLogs, allTimeLogs);
      achievements.add(achievement);
    }

    // Sort: unlocked first, then by progress
    achievements.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      return b.progress.compareTo(a.progress);
    });

    return achievements;
  }

  Achievement _evaluateAchievement(
    Achievement definition,
    StreakData streakData,
    List<PrayerLog> recentLogs,
    List<PrayerLog> allTimeLogs,
  ) {
    switch (definition.id) {
      case 'fajr_7':
        return _evaluatePrayerStreak(definition, streakData, 'fajr', 7);
      
      case 'streak_7':
        return _evaluateOverallStreak(definition, streakData, 7);
      
      case 'streak_30':
        return _evaluateOverallStreak(definition, streakData, 30);
      
      case 'jamaah_10':
        return _evaluateJamaahCount(definition, allTimeLogs, 10);
      
      case 'jamaah_50':
        return _evaluateJamaahCount(definition, allTimeLogs, 50);
      
      case 'all_fardh_day':
        return _evaluatePerfectFardhDay(definition, allTimeLogs);
      
      case 'all_sunnah':
        return _evaluateAllSunnahDay(definition, allTimeLogs);
      
      case 'night_owl':
        return _evaluateTahajjudWeek(definition, recentLogs);
      
      case 'asr_30':
        return _evaluatePrayerStreak(definition, streakData, 'asr', 30);
      
      case 'isha_7':
        return _evaluatePrayerStreak(definition, streakData, 'isha', 7);
      
      case 'first_prayer':
        return _evaluateFirstPrayer(definition, allTimeLogs);
      
      case 'week_complete':
        return _evaluateWeekComplete(definition, recentLogs);
      
      default:
        return definition;
    }
  }

  /// Evaluate prayer-specific streak (e.g., Fajr 7-day streak)
  Achievement _evaluatePrayerStreak(
    Achievement definition,
    StreakData streakData,
    String prayerName,
    int target,
  ) {
    final current = streakData.getPrayerStreak(prayerName);
    final progress = (current / target).clamp(0.0, 1.0);
    final isUnlocked = current >= target;

    return definition.copyWith(
      isUnlocked: isUnlocked,
      unlockedDate: isUnlocked ? streakData.lastPerfectDay : null,
      progress: progress,
      progressText: '$current / $target days',
    );
  }

  /// Evaluate overall streak
  Achievement _evaluateOverallStreak(
    Achievement definition,
    StreakData streakData,
    int target,
  ) {
    final current = streakData.longestStreak; // Use longest, not current for unlock
    final currentStreak = streakData.currentStreak;
    final progress = (currentStreak / target).clamp(0.0, 1.0);
    final isUnlocked = current >= target || currentStreak >= target;

    return definition.copyWith(
      isUnlocked: isUnlocked,
      unlockedDate: isUnlocked ? streakData.lastPerfectDay : null,
      progress: progress,
      progressText: '${currentStreak} / $target days',
    );
  }

  /// Count total Jama'ah prayers
  Achievement _evaluateJamaahCount(
    Achievement definition,
    List<PrayerLog> logs,
    int target,
  ) {
    int count = 0;
    for (final log in logs) {
      for (final entry in log.entries.values) {
        if (entry.isJamaah) count++;
      }
    }

    final progress = (count / target).clamp(0.0, 1.0);
    final isUnlocked = count >= target;

    return definition.copyWith(
      isUnlocked: isUnlocked,
      unlockedDate: isUnlocked ? DateTime.now() : null,
      progress: progress,
      progressText: '$count / $target prayers',
    );
  }

  /// Check for any day where all Fardh prayers were on time
  Achievement _evaluatePerfectFardhDay(
    Achievement definition,
    List<PrayerLog> logs,
  ) {
    DateTime? unlockedDate;
    
    for (final log in logs) {
      final fardhOnTime = fardhPrayers.every((prayer) {
        final entry = log.entries[prayer];
        return entry != null && entry.status == PrayerStatus.onTime;
      });
      
      if (fardhOnTime) {
        unlockedDate = log.date;
        break;
      }
    }

    return definition.copyWith(
      isUnlocked: unlockedDate != null,
      unlockedDate: unlockedDate,
      progress: unlockedDate != null ? 1.0 : 0.0,
      progressText: unlockedDate != null ? 'Achieved!' : 'Not yet achieved',
    );
  }

  /// Check for any day where all Sunnah prayers were completed
  Achievement _evaluateAllSunnahDay(
    Achievement definition,
    List<PrayerLog> logs,
  ) {
    DateTime? unlockedDate;
    
    for (final log in logs) {
      // Get sunnah prayers that exist in this log
      final sunnahInLog = log.entries.keys.where((p) => p.isSunnah).toList();
      if (sunnahInLog.isEmpty) continue;
      
      final allSunnahOnTime = sunnahInLog.every((prayer) {
        final entry = log.entries[prayer];
        return entry != null && entry.status == PrayerStatus.onTime;
      });
      
      if (allSunnahOnTime) {
        unlockedDate = log.date;
        break;
      }
    }

    return definition.copyWith(
      isUnlocked: unlockedDate != null,
      unlockedDate: unlockedDate,
      progress: unlockedDate != null ? 1.0 : 0.0,
      progressText: unlockedDate != null ? 'Achieved!' : 'Not yet achieved',
    );
  }

  /// Check for Tahajjud 3+ times in last 7 days
  Achievement _evaluateTahajjudWeek(
    Achievement definition,
    List<PrayerLog> logs,
  ) {
    final recentLogs = logs.take(7).toList();
    int count = 0;
    
    for (final log in recentLogs) {
      final entry = log.entries[Prayer.tahajjud];
      if (entry != null && entry.status.isCompleted) {
        count++;
      }
    }

    final progress = (count / 3).clamp(0.0, 1.0);
    final isUnlocked = count >= 3;

    return definition.copyWith(
      isUnlocked: isUnlocked,
      unlockedDate: isUnlocked ? DateTime.now() : null,
      progress: progress,
      progressText: '$count / 3 this week',
    );
  }

  /// Check if user has completed at least one prayer ever
  Achievement _evaluateFirstPrayer(
    Achievement definition,
    List<PrayerLog> logs,
  ) {
    DateTime? firstCompletionDate;
    
    for (final log in logs.reversed) {
      for (final entry in log.entries.values) {
        if (entry.status.isCompleted) {
          firstCompletionDate = log.date;
          break;
        }
      }
      if (firstCompletionDate != null) break;
    }

    return definition.copyWith(
      isUnlocked: firstCompletionDate != null,
      unlockedDate: firstCompletionDate,
      progress: firstCompletionDate != null ? 1.0 : 0.0,
      progressText: firstCompletionDate != null ? 'Achieved!' : 'Complete your first prayer',
    );
  }

  /// Check for complete week (all prayers completed for 7 days)
  Achievement _evaluateWeekComplete(
    Achievement definition,
    List<PrayerLog> logs,
  ) {
    if (logs.length < 7) {
      return definition.copyWith(
        progress: logs.length / 7,
        progressText: '${logs.length} / 7 days tracked',
      );
    }

    int perfectDays = 0;
    for (final log in logs.take(7)) {
      final allCompleted = log.entries.values.every((e) => 
        e.status.isCompleted || e.status == PrayerStatus.upcoming
      );
      if (allCompleted) perfectDays++;
    }

    final isUnlocked = perfectDays >= 7;
    final progress = (perfectDays / 7).clamp(0.0, 1.0);

    return definition.copyWith(
      isUnlocked: isUnlocked,
      unlockedDate: isUnlocked ? DateTime.now() : null,
      progress: progress,
      progressText: '$perfectDays / 7 perfect days',
    );
  }

  // ============================================
  // STATISTICS CALCULATIONS
  // ============================================

  /// Get comprehensive statistics
  Map<String, dynamic> getStatistics() {
    final streakData = _storageService.getStreakData();
    final recentLogs = _storageService.getRecentPrayerLogs(30);
    final weekLogs = _storageService.getRecentPrayerLogs(7);

    // Calculate weekly stats
    int weekOnTime = 0;
    int weekTotal = 0;
    int weekMissed = 0;
    
    for (final log in weekLogs) {
      for (final entry in log.entries.values) {
        weekTotal++;
        if (entry.status == PrayerStatus.onTime) weekOnTime++;
        if (entry.status == PrayerStatus.missed) weekMissed++;
      }
    }

    // Calculate all-time stats
    int totalOnTime = 0;
    int totalCompleted = 0;
    int totalJamaah = 0;
    int totalPrayers = 0;
    
    for (final log in recentLogs) {
      for (final entry in log.entries.values) {
        totalPrayers++;
        if (entry.status.isCompleted) totalCompleted++;
        if (entry.status == PrayerStatus.onTime) totalOnTime++;
        if (entry.isJamaah) totalJamaah++;
      }
    }

    // Find best prayer (highest streak)
    String? bestPrayer;
    int bestStreak = 0;
    for (final prayer in fardhPrayers) {
      final streak = streakData.getPrayerStreak(prayer.name);
      if (streak > bestStreak) {
        bestStreak = streak;
        bestPrayer = prayer.displayName;
      }
    }

    return {
      'currentStreak': streakData.currentStreak,
      'longestStreak': streakData.longestStreak,
      'weekOnTime': weekOnTime,
      'weekTotal': weekTotal,
      'weekMissed': weekMissed,
      'weekPercentage': weekTotal > 0 ? (weekOnTime / weekTotal * 100).round() : 0,
      'totalOnTime': totalOnTime,
      'totalCompleted': totalCompleted,
      'totalJamaah': totalJamaah,
      'totalPrayers': totalPrayers,
      'bestPrayer': bestPrayer,
      'bestPrayerStreak': bestStreak,
      'prayerStreaks': streakData.prayerStreaks ?? {},
    };
  }
}
