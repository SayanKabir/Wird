import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../models/prayer.dart';
import '../../models/settings.dart';
import '../utils/islamic_day_utils.dart';
import 'prayer_service.dart';

import 'package:flutter_timezone/flutter_timezone.dart';

/// Types of notification actions the user can take
enum NotificationActionType { snooze, markPrayed, open }

/// Represents a notification action taken by the user
class NotificationAction {
  final NotificationActionType type;
  final String prayerName;

  const NotificationAction({required this.type, required this.prayerName});
}

/// Notification service for scheduling prayer reminders
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  
  /// Singleton instance
  static NotificationService? _instance;
  
  factory NotificationService() {
    _instance ??= NotificationService._internal(
      FlutterLocalNotificationsPlugin(),
    );
    return _instance!;
  }
  
  NotificationService._internal(this._notificationsPlugin);

  /// Stream controller for notification actions (bridge to BLoC)
  final StreamController<NotificationAction> _actionController =
      StreamController<NotificationAction>.broadcast();

  /// Stream of notification actions for the BLoC to listen to
  Stream<NotificationAction> get actionStream => _actionController.stream;

  /// Dispose resources
  void dispose() {
    _actionController.close();
  }

  /// Notification channel for prayer times
  static const String _prayerChannelId = 'prayer_times';
  static const String _prayerChannelName = 'Prayer Time Notifications';
  static const String _prayerChannelDesc = 'Notifications for prayer times';

  /// Notification channel for warnings
  static const String _warningChannelId = 'prayer_warnings';
  static const String _warningChannelName = 'Prayer End Warnings';
  static const String _warningChannelDesc = 'Warnings before prayer time ends';

  /// Notification channel for sunnah reminders
  static const String _sunnahChannelId = 'sunnah_reminders';
  static const String _sunnahChannelName = 'Sunnah Reminders';
  static const String _sunnahChannelDesc = 'Weekly sunnah of the week reminder';

  /// Notification channel for islamic events
  static const String _eventChannelId = 'islamic_events';
  static const String _eventChannelName = 'Islamic Events';
  static const String _eventChannelDesc = 'Notifications for special Islamic days';

  static final _random = Random();

  /// Motivational messages per prayer
  static const Map<Prayer, List<String>> _motivationalMessages = {
    Prayer.tahajjud: [
      'Sad and depressed? Talk to Allah in Qiyam',
      'The night is still, rise and connect with your Lord',
      'The last third of the night — when dua is accepted',
      'Stand before Allah while the world sleeps',
    ],
    Prayer.fajr: [
      'Shake off your sleep and offer Fajr!',
      'Start your day with the remembrance of Allah',
      'The early morning prayer is worth more than the world',
      'Wake up and earn the protection of Allah',
      'Prayer is better than sleep',
    ],
    Prayer.ishraq: [
      'We hope you have a great day!',
      'Begin your morning with gratitude',
      'A beautiful morning to remember Allah',
    ],
    Prayer.duha: [
      'Take a moment to pray and recharge',
      'A few minutes of prayer, a day of blessings',
      'Charity of the morning — pray Duha',
    ],
    Prayer.dhuhr: [
      'Life is short, pray on time!',
      'Pause your day and connect with Allah',
      'Take a break from the world, stand with your Creator',
      'A moment of prayer is worth hours of worry',
    ],
    Prayer.asr: [
      'Worries end when Salah begins',
      'Guard the middle prayer — Surah Al-Baqarah',
      'Do not let the afternoon pass without prayer',
      'Pause and reflect before the day ends',
    ],
    Prayer.maghrib: [
      'When in doubt, offer salah and talk to Allah',
      'The sun has set, turn to your Lord',
      'Hasten to pray Maghrib before the twilight fades',
      'End your day\'s work with prayer',
    ],
    Prayer.isha: [
      'Are you strong enough to defeat your nafs and offer Isha on time?',
      'Close your day with Isha prayer',
      'Pray Isha and sleep with a clear conscience',
      'One last prayer before the night — make it count',
    ],
  };

  /// End-time warning messages
  static const List<String> _endWarningMessages = [
    'Do not delay — pray before the time is up',
    'Time is running out, hasten to prayer',
    'The prayer window is closing soon',
    'Pray now, there may not be another chance',
  ];

  /// Get a random motivational message for a prayer
  static String _getMotivationalMessage(Prayer prayer) {
    final messages = _motivationalMessages[prayer] ?? ['It\'s time to pray'];
    return messages[_random.nextInt(messages.length)];
  }

  /// Get a random end warning message
  static String _getEndWarningMessage() {
    return _endWarningMessages[_random.nextInt(_endWarningMessages.length)];
  }

  /// Format time as 12-hour string (e.g., "05:04 AM")
  static String _formatTime12h(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Initialize the notification service
  Future<void> init() async {
    // Initialize timezone database
    tz_data.initializeTimeZones();

    // Get and set local timezone
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('[Notifications] Local timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('[Notifications] Could not set local timezone: $e');
      // Fallback to UTC or a default if critical, but usually this works if DB is init
    }

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels (Android 8.0+)
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Prayer start channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _prayerChannelId,
          _prayerChannelName,
          description: _prayerChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );

      // Warning channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _warningChannelId,
          _warningChannelName,
          description: _warningChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Sunnah reminders channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _sunnahChannelId,
          _sunnahChannelName,
          description: _sunnahChannelDesc,
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Islamic events channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _eventChannelId,
          _eventChannelName,
          description: _eventChannelDesc,
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  /// Handle notification tap or action button press
  void _onNotificationTapped(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    debugPrint('[Notifications] Action received: actionId=$actionId, payload=$payload');

    // Parse prayer name from payload (format: "prayer_start:fajr" or "prayer_warning:fajr")
    String? prayerName;
    if (payload != null && payload.contains(':')) {
      prayerName = payload.split(':').last;
    }

    if (prayerName == null) {
      debugPrint('[Notifications] Could not parse prayer name from payload');
      return;
    }

    if (actionId == 'mark_prayed') {
      debugPrint('[Notifications] Mark as prayed: $prayerName');
      _actionController.add(NotificationAction(
        type: NotificationActionType.markPrayed,
        prayerName: prayerName,
      ));
    } else if (actionId == 'snooze_10') {
      debugPrint('[Notifications] Snooze 10 min: $prayerName');
      _actionController.add(NotificationAction(
        type: NotificationActionType.snooze,
        prayerName: prayerName,
      ));
    } else {
      // Default tap (no specific action) — open app
      debugPrint('[Notifications] Open app for: $prayerName');
      _actionController.add(NotificationAction(
        type: NotificationActionType.open,
        prayerName: prayerName,
      ));
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    
    return false;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Check if exact alarms are permitted (Android 12+)
  /// Returns true on iOS or if permission is granted on Android
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      return await androidPlugin?.canScheduleExactNotifications() ?? false;
    }
    return true; // iOS doesn't need this permission
  }

  /// Request exact alarm permission (Android 12+)
  /// Opens system settings for the user to grant permission
  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      // This opens the alarm settings screen on Android 12+
      await androidPlugin?.requestExactAlarmsPermission();
      
      // Re-check permission after user returns
      return await canScheduleExactAlarms();
    }
    return true;
  }

  /// Check all required permissions for notifications
  /// Returns a map with permission statuses
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'notifications': await areNotificationsEnabled(),
      'exactAlarms': await canScheduleExactAlarms(),
    };
  }

  /// Determine the best available schedule mode.
  /// Returns exact mode if permitted, otherwise falls back to inexact.
  /// Wrapped in try-catch to handle edge cases on newer Android versions.
  Future<AndroidScheduleMode> _getScheduleMode() async {
    try {
      if (Platform.isAndroid) {
        final canExact = await canScheduleExactAlarms();
        if (canExact) {
          debugPrint('[Notifications] Using EXACT schedule mode');
          return AndroidScheduleMode.exactAllowWhileIdle;
        }
      } else {
        // iOS doesn't need this distinction
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (e) {
      debugPrint('[Notifications] ⚠️ Error checking exact alarm permission: $e');
    }
    debugPrint('[Notifications] Using INEXACT schedule mode (fallback)');
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Resilient wrapper around zonedSchedule that retries with inexact mode
  /// if exact mode throws (e.g. SecurityException on Android 14+/16).
  Future<bool> _zonedScheduleSafe({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final scheduleMode = await _getScheduleMode();

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      debugPrint('[Notifications] ✅ Scheduled ID=$id (mode=$scheduleMode)');
      return true;
    } catch (e) {
      debugPrint('[Notifications] ⚠️ Failed with $scheduleMode: $e');

      // If we tried exact mode and it failed, retry with inexact
      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        try {
          debugPrint('[Notifications] 🔄 Retrying ID=$id with INEXACT mode');
          await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
            matchDateTimeComponents: matchDateTimeComponents,
          );
          debugPrint('[Notifications] ✅ Retry succeeded ID=$id (inexact)');
          return true;
        } catch (retryError) {
          debugPrint('[Notifications] ❌ Retry also failed ID=$id: $retryError');
          return false;
        }
      }
      debugPrint('[Notifications] ❌ Failed to schedule ID=$id: $e');
      return false;
    }
  }

  /// Schedule a prayer start notification
  Future<void> scheduleStartNotification({
    required Prayer prayer,
    required DateTime time,
  }) async {
    final id = _getNotificationId(prayer, isStart: true);
    final displayName = prayer.displayNameForDay(time);
    final scheduledTime = tz.TZDateTime.from(time, tz.local);
    final timeStr = _formatTime12h(time);
    final motivational = _getMotivationalMessage(prayer);
    
    debugPrint('[Notifications] Scheduling START ID=$id for $displayName at $scheduledTime');

    await _zonedScheduleSafe(
      id: id,
      title: "It's time to offer $displayName $timeStr",
      body: motivational,
      scheduledDate: scheduledTime,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          _prayerChannelName,
          channelDescription: _prayerChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          actions: [
            const AndroidNotificationAction(
              'mark_prayed',
              "I've Prayed",
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'snooze_10',
              'Snooze 10 min',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'prayer_start:${prayer.name}',
    );
  }

  /// Schedule an end-time warning notification
  Future<void> scheduleEndWarning({
    required Prayer prayer,
    required DateTime endTime,
    int minutesBefore = 15,
  }) async {
    final warningTime = endTime.subtract(Duration(minutes: minutesBefore));
    
    // Don't schedule if warning time is in the past
    if (warningTime.isBefore(DateTime.now())) {
      return;
    }

    final id = _getNotificationId(prayer, isStart: false);
    final displayName = prayer.displayNameForDay(endTime);
    final warningMsg = _getEndWarningMessage();

    await _zonedScheduleSafe(
      id: id,
      title: '$displayName ending in $minutesBefore minutes',
      body: warningMsg,
      scheduledDate: tz.TZDateTime.from(warningTime, tz.local),
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          _warningChannelId,
          _warningChannelName,
          channelDescription: _warningChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          actions: [
            const AndroidNotificationAction(
              'mark_prayed',
              "I've Prayed",
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'prayer_warning:${prayer.name}',
    );
  }

  /// Schedule snooze notification
  Future<void> scheduleSnooze({
    required Prayer prayer,
    required Duration duration,
    required DateTime prayerEndTime,
  }) async {
    // Cap snooze duration to not exceed prayer end time
    var snoozeTime = DateTime.now().add(duration);
    if (snoozeTime.isAfter(prayerEndTime)) {
      final remaining = prayerEndTime.difference(DateTime.now());
      if (remaining.isNegative) return; // Prayer already ended
      snoozeTime = DateTime.now().add(remaining);
    }

    final id = _getNotificationId(prayer, isStart: true);
    final displayName = prayer.displayNameForDay(snoozeTime);
    final motivational = _getMotivationalMessage(prayer);

    await _zonedScheduleSafe(
      id: id,
      title: '$displayName — Don\'t forget to pray!',
      body: motivational,
      scheduledDate: tz.TZDateTime.from(snoozeTime, tz.local),
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          _prayerChannelName,
          channelDescription: _prayerChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            const AndroidNotificationAction(
              'mark_prayed',
              "I've Prayed",
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'snooze_10',
              'Snooze 10 min',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'prayer_snooze:${prayer.name}',
    );
  }

  /// Cancel notification for a prayer
  Future<void> cancelPrayerNotifications(Prayer prayer) async {
    await _notificationsPlugin.cancel(_getNotificationId(prayer, isStart: true));
    await _notificationsPlugin.cancel(_getNotificationId(prayer, isStart: false));
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel sunnah weekly notification
  Future<void> cancelSunnahNotifications() async {
    await _notificationsPlugin.cancel(200);
  }

  /// Cancel islamic event notification
  Future<void> cancelEventNotifications() async {
    await _notificationsPlugin.cancel(300);
  }

  // ─────────────── Sunnah & Islamic Event Notifications ───────────────

  /// Schedule a recurring weekly sunnah reminder (every Monday at 9 AM).
  Future<void> scheduleWeeklySunnahReminder(String sunnahTitle) async {
    final now = tz.TZDateTime.now(tz.local);
    // Next Monday at 9:00 AM
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, 9,
    );
    // Advance to next Monday
    while (scheduled.weekday != DateTime.monday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    debugPrint('[Notifications] Scheduling weekly sunnah reminder at $scheduled');

    await _zonedScheduleSafe(
      id: 200,
      title: '📿 Sunnah of the Week',
      body: 'This week\'s sunnah: $sunnahTitle — try to practice it daily!',
      scheduledDate: scheduled,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          _sunnahChannelId,
          _sunnahChannelName,
          channelDescription: _sunnahChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'sunnah_weekly',
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Schedule a daily Islamic event check (8 AM each day).
  /// If today is a special day, shows a notification; otherwise silent.
  Future<void> scheduleSpecialDayNotification() async {
    // Check if today is a special day
    final today = DateTime.now();
    final message = IslamicDayUtils.messageForDate(today);
    if (message == null) {
      debugPrint('[Notifications] No special Islamic day today, skipping');
      return;
    }

    // Schedule an immediate-ish notification for today's event
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(const Duration(seconds: 5));

    debugPrint('[Notifications] Scheduling special day notification: ${message.title}');

    await _zonedScheduleSafe(
      id: 300,
      title: '🌙 ${message.title}',
      body: message.subtitle,
      scheduledDate: scheduled,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          _eventChannelId,
          _eventChannelName,
          channelDescription: _eventChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          category: AndroidNotificationCategory.event,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'islamic_event',
    );
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Generate unique notification ID for a prayer
  int _getNotificationId(Prayer prayer, {required bool isStart}) {
    // Use prayer index * 10 + 0/1 for start/warning
    final prayerIndex = Prayer.values.indexOf(prayer);
    return prayerIndex * 10 + (isStart ? 0 : 1);
  }

  /// Show a test notification immediately
  Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      999,
      '🕌 Test Notification',
      'Prayer notifications are working!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          _prayerChannelName,
          channelDescription: _prayerChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Schedule all notifications for today's prayers
  /// This is the main method to call when the app starts or settings change
  Future<void> scheduleAllDailyNotifications({
    required Map<Prayer, PrayerTimeData> prayerTimes,
    required AppSettings settings,
    Set<Prayer>? completedPrayers,
  }) async {
    debugPrint('[Notifications] ========== SCHEDULING START ==========');
    debugPrint('[Notifications] Global notifications enabled: ${settings.notificationsEnabled}');
    debugPrint('[Notifications] Prayer times count: ${prayerTimes.length}');
    debugPrint('[Notifications] Completed prayers: ${completedPrayers?.map((p) => p.name).join(", ") ?? "none"}');
    
    if (!settings.notificationsEnabled) {
      debugPrint('[Notifications] ❌ Notifications disabled globally, cancelling all');
      await cancelAllNotifications();
      return;
    }

    final now = DateTime.now();
    debugPrint('[Notifications] Current time: $now');
    final completed = completedPrayers ?? <Prayer>{};

    for (final entry in prayerTimes.entries) {
      final prayer = entry.key;
      final timeData = entry.value;

      debugPrint('[Notifications] --- ${prayer.name} ---');
      debugPrint('[Notifications]   Start: ${timeData.startTime}');
      debugPrint('[Notifications]   End: ${timeData.endTime}');

      // Skip if prayer is already completed
      if (completed.contains(prayer)) {
        debugPrint('[Notifications]   ⏭️ Skipped (already completed)');
        await cancelPrayerNotifications(prayer);
        continue;
      }

      // Get per-prayer notification settings, use defaults if not configured
      final prayerSettings = settings.notificationSettings[prayer.name] 
          ?? const PrayerNotificationSettings();
      
      debugPrint('[Notifications]   Start notification enabled: ${prayerSettings.startNotification}');
      debugPrint('[Notifications]   End warning enabled: ${prayerSettings.endWarning}');
      
      // Skip if start notifications explicitly disabled for this prayer
      if (!prayerSettings.startNotification) {
        debugPrint('[Notifications]   ⏭️ Skipped (start notification disabled)');
        await cancelPrayerNotifications(prayer);
        continue;
      }

      // Schedule start notification if prayer time is in the future
      if (timeData.startTime.isAfter(now)) {
        debugPrint('[Notifications]   ✅ Scheduling START notification for ${timeData.startTime}');
        await scheduleStartNotification(
          prayer: prayer,
          time: timeData.startTime,
        );
      } else {
        debugPrint('[Notifications]   ⏭️ Start time already passed');
      }

      // Schedule end warning if enabled and time is in the future
      if (prayerSettings.endWarning) {
        final warningTime = timeData.endTime.subtract(
          Duration(minutes: settings.endTimeWarningMinutes),
        );
        if (warningTime.isAfter(now)) {
          debugPrint('[Notifications]   ✅ Scheduling END WARNING for $warningTime');
          await scheduleEndWarning(
            prayer: prayer,
            endTime: timeData.endTime,
            minutesBefore: settings.endTimeWarningMinutes,
          );
        } else {
          debugPrint('[Notifications]   ⏭️ Warning time already passed');
        }
      }
    }
    
    await debugPrintPendingNotifications();
    debugPrint('[Notifications] ========== SCHEDULING COMPLETE ==========');
  }

  /// Schedule a daily refresh notification that will trigger rescheduling
  /// This schedules a "silent" notification at midnight to prompt rescheduling
  Future<void> scheduleMidnightRefresh() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final midnightTime = tomorrow.add(const Duration(minutes: 1)); // 12:01 AM

    const id = 9999; // Special ID for refresh notification

    await _zonedScheduleSafe(
      id: id,
      title: '🌙 Wird',
      body: 'Prayer times updated for today',
      scheduledDate: tz.TZDateTime.from(midnightTime, tz.local),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          _prayerChannelName,
          channelDescription: _prayerChannelDesc,
          importance: Importance.low,
          priority: Priority.low,
          showWhen: false,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: 'daily_refresh',
      matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
    );
  }

  /// Cancel all notifications for today and reschedule
  Future<void> rescheduleAllNotifications({
    required Map<Prayer, PrayerTimeData> prayerTimes,
    required AppSettings settings,
    Set<Prayer>? completedPrayers,
  }) async {
    // Cancel all existing prayer notifications (except refresh)
    for (final prayer in Prayer.values) {
      await cancelPrayerNotifications(prayer);
    }

    // Schedule fresh notifications
    await scheduleAllDailyNotifications(
      prayerTimes: prayerTimes,
      settings: settings,
      completedPrayers: completedPrayers,
    );
  }

  /// Get count of pending notifications
  Future<int> getPendingNotificationCount() async {
    final pending = await getPendingNotifications();
    return pending.length;
  }

  /// Debug: Print all pending notifications
  Future<void> debugPrintPendingNotifications() async {
    final pending = await getPendingNotifications();
    debugPrint('[Notifications] === ${pending.length} PENDING NOTIFICATIONS ===');
    for (final notification in pending) {
      debugPrint('[Notifications]   ID=${notification.id}, Title="${notification.title}", Payload=${notification.payload}');
    }
    debugPrint('[Notifications] === END PENDING ===');
  }

  /// Schedule a test notification 10 seconds from now using zonedSchedule
  /// (NOT show()!) to verify that scheduled notifications work on this device.
  Future<bool> scheduleTestNotification() async {
    final testTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    debugPrint('[Notifications] 🧪 TEST: Scheduling test notification for $testTime');

    final result = await _zonedScheduleSafe(
      id: 9998, // Special test ID
      title: '✅ Scheduled notification works!',
      body: 'This was scheduled 10 seconds ago via zonedSchedule()',
      scheduledDate: testTime,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          _prayerChannelName,
          channelDescription: _prayerChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_scheduled',
    );

    debugPrint('[Notifications] 🧪 TEST: Schedule result = $result');
    await debugPrintPendingNotifications();
    return result;
  }
}
