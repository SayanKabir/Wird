import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/hijri_date.dart';
import '../../../core/utils/islamic_day_utils.dart';
import '../../../models/prayer.dart';
import '../../../models/prayer_status.dart';
import '../bloc/prayer_bloc.dart';
import '../../../core/services/prayer_service.dart' show PrayerPeriod;
import '../../../widgets/common/string_lights_overlay.dart';
import '../widgets/celestial_background.dart';
import '../widgets/countdown_timer.dart';
import 'schedule_view.dart';
import '../../sunnah/screens/sunnah_screen.dart';
import '../../quran/screens/quran_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../qibla/screens/qibla_screen.dart'; // Re-added
import '../../islamic_calendar/screens/islamic_calendar_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/debug_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/repositories/sunnah_repository.dart';
import '../../../models/settings.dart';
import '../../../widgets/common/premium_flowing_loader.dart';
import '../../tasbih/screens/tasbih_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 2);
  final NotificationService _notificationService = NotificationService();
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final DebugService _debugService = DebugService();
  final StorageService _storageService = StorageService();

  int _currentPage = 2;
  bool _showPermissionWarning = false;
  WeatherData? _weather;
  Timer? _weatherTimer;
  double _latitude = 0.0; // Default to equator if unknown

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _fetchWeather();
    _scheduleSunnahAndEventNotifications();

    // Refresh weather every 15 minutes
    _weatherTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _fetchWeather();
    });

    // Listen to debug overrides
    _debugService.overriddenWeather.addListener(_onDebugChanged);
    _debugService.overriddenMoonPhase.addListener(_onDebugChanged);
  }

  void _onDebugChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchWeather() async {
    final location = _locationService.getStoredLocation();
    if (location != null) {
      if (mounted) {
        setState(() => _latitude = location.latitude);
      }
      final weather = await _weatherService.getWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (mounted) {
        setState(() => _weather = weather);
      }
    }
  }

  Future<void> _checkPermissions() async {
    final canSchedule = await _notificationService.canScheduleExactAlarms();
    // Also check if user has not permanently dismissed this (could use storage, but for now session-based is fine)
    if (!canSchedule && mounted) {
      setState(() => _showPermissionWarning = true);
    }
  }

  Future<void> _scheduleSunnahAndEventNotifications() async {
    try {
      final settings = _storageService.getSettings();

      // Schedule weekly sunnah reminder
      if (settings.sunnahNotificationsEnabled) {
        final sunnahRepo = context.read<SunnahRepository>();
        final weeklySunnah = await sunnahRepo.getWeeklySunnah();
        await _notificationService.scheduleWeeklySunnahReminder(weeklySunnah.title);
      } else {
        await _notificationService.cancelSunnahNotifications();
      }

      // Schedule special Islamic day notification (if today is special)
      if (settings.islamicEventsEnabled) {
        await _notificationService.scheduleSpecialDayNotification();
      } else {
        await _notificationService.cancelEventNotifications();
      }
    } catch (e) {
      debugPrint('[HomeScreen] Failed to schedule sunnah/event notifications: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weatherTimer?.cancel();
    _debugService.overriddenWeather.removeListener(_onDebugChanged);
    _debugService.overriddenMoonPhase.removeListener(_onDebugChanged);
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    HapticFeedback.lightImpact();
  }

  void _navToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );
  }

  int _getDebugCloudCoverage(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return 0;
      case WeatherCondition.cloudy:
        return 90;
      case WeatherCondition.rain:
        return 100;
      case WeatherCondition.drizzle:
        return 70;
      case WeatherCondition.thunderstorm:
        return 100;
      case WeatherCondition.snow:
        return 100;
      case WeatherCondition.fog:
        return 40;
    }
  }

  WeatherData? _getEffectiveWeather(AppSettings settings) {
    // 1. Debug Override (Highest Priority)
    final debugOverride = _debugService.overriddenWeather.value;
    if (debugOverride != null) {
      return _createFakeWeather(debugOverride);
    }

    // 2. Static Theme (Medium Priority)
    if (settings.weatherTheme != WeatherTheme.auto) {
      final condition = _mapThemeToCondition(settings.weatherTheme);
      return _createFakeWeather(condition);
    }

    // 3. Live Weather (Lowest Priority)
    return _weather;
  }

  WeatherData _createFakeWeather(WeatherCondition condition) {
    return WeatherData(
      condition: condition,
      temperature: _weather?.temperature ?? 22.0,
      cloudCoverage: _getDebugCloudCoverage(condition),
      windSpeed: 5.0,
      fetchedAt: DateTime.now(),
    );
  }

  WeatherCondition _mapThemeToCondition(WeatherTheme theme) {
    switch (theme) {
      case WeatherTheme.clear:
        return WeatherCondition.clear;
      case WeatherTheme.cloudy:
        return WeatherCondition.cloudy;
      case WeatherTheme.rain:
        return WeatherCondition.rain;
      case WeatherTheme.thunderstorm:
        return WeatherCondition.thunderstorm;
      case WeatherTheme.snow:
        return WeatherCondition.snow;
      case WeatherTheme.fog:
        return WeatherCondition.fog;
      default:
        return WeatherCondition.clear;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _storageService.getSettingsListenable(),
      builder: (context, box, _) {
        // Fetch settings on every build (triggered by Settings update OR PrayerBloc)
        final settings = _storageService.getSettings();
        final effectiveWeather = _getEffectiveWeather(settings);

        return BlocBuilder<PrayerBloc, PrayerState>(
          builder: (context, state) {
            if (state is PrayerLoading) return const _LoadingView();
            if (state is PrayerError) return _ErrorView(message: state.message);

            if (state is PrayerLoaded) {
              return CelestialBackground(
                prayerPeriod: state.prayerPeriod,
                weatherCondition:
                    effectiveWeather?.condition ?? WeatherCondition.clear,
                cloudCoverage:
                    effectiveWeather != null
                        ? effectiveWeather.cloudCoverage
                        : 0,
                latitude: _latitude,
                fixedMoonPhase: _debugService.overriddenMoonPhase.value,
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  backgroundColor: Colors.transparent,
                  extendBody: true,
                  body: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const SettingsScreen(), // 0
                          const QuranScreen(), // 1
                          _DashboardView(
                            // 2 (Home)
                            state: state,
                            weather:
                                settings.showWeatherWidget
                                    ? effectiveWeather
                                    : null,
                            showIslamicEvents: settings.islamicEventsEnabled,
                          ),
                          ScheduleView(state: state), // 3
                          const SunnahScreen(), // 4
                          const QiblaScreen(), // 5
                          const StatisticsScreen(), // 6
                        ],
                      ),
                      // Floating Navigation Capsule
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                        child: Center(child: _buildMinimalIndicator(MediaQuery.sizeOf(context).width)),
                      ),

                      // Permission Warning Overlay
                      if (_showPermissionWarning)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: _buildPermissionWarning(),
                        ),
                    ],
                  ),
                ),
              );
            }

            return const _LoadingView();
          },
        );
      },
    );
  }

  Widget _buildMinimalIndicator(double screenWidth) {
    // Determine responsive sizing based on screen width
    final isSmallScreen = screenWidth < 380;
    final containerHeight = isSmallScreen ? 48.0 : 56.0;
    final horizontalPadding = isSmallScreen ? 4.0 : 6.0;
    final iconWidth = isSmallScreen ? 42.0 : 48.0;
    final iconHeight = isSmallScreen ? 40.0 : 44.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(32), // High curvature for capsule shape
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: containerHeight,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4), // Darker for contrast
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08), // Subtle glass edge
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Hug contents
                children: [
                  _buildIndicatorIcon(0, Icons.tune_rounded, iconWidth, iconHeight, iconSize), // Settings
                  _buildIndicatorIcon(1, Icons.menu_book_rounded, iconWidth, iconHeight, iconSize), // Quran
                  _buildIndicatorIcon(2, Icons.grid_view_rounded, iconWidth, iconHeight, iconSize), // Home
                  _buildIndicatorIcon(3, Icons.calendar_month_rounded, iconWidth, iconHeight, iconSize), // Schedule
                  _buildIndicatorIcon(4, Icons.auto_stories_rounded, iconWidth, iconHeight, iconSize), // Sunnah
                  _buildIndicatorIcon(5, Icons.explore_rounded, iconWidth, iconHeight, iconSize), // Qibla
                  _buildIndicatorIcon(6, Icons.bar_chart_rounded, iconWidth, iconHeight, iconSize), // Stats
                ],
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildIndicatorIcon(int index, IconData icon, double width, double height, double size) {
    final isSelected = _currentPage == index;

    return GestureDetector(
      onTap: () => _navToPage(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        width: width,
        height: height,
        alignment: Alignment.center,
        transform:
            Matrix4.identity()..scale(isSelected ? 1.1 : 1.0), // Subtle pop
        child: Icon(
          icon,
          size: size,
          color:
              isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
          // Add a subtle glow only to the active icon
          shadows:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                  : null,
        ),
      ),
    );
  }

  Widget _buildPermissionWarning() {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Permission Needed",
                          style: AppTextStyles.body(
                            color: Colors.white,
                            weight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Enable 'Alarms & reminders' for accurate prayer times.",
                          style: AppTextStyles.tiny(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _notificationService.requestExactAlarmPermission();
                      _checkPermissions();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("Fix"),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _showPermissionWarning = false),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final PrayerLoaded state;
  final WeatherData? weather;
  final bool showIslamicEvents;

  const _DashboardView({
    required this.state,
    this.weather,
    required this.showIslamicEvents,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final textColor = AppColors.getContentColor(state.prayerPeriod);
    final now = DateTime.now();
    final maghribTime = state.prayerTimes[Prayer.maghrib]?.startTime;
    final isRamadanMode = IslamicDayUtils.isRamadanDate(now, maghribTime: maghribTime);
    final nextEvent = IslamicDayUtils.nextImportantEvent(state.date);

    final sortedTimes =
        state.prayerTimes.entries.toList()
          ..sort((a, b) => a.value.startTime.compareTo(b.value.startTime));

    Prayer? derivedCurrent;
    Prayer? derivedNext;

    for (var entry in sortedTimes) {
      final p = entry.key;
      final times = entry.value;

      // Current: Now is inside the window
      if (now.isAfter(times.startTime) && now.isBefore(times.endTime)) {
        derivedCurrent = p;
      }

      // Next: First one starting after Now
      if (derivedNext == null && times.startTime.isAfter(now)) {
        derivedNext = p;
      }
    }

    final bool hasActivePrayer = derivedCurrent != null;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          if (isRamadanMode && showIslamicEvents)
            Positioned(
              top: screenHeight * 0.02,   // 2% of the screen height
              left: 0,
              right: 0,
              height: screenHeight * 0.18, // 18% of the screen height gives the cables room to hang
              child: const StringLightsOverlay(),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context, state.date, textColor, state.currentStreak, maghribTime),
                        // _buildSpecialDayBanner(state.date, textColor, maghribTime),
                        if (showIslamicEvents && !isRamadanMode && nextEvent != null)
                          _buildNextEventCountdown(nextEvent, textColor),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 24),

                                // SCENARIO A: Active Prayer Window
                                if (hasActivePrayer) ...[
                                  _CurrentPrayerSection(
                                    prayer: derivedCurrent!,
                                    state: state,
                                    textColor: textColor,
                                  ),

                                  const SizedBox(height: 32),

                                  Container(
                                    width: 100,
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          textColor.withValues(alpha: 0.0),
                                          textColor.withValues(alpha: 0.3),
                                          textColor.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  if (derivedNext != null)
                                    _NextPrayerSection(
                                      prayer: derivedNext,
                                      state: state,
                                      textColor: textColor,
                                      showLabel: true,
                                    ),
                                ]
                                // SCENARIO B: No Active Prayer (Waiting)
                                else ...[
                                  _WaitingForNextSection(
                                    nextPrayer: derivedNext,
                                    state: state,
                                    textColor: textColor,
                                    streak: state.currentStreak,
                                  ),
                                ],

                                // Bottom padding to clear the floating nav bar
                                SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      DateTime date,
      Color textColor,
      int streak,
      DateTime? maghribTime,
      ) {
    final now = DateTime.now();
    final hijri = HijriDate.fromDateTime(now, maghribTime: maghribTime);
    final todayEvent = IslamicDayUtils.messageForDate(now, maghribTime: maghribTime);
    final hasEvent = todayEvent != null;
    final accentColor = hasEvent
        ? IslamicDayUtils.accentColor(todayEvent.type)
        : textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () => _openIslamicCalendar(context, date),
              behavior: HitTestBehavior.opaque,
              // Start Glassmorphism implementation
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      // Made the gradient more subtle and translucent for glass effect
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: hasEvent ? 0.12 : 0.1),
                          accentColor.withValues(alpha: hasEvent ? 0.05 : 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      // Made border slightly crisper but still transparent
                      border: Border.all(
                        color: accentColor.withValues(alpha: hasEvent ? 0.3 : 0.15),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            // Slightly adjusted opacity for the icon background to pop on glass
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            hasEvent
                                ? IslamicDayUtils.iconForType(todayEvent.type)
                                : Icons.calendar_month_rounded,
                            size: 16,
                            color: accentColor.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible( // Added Flexible here to prevent overflow on small screens
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${hijri.day} ${hijri.monthNameEnglish} ${hijri.year}',
                                style: AppTextStyles.small(
                                  color: textColor.withValues(alpha: 0.95),
                                  weight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasEvent ? todayEvent.title : 'Islamic Calendar',
                                style: AppTextStyles.tiny(
                                  color: hasEvent
                                      ? accentColor
                                      : textColor.withValues(alpha: 0.6),
                                ).copyWith(
                                    fontWeight:
                                    hasEvent ? FontWeight.w600 : FontWeight.w400),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // End Glassmorphism implementation
            ),
          ),
          // ... (Rest of the Row remains unchanged: Weather and Streak widgets)
          Row(
            children: [
              // Weather Widget
              if (weather != null) ...[
                _buildWeatherWidget(weather!, textColor),
                if (streak > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 1,
                    height: 16,
                    color: textColor.withValues(alpha: 0.2),
                  ),
              ],

              // Streak Widget
              if (streak > 0)
                Row(
                  children: [
                    Text('$streak', style: AppTextStyles.h3(color: textColor)),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.streakFire,
                      size: 20,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openIslamicCalendar(BuildContext context, DateTime date) {
    // Get current prayer period for background gradient
    final prayerState = context.read<PrayerBloc>().state;
    final prayerPeriod = prayerState is PrayerLoaded
        ? prayerState.prayerPeriod
        : PrayerPeriod.isha;
    final maghribTime = prayerState is PrayerLoaded
        ? prayerState.prayerTimes[Prayer.maghrib]?.startTime
        : null;

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder:
            (context, animation, secondaryAnimation) => IslamicCalendarScreen(
              initialDate: date,
              prayerPeriod: prayerPeriod,
              maghribTime: maghribTime,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecialDayBanner(DateTime date, Color textColor, DateTime? maghribTime) {
    final now = DateTime.now();
    final message = IslamicDayUtils.messageForDate(now, maghribTime: maghribTime);
    if (message == null ||
        message.type == IslamicEventType.jummah ||
        message.type == IslamicEventType.ayyamAlBeed) {
      return const SizedBox.shrink();
    }

    final accent = IslamicDayUtils.accentColor(message.type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.14),
              accent.withValues(alpha: 0.06),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message.subtitle,
                style: AppTextStyles.small(
                  color: textColor.withValues(alpha: 0.88),
                  weight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextEventCountdown(NextEventInfo info, Color textColor) {
    final accent = IslamicDayUtils.accentColor(info.event.type);
    final icon = IslamicDayUtils.iconForType(info.event.type);
    final unit = info.daysUntil == 1 ? 'day' : 'days';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.12),
              accent.withValues(alpha: 0.04),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${info.event.title} in ${info.daysUntil} $unit',
                style: AppTextStyles.small(
                  color: textColor.withValues(alpha: 0.92),
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${info.daysUntil}',
                style: AppTextStyles.small(
                  color: accent,
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildWeatherWidget(WeatherData data, Color textColor) {
    IconData icon;
    switch (data.condition) {
      case WeatherCondition.clear:
        icon = Icons.wb_sunny_rounded;
        break;
      case WeatherCondition.cloudy:
        icon = Icons.cloud_rounded;
        break;
      case WeatherCondition.rain:
        icon = Icons.water_drop_rounded;
        break;
      case WeatherCondition.drizzle:
        icon = Icons.grain_rounded;
        break;
      case WeatherCondition.thunderstorm:
        icon = Icons.thunderstorm_rounded;
        break;
      case WeatherCondition.snow:
        icon = Icons.ac_unit_rounded;
        break;
      case WeatherCondition.fog:
        icon = Icons.foggy;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: textColor.withValues(alpha: 0.9), size: 20),
        const SizedBox(width: 6),
        Text(
          '${data.temperature.round()}°',
          style: AppTextStyles.body(
            color: textColor.withValues(alpha: 0.9),
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}


class _CurrentPrayerSection extends StatelessWidget {
  final Prayer prayer;
  final PrayerLoaded state;
  final Color textColor;

  const _CurrentPrayerSection({
    required this.prayer,
    required this.state,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final entry = state.statuses[prayer];
    final isCompleted = entry?.status.isCompleted ?? false;
    final isJamaah = entry?.isJamaah ?? false;
    final timeData = state.prayerTimes[prayer];

    // Calculate time remaining for CURRENT prayer window
    final now = DateTime.now();
    Duration timeRemaining = Duration.zero;
    if (timeData != null) {
      timeRemaining = timeData.endTime.difference(now);
      if (timeRemaining.isNegative) timeRemaining = Duration.zero;
    }

    return GestureDetector(
      onTap:
          !isCompleted
              ? () {
                HapticFeedback.mediumImpact();
                context.read<PrayerBloc>().add(
                  MarkPrayerComplete(prayer: prayer, isOnTime: true),
                );
              }
              : null,
      onLongPress:
          !isCompleted
              ? () {
                HapticFeedback.heavyImpact();
                context.read<PrayerBloc>().add(
                  MarkPrayerComplete(
                    prayer: prayer,
                    isOnTime: true,
                    isJamaah: true,
                  ),
                );
              }
              : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: isCompleted ? 0.5 : 1.0,
        child: Column(
          children: [
            Text(
              "NOW",
              style: AppTextStyles.tiny(
                color: AppColors.activeGlow,
              ).copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Hero(
              tag: 'current_prayer_name',
              child: Text(
                prayer.displayNameForDay(state.date),
                style: AppTextStyles.h1(color: textColor).copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.w200,
                  height: 0.9,
                  letterSpacing: -1,
                  shadows: [
                    Shadow(
                      color: textColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            if (isCompleted)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.statusOnTime.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 14,
                              color: AppColors.statusOnTime,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "COMPLETED",
                              style: AppTextStyles.tiny(
                                color: AppColors.statusOnTime,
                              ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TasbihScreen(initialFlow: 'after_prayer'),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.spiritualGold.withValues(alpha: 0.15),
                            border: Border.all(
                              color: AppColors.spiritualGold.withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_stories_rounded,
                                size: 14,
                                color: AppColors.spiritualGold,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "READ AZKAR",
                                style: AppTextStyles.tiny(
                                  color: AppColors.spiritualGold,
                                ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Jamaah toggle pill
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<PrayerBloc>().add(
                        ToggleJamaah(prayer: prayer),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isJamaah
                            ? textColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: isJamaah
                              ? textColor.withValues(alpha: 0.4)
                              : textColor.withValues(alpha: 0.15),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 14,
                            color: isJamaah
                                ? textColor.withValues(alpha: 0.8)
                                : textColor.withValues(alpha: 0.35),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Jamaah",
                            style: AppTextStyles.tiny(
                              color: isJamaah
                                  ? textColor.withValues(alpha: 0.8)
                                  : textColor.withValues(alpha: 0.35),
                            ).copyWith(
                              fontWeight: isJamaah ? FontWeight.w600 : FontWeight.normal,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  // Countdown Timer
                  HeroCountdown(
                    duration: timeRemaining,
                    prayerName: "Time Remaining",
                    isPrayerActive: true,
                  ),
                  const SizedBox(height: 12),

                  // Tap / Long-press hint
                  Text(
                    "Tap to mark  •  Hold for jamaah",
                    style: AppTextStyles.tiny(
                      color: textColor.withValues(alpha: 0.4),
                    ),
                  ),

                  // Ends At Info
                  if (timeData != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Ends at ${_formatTime(timeData.endTime)}",
                      style: AppTextStyles.tiny(
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NextPrayerSection extends StatelessWidget {
  final Prayer prayer;
  final PrayerLoaded state;
  final Color textColor;
  final bool showLabel;

  const _NextPrayerSection({
    required this.prayer,
    required this.state,
    required this.textColor,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final timeData = state.prayerTimes[prayer];

    return Column(
      children: [
        if (showLabel) ...[
          Text(
            "UP NEXT",
            style: AppTextStyles.tiny(
              color: textColor.withValues(alpha: 0.5),
            ).copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          prayer.displayNameForDay(state.date),
          style: AppTextStyles.h2(color: textColor).copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 8),
        if (timeData != null)
          Text(
            _formatTime(timeData.startTime),
            style: AppTextStyles.body(
              color: textColor.withValues(alpha: 0.7),
            ).copyWith(
              fontFamily: 'JetBrains Mono',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _WaitingForNextSection extends StatelessWidget {
  final Prayer? nextPrayer;
  final PrayerLoaded state;
  final Color textColor;
  final int streak;

  const _WaitingForNextSection({
    required this.nextPrayer,
    required this.state,
    required this.textColor,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    Duration timeToNext = Duration.zero;

    if (nextPrayer != null) {
      final nextTime = state.prayerTimes[nextPrayer]!.startTime;
      timeToNext = nextTime.difference(now);
      if (timeToNext.isNegative) timeToNext = Duration.zero;
    }

    return Column(
      children: [
        if (nextPrayer != null) ...[
          Text(
            "WAITING FOR",
            style: AppTextStyles.tiny(
              color: textColor.withValues(alpha: 0.5),
            ).copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            nextPrayer!.displayNameForDay(state.date),
            style: AppTextStyles.h1(
              color: textColor,
            ).copyWith(fontSize: 48, fontWeight: FontWeight.w200),
          ),
          const SizedBox(height: 16),
          // Countdown to NEXT prayer start
          HeroCountdown(
            duration: timeToNext,
            prayerName: "Starts in",
            isPrayerActive: false,
          ),
          const SizedBox(height: 8),
          Text(
            "Starts at ${_formatTime(state.prayerTimes[nextPrayer]!.startTime)}",
            style: AppTextStyles.body(color: textColor.withValues(alpha: 0.6)),
          ),
        ] else ...[
          // All Done State
          Icon(
            Icons.nightlight_round,
            color: textColor.withValues(alpha: 0.5),
            size: 32,
          ),
          const SizedBox(height: 16),
          Text("See you at Fajr", style: AppTextStyles.h3(color: textColor)),
          if (streak > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.streakFire.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.streakFire,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$streak day streak!",
                    style: AppTextStyles.small(
                      color: AppColors.streakFire,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: PremiumFlowingLoader(color: AppColors.activeGlow),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final hour =
      time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
