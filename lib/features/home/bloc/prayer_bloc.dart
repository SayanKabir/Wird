import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/prayer.dart';
import '../../../models/prayer_status.dart';
import '../../../models/prayer_log.dart';
import '../../../models/settings.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/widget_service.dart';
import '../../../core/utils/islamic_day_utils.dart';

// ============================================
// EVENTS
// ============================================

abstract class PrayerEvent extends Equatable {
  const PrayerEvent();

  @override
  List<Object?> get props => [];
}

/// Load/reload prayer times
class LoadPrayers extends PrayerEvent {}

/// Update countdown timer
class UpdateCountdown extends PrayerEvent {}

/// Mark a prayer as completed
class MarkPrayerComplete extends PrayerEvent {
  final Prayer prayer;
  final bool isOnTime;
  final bool isJamaah;

  const MarkPrayerComplete({
    required this.prayer,
    required this.isOnTime,
    this.isJamaah = false,
  });

  @override
  List<Object?> get props => [prayer, isOnTime, isJamaah];
}

/// Toggle jama'ah (congregation) for a prayer
class ToggleJamaah extends PrayerEvent {
  final Prayer prayer;

  const ToggleJamaah({required this.prayer});

  @override
  List<Object?> get props => [prayer];
}

/// Refresh prayer times (e.g., after settings change)
class RefreshPrayerTimes extends PrayerEvent {}

/// Snooze notification for a prayer
class SnoozePrayer extends PrayerEvent {
  final Prayer prayer;
  final Duration duration;

  const SnoozePrayer({
    required this.prayer,
    required this.duration,
  });

  @override
  List<Object?> get props => [prayer, duration];
}

// ============================================
// STATES
// ============================================

abstract class PrayerState extends Equatable {
  const PrayerState();

  @override
  List<Object?> get props => [];
}

/// Initial loading state
class PrayerLoading extends PrayerState {}

/// Prayer data loaded successfully
class PrayerLoaded extends PrayerState {
  /// All prayer time data for today
  final Map<Prayer, PrayerTimeData> prayerTimes;
  
  /// List of enabled prayers (Fardh + enabled Sunnah)
  final List<Prayer> enabledPrayers;
  
  /// Current active prayer (within time window)
  final Prayer? currentPrayer;
  
  /// Next upcoming prayer
  final Prayer? nextPrayer;
  
  /// Countdown duration (to end if current, to start if next)
  final Duration countdown;
  
  /// Prayer statuses for today
  final Map<Prayer, PrayerEntry> statuses;
  
  /// Today's date
  final DateTime date;
  
  /// Current prayer period for gradient
  final PrayerPeriod prayerPeriod;
  
  /// Whether all prayers are complete
  final bool allComplete;
  
  /// Current streak count
  final int currentStreak;

  const PrayerLoaded({
    required this.prayerTimes,
    required this.enabledPrayers,
    this.currentPrayer,
    this.nextPrayer,
    required this.countdown,
    required this.statuses,
    required this.date,
    required this.prayerPeriod,
    this.allComplete = false,
    this.currentStreak = 0,
  });

  @override
  List<Object?> get props => [
    prayerTimes,
    enabledPrayers,
    currentPrayer,
    nextPrayer,
    countdown,
    statuses,
    date,
    prayerPeriod,
    allComplete,
    currentStreak,
  ];

  PrayerLoaded copyWith({
    Map<Prayer, PrayerTimeData>? prayerTimes,
    List<Prayer>? enabledPrayers,
    Prayer? currentPrayer,
    Prayer? nextPrayer,
    Duration? countdown,
    Map<Prayer, PrayerEntry>? statuses,
    DateTime? date,
    PrayerPeriod? prayerPeriod,
    bool? allComplete,
    int? currentStreak,
  }) {
    return PrayerLoaded(
      prayerTimes: prayerTimes ?? this.prayerTimes,
      enabledPrayers: enabledPrayers ?? this.enabledPrayers,
      currentPrayer: currentPrayer ?? this.currentPrayer,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      countdown: countdown ?? this.countdown,
      statuses: statuses ?? this.statuses,
      date: date ?? this.date,
      prayerPeriod: prayerPeriod ?? this.prayerPeriod,
      allComplete: allComplete ?? this.allComplete,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }

  /// Copy with explicit control over nullable prayer fields
  /// Use this when you need to set currentPrayer or nextPrayer to null
  PrayerLoaded copyWithPrayerUpdate({
    required Prayer? currentPrayer,
    required Prayer? nextPrayer,
    Map<Prayer, PrayerEntry>? statuses,
    Duration? countdown,
    bool? allComplete,
  }) {
    return PrayerLoaded(
      prayerTimes: prayerTimes,
      enabledPrayers: enabledPrayers,
      currentPrayer: currentPrayer,
      nextPrayer: nextPrayer,
      countdown: countdown ?? this.countdown,
      statuses: statuses ?? this.statuses,
      date: date,
      prayerPeriod: prayerPeriod,
      allComplete: allComplete ?? this.allComplete,
      currentStreak: currentStreak,
    );
  }
}

/// Error state
class PrayerError extends PrayerState {
  final String message;

  const PrayerError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ============================================
// BLOC
// ============================================

class PrayerBloc extends Bloc<PrayerEvent, PrayerState> {
  final PrayerService _prayerService;
  final StorageService _storageService;
  final NotificationService _notificationService;
  final WidgetService _widgetService = WidgetService();
  
  Timer? _countdownTimer;
  StreamSubscription<NotificationAction>? _notificationActionSub;

  PrayerBloc({
    PrayerService? prayerService,
    StorageService? storageService,
    NotificationService? notificationService,
  }) : _prayerService = prayerService ?? PrayerService(),
       _storageService = storageService ?? StorageService(),
       _notificationService = notificationService ?? NotificationService(),
       super(PrayerLoading()) {
    on<LoadPrayers>(_onLoadPrayers);
    on<UpdateCountdown>(_onUpdateCountdown);
    on<MarkPrayerComplete>(_onMarkPrayerComplete);
    on<ToggleJamaah>(_onToggleJamaah);
    on<RefreshPrayerTimes>(_onRefreshPrayerTimes);
    on<SnoozePrayer>(_onSnoozePrayer);

    // Listen for notification actions (snooze, mark prayed)
    _notificationActionSub = _notificationService.actionStream.listen(
      _handleNotificationAction,
    );
  }

  /// Handle notification action from the notification tray
  void _handleNotificationAction(NotificationAction action) {
    debugPrint('[PrayerBloc] Notification action: ${action.type} for ${action.prayerName}');
    try {
      final prayer = Prayer.values.byName(action.prayerName);

      switch (action.type) {
        case NotificationActionType.markPrayed:
          add(MarkPrayerComplete(prayer: prayer, isOnTime: true));
          break;
        case NotificationActionType.snooze:
          add(SnoozePrayer(
            prayer: prayer,
            duration: const Duration(minutes: 10),
          ));
          break;
        case NotificationActionType.open:
          // The app will come to foreground; no additional dispatch needed
          break;
      }
    } catch (e) {
      debugPrint('[PrayerBloc] Error handling notification action: $e');
    }
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _notificationActionSub?.cancel();
    return super.close();
  }

  /// Load prayer times and start countdown
  Future<void> _onLoadPrayers(
    LoadPrayers event,
    Emitter<PrayerState> emit,
  ) async {
    try {
      final settings = _storageService.getSettings();
      
      if (settings.location == null || !settings.location!.isValid) {
        emit(const PrayerError(
          message: 'Location not set. Please configure your location.',
        ));
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Calculate prayer times
      final prayerTimes = _prayerService.calculatePrayerTimes(
        date: today,
        location: settings.location!,
        calculationMethod: settings.calculationMethod,
        madhab: settings.madhab,
        includeTahajjud: settings.includeTahajjud,
        includeIshraq: settings.includeIshraq,
        includeDuha: settings.includeDuha,
      );

      // [PATCH] Early Morning Tahajjud Fix
      // If we are in the early morning (before Fajr), we might be in Yesterday's Tahajjud window.
      // Standard calculation returns "Tonight's" Tahajjud (which is actually tomorrow morning).
      // We need to check if we are currently in "Yesterday's" Tahajjud and use that instead.
      if (settings.includeTahajjud && 
          prayerTimes.containsKey(Prayer.fajr) && 
          now.isBefore(prayerTimes[Prayer.fajr]!.startTime)) {
        
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayTimes = _prayerService.calculatePrayerTimes(
          date: yesterday,
          location: settings.location!,
          calculationMethod: settings.calculationMethod,
          madhab: settings.madhab,
          includeTahajjud: true,
          includeIshraq: false,
          includeDuha: false,
        );

        final yesterdayTahajjud = yesterdayTimes[Prayer.tahajjud];
        if (yesterdayTahajjud != null && yesterdayTahajjud.isWithinWindow(now)) {
          // Replace future Tahajjud with current (yesterday's) Tahajjud
          prayerTimes[Prayer.tahajjud] = yesterdayTahajjud;
        }
      }

      // Get enabled prayers list
      final enabledPrayers = _getEnabledPrayers(settings);

      // Get current and next prayer
      final currentPrayer = _prayerService.getCurrentPrayer(prayerTimes, now);
      final nextPrayer = _prayerService.getNextPrayer(prayerTimes, now);

      // Get countdown
      final countdown = _prayerService.getCountdownDuration(prayerTimes, now);

      // Get current prayer period for gradient
      final prayerPeriod = _prayerService.getCurrentPrayerPeriod(prayerTimes, now);

      // Load or create today's prayer log
      var prayerLog = _storageService.getPrayerLog(today);
      if (prayerLog == null) {
        prayerLog = PrayerLog.forToday(
          enabledPrayers: enabledPrayers,
          currentPrayer: currentPrayer,
        );
        await _storageService.savePrayerLog(prayerLog);
      }

      // Check if all prayers are complete
      final allComplete = _checkAllComplete(prayerLog, enabledPrayers);
      
      // Load current streak
      final streakData = _storageService.getStreakData();
      final currentStreak = streakData.currentStreak;

      emit(PrayerLoaded(
        prayerTimes: prayerTimes,
        enabledPrayers: enabledPrayers,
        currentPrayer: currentPrayer,
        nextPrayer: nextPrayer,
        countdown: countdown,
        statuses: prayerLog.entries,
        date: today,
        prayerPeriod: prayerPeriod,
        allComplete: allComplete,
        currentStreak: currentStreak,
      ));

      // Update Widget
      final completedPrayers = _getCompletedPrayers(prayerLog);
      if (nextPrayer != null) {
        _widgetService.updateWidgetData(
          prayerTimes: prayerTimes,
          nextPrayer: nextPrayer,
          currentPrayer: currentPrayer,
          completedPrayers: completedPrayers,
          weatherData: null,
        );
      }

      // Schedule notifications for all prayers (excluding already completed ones)
      final canExact = await _notificationService.canScheduleExactAlarms();
      final maghribTime = prayerTimes[Prayer.maghrib]?.startTime;
      final isRamadan = IslamicDayUtils.isRamadanDate(now, maghribTime: maghribTime);
      debugPrint('[PrayerBloc] Scheduling notifications (exactAlarms=$canExact, ramadan=$isRamadan)');
      await _notificationService.scheduleAllDailyNotifications(
        prayerTimes: prayerTimes,
        settings: settings,
        completedPrayers: completedPrayers,
        isRamadan: isRamadan,
      );

      // Start countdown timer
      _startCountdownTimer();
    } catch (e) {
      emit(PrayerError(message: 'Failed to load prayers: $e'));
    }
  }

  /// Update countdown timer
  void _onUpdateCountdown(
    UpdateCountdown event,
    Emitter<PrayerState> emit,
  ) {
    final currentState = state;
    if (currentState is PrayerLoaded) {
      final now = DateTime.now();
      
      if (currentState.date.day != now.day || 
          currentState.date.month != now.month || 
          currentState.date.year != now.year) {
        add(LoadPrayers());
        return;
      }

      // Check if we've crossed into a new prayer period
      final newCurrentPrayer = _prayerService.getCurrentPrayer(
        currentState.prayerTimes, now,
      );
      final newNextPrayer = _prayerService.getNextPrayer(
        currentState.prayerTimes, now,
      );
      final newCountdown = _prayerService.getCountdownDuration(
        currentState.prayerTimes, now,
      );
      final newPeriod = _prayerService.getCurrentPrayerPeriod(
        currentState.prayerTimes, now,
      );

      // Update statuses if prayer has ended
      var updatedStatuses = Map<Prayer, PrayerEntry>.from(currentState.statuses);
      bool statusChanged = false;

      for (final prayer in currentState.enabledPrayers) {
        final timeData = currentState.prayerTimes[prayer];
        final entry = updatedStatuses[prayer];
        
        if (timeData != null && entry != null) {
          // If prayer time has ended and still pending or upcoming, mark as missed
          if (now.isAfter(timeData.endTime) && 
              (entry.status == PrayerStatus.pending ||
               entry.status == PrayerStatus.upcoming)) {
            updatedStatuses[prayer] = PrayerEntry.missed();
            statusChanged = true;
          }
          // If prayer hasn't started yet, ensure it's upcoming
          else if (now.isBefore(timeData.startTime) && 
                   entry.status != PrayerStatus.upcoming &&
                   !entry.status.isCompleted) {
            updatedStatuses[prayer] = PrayerEntry.upcoming();
            statusChanged = true;
          }
          // If prayer has started and was upcoming, make it pending
          else if (now.isAfter(timeData.startTime) && 
                   now.isBefore(timeData.endTime) &&
                   entry.status == PrayerStatus.upcoming) {
            updatedStatuses[prayer] = PrayerEntry.pending();
            statusChanged = true;
          }
        }
      }

      // Save if statuses changed
      if (statusChanged) {
        final updatedLog = currentState.prayerTimes.isNotEmpty
            ? PrayerLog(
                date: currentState.date,
                entries: updatedStatuses,
              )
            : null;
        if (updatedLog != null) {
          _storageService.savePrayerLog(updatedLog);
        }
      }

      final allComplete = _checkAllComplete(
        PrayerLog(date: currentState.date, entries: updatedStatuses),
        currentState.enabledPrayers,
      );

      emit(currentState.copyWith(
        currentPrayer: newCurrentPrayer,
        nextPrayer: newNextPrayer,
        countdown: newCountdown,
        statuses: updatedStatuses,
        prayerPeriod: newPeriod,
        allComplete: allComplete,
      ));
    }
  }
  /// Mark prayer as complete
  Future<void> _onMarkPrayerComplete(
    MarkPrayerComplete event,
    Emitter<PrayerState> emit,
  ) async {
    final currentState = state;
    if (currentState is PrayerLoaded) {
      final entry = PrayerEntry.completed(
        isOnTime: event.isOnTime,
        isJamaah: event.isJamaah,
      );

      final updatedStatuses = Map<Prayer, PrayerEntry>.from(currentState.statuses);
      updatedStatuses[event.prayer] = entry;

      // Save to storage
      final updatedLog = PrayerLog(
        date: currentState.date,
        entries: updatedStatuses,
      );
      await _storageService.savePrayerLog(updatedLog);

      // Cancel notifications for this prayer
      await _notificationService.cancelPrayerNotifications(event.prayer);

      // Update streak
      await _updateStreakData(updatedStatuses, currentState.enabledPrayers);

      final allComplete = _checkAllComplete(updatedLog, currentState.enabledPrayers);

      // Recalculate current and next prayer after marking complete
      final now = DateTime.now();
      
      // Find next incomplete prayer
      Prayer? newCurrentPrayer;
      Prayer? newNextPrayer;
      
      // Check if there's still a current prayer window active that's not completed
      for (final prayer in currentState.enabledPrayers) {
        final timeData = currentState.prayerTimes[prayer];
        final prayerEntry = updatedStatuses[prayer];
        if (timeData != null && 
            timeData.isWithinWindow(now) && 
            prayerEntry != null && 
            !prayerEntry.status.isCompleted) {
          newCurrentPrayer = prayer;
          break;
        }
      }
      
      // Find next upcoming prayer
      if (newCurrentPrayer == null) {
        for (final prayer in currentState.enabledPrayers) {
          final timeData = currentState.prayerTimes[prayer];
          final prayerEntry = updatedStatuses[prayer];
          if (timeData != null && 
              timeData.startTime.isAfter(now) &&
              (prayerEntry == null || !prayerEntry.status.isCompleted)) {
            newNextPrayer = prayer;
            break;
          }
        }
      }

      // Recalculate countdown
      Duration newCountdown = Duration.zero;
      if (newCurrentPrayer != null) {
        final timeData = currentState.prayerTimes[newCurrentPrayer];
        if (timeData != null) {
          newCountdown = timeData.endTime.difference(now);
        }
      } else if (newNextPrayer != null) {
        // Use the new method that handles next-day prayers
        newCountdown = _prayerService.getCountdownToNextPrayer(
          currentState.prayerTimes,
          now,
          newNextPrayer,
        );
      }

      emit(currentState.copyWithPrayerUpdate(
        statuses: updatedStatuses,
        allComplete: allComplete,
        currentPrayer: newCurrentPrayer,
        nextPrayer: newNextPrayer,
        countdown: newCountdown,
      ));
    }
  }

  /// Toggle jama'ah status
  Future<void> _onToggleJamaah(
    ToggleJamaah event,
    Emitter<PrayerState> emit,
  ) async {
    final currentState = state;
    if (currentState is PrayerLoaded) {
      final currentEntry = currentState.statuses[event.prayer];
      if (currentEntry != null && currentEntry.status.isCompleted) {
        final updatedEntry = currentEntry.copyWith(
          isJamaah: !currentEntry.isJamaah,
        );

        final updatedStatuses = Map<Prayer, PrayerEntry>.from(currentState.statuses);
        updatedStatuses[event.prayer] = updatedEntry;

        // Save to storage
        final updatedLog = PrayerLog(
          date: currentState.date,
          entries: updatedStatuses,
        );
        await _storageService.savePrayerLog(updatedLog);

        emit(currentState.copyWith(statuses: updatedStatuses));
      }
    }
  }

  /// Refresh prayer times
  Future<void> _onRefreshPrayerTimes(
    RefreshPrayerTimes event,
    Emitter<PrayerState> emit,
  ) async {
    add(LoadPrayers());
  }

  /// Handle snooze
  /// Snooze scheduling is now handled directly by the notification service
  /// (both foreground and background). This handler is kept for completeness /
  /// future use but is effectively a no-op.
  Future<void> _onSnoozePrayer(
    SnoozePrayer event,
    Emitter<PrayerState> emit,
  ) async {
    debugPrint('[PrayerBloc] Snooze handled directly by notification service');
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  List<Prayer> _getEnabledPrayers(AppSettings settings) {
    final prayers = <Prayer>[];
    
    // Add Sunnah prayers based on settings
    if (settings.includeTahajjud) prayers.add(Prayer.tahajjud);
    
    // Add Fardh prayers (always enabled)
    prayers.add(Prayer.fajr);
    
    if (settings.includeIshraq) prayers.add(Prayer.ishraq);
    if (settings.includeDuha) prayers.add(Prayer.duha);
    
    prayers.add(Prayer.dhuhr);
    prayers.add(Prayer.asr);
    prayers.add(Prayer.maghrib);
    prayers.add(Prayer.isha);
    
    return prayers;
  }

  bool _checkAllComplete(PrayerLog log, List<Prayer> enabledPrayers) {
    for (final prayer in enabledPrayers) {
      final entry = log.entries[prayer];
      if (entry == null || !entry.status.isCompleted) {
        return false;
      }
    }
    return true;
  }

  Future<void> _scheduleNotifications(
    Map<Prayer, PrayerTimeData> prayerTimes,
    AppSettings settings,
  ) async {
    if (!settings.notificationsEnabled) return;

    final now = DateTime.now();

    for (final entry in prayerTimes.entries) {
      final prayer = entry.key;
      final timeData = entry.value;
      
      // Check per-prayer notification settings, default to enabled
      final prayerNotifSettings = settings.notificationSettings[prayer.name]
          ?? const PrayerNotificationSettings();
      
      // Skip if this prayer has notifications explicitly disabled
      if (!prayerNotifSettings.startNotification) {
        continue;
      }

      // Only schedule for future prayers
      if (timeData.startTime.isAfter(now)) {
        await _notificationService.scheduleStartNotification(
          prayer: prayer,
          time: timeData.startTime,
          endTime: timeData.endTime,
        );
      }

      // Schedule end warning only if enabled for this prayer
      if (prayerNotifSettings.endWarning) {
        final warningTime = timeData.endTime.subtract(
          Duration(minutes: settings.endTimeWarningMinutes),
        );
        if (warningTime.isAfter(now)) {
          await _notificationService.scheduleEndWarning(
            prayer: prayer,
            endTime: timeData.endTime,
            minutesBefore: settings.endTimeWarningMinutes,
          );
        }
      }
    }
  }

  /// Get set of already completed prayers from prayer log
  Set<Prayer> _getCompletedPrayers(PrayerLog log) {
    final completed = <Prayer>{};
    for (final entry in log.entries.entries) {
      if (entry.value.status.isCompleted) {
        completed.add(entry.key);
      }
    }
    return completed;
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(UpdateCountdown()),
    );
  }

  Future<void> _updateStreakData(
    Map<Prayer, PrayerEntry> statuses,
    List<Prayer> enabledPrayers,
  ) async {
    // Get enabled Fardh prayers
    final enabledFardh = enabledPrayers.where((p) => p.isFardh).toList();
    final enabledSunnah = enabledPrayers.where((p) => p.isSunnah).toList();

    // Check if all Fardh are on time
    final allFardhOnTime = enabledFardh.every((p) => 
      statuses[p]?.status == PrayerStatus.onTime);
    
    // Check if all enabled Sunnah are on time
    final allSunnahOnTime = enabledSunnah.every((p) =>
      statuses[p]?.status == PrayerStatus.onTime);

    final isPerfectDay = allFardhOnTime && allSunnahOnTime;

    // Create prayer on-time map
    final prayerOnTime = <Prayer, bool>{};
    for (final prayer in enabledPrayers) {
      prayerOnTime[prayer] = statuses[prayer]?.status == PrayerStatus.onTime;
    }

    await _storageService.updateStreak(
      isPerfectDay: isPerfectDay,
      prayerOnTime: prayerOnTime,
    );
  }
}
