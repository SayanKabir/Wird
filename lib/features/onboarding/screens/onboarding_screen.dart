import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/durations.dart';
import '../../../core/constants/effects.dart';
import '../../../core/constants/radii.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/athan_cue_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/weather_sound_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/prayer.dart';
import '../../../models/settings.dart';
import '../../../widgets/common/athan_cue_caption.dart';
import '../../../widgets/common/glass_panel.dart';
import '../../../widgets/common/location_off_prompt.dart';
import '../../../widgets/common/prayer_glyph.dart';
import '../../../widgets/common/pressable.dart';
import '../../../widgets/common/wird_icons.dart';
import '../../home/screens/home_screen.dart';
import '../../home/widgets/celestial_background.dart';
import '../widgets/onboarding_widgets.dart';

/// First run. The user walks through one day of the app's living sky, from
/// the stars of Tahajjud to Maghrib's sunset, and each hour asks for one
/// preference while showing off the feature it shapes: real prayer times and
/// the Qibla as soon as the location is in, Asr moving as the madhab changes,
/// both mushaf scripts side by side. Each step is entered with the next
/// phrase of the iqamah, so the walk through recites the whole call.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// The sky behind each step, in order through the day.
const _skies = [
  PrayerPeriod.tahajjud,
  PrayerPeriod.fajr,
  PrayerPeriod.sunrise,
  PrayerPeriod.dhuhr,
  PrayerPeriod.asr,
  PrayerPeriod.maghrib,
  PrayerPeriod.isha,
];

/// The iqamah phrase sounded on arriving at each step, in order; the
/// closing takbir and tahlil ([AthanCue.closing]) play on finishing. Going
/// back sounds nothing, so the phrases are only ever heard in their order.
const _entryCues = [
  null,
  AthanCue.takbir,
  AthanCue.shahada,
  AthanCue.risalah,
  AthanCue.salah,
  AthanCue.falah,
  AthanCue.iqamah,
];

const _fard = [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha];

const _bismillahUthmani = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
const _bismillahIndoPak = 'بِسۡمِ اللهِ الرَّحۡمٰنِ الرَّحِيۡمِ';

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _cityController = TextEditingController();
  final AthanCueService _cues = AthanCueService.instance;

  int _page = 0;
  bool _locating = false;
  bool _searching = false;
  bool _requestingNotifications = false;
  bool _finishing = false;

  /// The last beat of finishing: the phrase lifts away just before home
  /// arrives.
  bool _leaving = false;

  /// The sky for the actual time of day, which the home screen opens with,
  /// so the hand-off happens under one sky. Set when finishing.
  PrayerPeriod _homeSky = PrayerPeriod.isha;
  String? _locationError;
  LocationData? _location;

  CalculationMethodType _method = CalculationMethodType.muslimWorldLeague;
  CalculationMethodType? _suggestedMethod;
  MadhabType _madhab = MadhabType.shafi;

  bool _tahajjud = true;
  bool _ishraq = false;
  bool _duha = false;
  bool _sunnahReminders = true;
  bool _islamicEvents = true;

  QuranScript _script = QuranScript.indopak;
  bool _translation = true;
  bool _transliteration = false;

  bool? _notificationsGranted;

  // The last step's touches. Unlike the rest, these are saved the moment
  // they change, so each switch can be felt or heard straight away.
  bool _sounds = true;
  bool _weatherSounds = true;
  bool _haptics = true;
  bool _weatherWidget = true;
  String _appIcon = AppIconChoice.auto.key;
  int _endWarning = AppDurations.defaultEndWarningMinutes;

  int get _lastPage => _skies.length - 1;

  /// The sun and moon pass behind the headings, so they're softened while a
  /// page has text over them.
  final ValueNotifier<double> _celestialOpacity = ValueNotifier(1);

  @override
  void initState() {
    super.initState();
    // Coming back here (Settings can reset onboarding) starts from what's set.
    final s = _storageService.getSettings();
    _location = s.location;
    _method = s.calculationMethod;
    _madhab = s.madhab;
    _tahajjud = s.includeTahajjud;
    _ishraq = s.includeIshraq;
    _duha = s.includeDuha;
    _sunnahReminders = s.sunnahNotificationsEnabled;
    _islamicEvents = s.islamicEventsEnabled;
    _script = s.quranSelectedScript;
    _translation = s.quranShowTranslation;
    _transliteration = s.quranShowTransliteration;
    _endWarning = s.endTimeWarningMinutes;
    _sounds = s.soundsEnabled;
    _weatherSounds = s.weatherSoundsEnabled;
    _haptics = s.hapticsEnabled;
    _weatherWidget = s.showWeatherWidget;
    _appIcon = s.appIcon;
    _suggestedMethod = _methodForCountry(_location?.country);
    _cues.warmUp();
    _cues.captionedLocally.value = true;
    WidgetsBinding.instance.addObserver(this);
    _checkNotifications();
  }

  /// Picks up notifications allowed from the phone's settings while Wird
  /// was in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _notificationsGranted != true) _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    if (!mounted || !enabled || _notificationsGranted == true) return;
    setState(() => _notificationsGranted = true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _cues.captionedLocally.value = false;
    _cityController.dispose();
    _celestialOpacity.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  /// Reminders are the heart of Wird, so the last step waits for them.
  bool get _canContinue => switch (_page) {
        1 => _location != null,
        5 => _notificationsGranted == true,
        // Notifications can't be revoked from the step after, but a trip to
        // Settings mid-way could; check again before finishing.
        6 => _notificationsGranted == true,
        _ => true,
      };

  void _goTo(int page) {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      page,
      duration: motionStill() ? Duration.zero : const Duration(milliseconds: 520),
      curve: AppCurves.move,
    );
  }

  void _next() {
    HapticService().light();
    if (_page < _lastPage) {
      final cue = _entryCues[_page + 1];
      if (cue != null) _cues.play(cue);
      _goTo(_page + 1);
    }
  }

  void _back() {
    HapticService().light();
    if (_page > 0) _goTo(_page - 1);
  }

  // ---------------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------------

  Future<void> _detectLocation() async {
    HapticService().medium();
    setState(() {
      _locating = true;
      _locationError = null;
    });
    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (result.isSuccess) {
      _setLocation(result.data!);
    } else {
      setState(() => _locationError = result.error);
    }
    if (result.serviceDisabled) await showLocationOffPrompt(context);
  }

  Future<void> _searchCity() async {
    final query = _cityController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    HapticService().light();
    setState(() {
      _searching = true;
      _locationError = null;
    });
    final result = await _locationService.geocodeCity(query, null);
    if (!mounted) return;
    setState(() => _searching = false);
    if (result.isSuccess) {
      _setLocation(result.data!);
    } else {
      setState(() => _locationError = result.error);
    }
  }

  void _setLocation(LocationData location) {
    SoundService().ready();
    HapticService().medium();
    final suggested = _methodForCountry(location.country);
    setState(() {
      _location = location;
      _locationError = null;
      _suggestedMethod = suggested;
      if (suggested != null) _method = suggested;
      if (_hanafiCountries.contains(location.country?.toLowerCase())) _madhab = MadhabType.hanafi;
    });
  }

  static const _hanafiCountries = {'pakistan', 'india', 'bangladesh', 'afghanistan', 'turkey', 'türkiye'};

  /// The convention most mosques in [country] follow, when it's clear.
  static CalculationMethodType? _methodForCountry(String? country) {
    switch (country?.toLowerCase()) {
      case 'united states':
      case 'united states of america':
      case 'canada':
        return CalculationMethodType.isna;
      case 'saudi arabia':
      case 'yemen':
        return CalculationMethodType.ummAlQura;
      case 'egypt':
      case 'sudan':
      case 'libya':
      case 'syria':
      case 'lebanon':
        return CalculationMethodType.egyptian;
      case 'pakistan':
      case 'india':
      case 'bangladesh':
      case 'afghanistan':
        return CalculationMethodType.karachi;
      case 'iran':
        return CalculationMethodType.tehran;
      case 'united arab emirates':
        return CalculationMethodType.dubai;
      case 'kuwait':
        return CalculationMethodType.kuwait;
      case 'qatar':
        return CalculationMethodType.qatar;
      case 'singapore':
      case 'malaysia':
      case 'indonesia':
      case 'brunei':
        return CalculationMethodType.singapore;
      case 'united kingdom':
      case 'germany':
      case 'france':
      case 'netherlands':
      case 'belgium':
        return CalculationMethodType.muslimWorldLeague;
    }
    return null;
  }

  /// Today's times for the chosen location and conventions.
  Map<Prayer, PrayerTimeData>? _times({CalculationMethodType? method, MadhabType? madhab}) {
    final location = _location;
    if (location == null) return null;
    return PrayerService().calculatePrayerTimes(
      date: DateTime.now(),
      location: location,
      calculationMethod: method ?? _method,
      madhab: madhab ?? _madhab,
      includeTahajjud: true,
      includeIshraq: true,
      includeDuha: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  Future<void> _requestNotifications() async {
    HapticService().medium();
    // Once refused, the system won't ask again; only Settings can turn them
    // on, and coming back is caught by didChangeAppLifecycleState.
    if (_notificationsGranted == false) {
      await _locationService.openAppSettings();
      return;
    }
    setState(() => _requestingNotifications = true);
    final granted = await _notificationService.requestPermission();
    if (!mounted) return;
    setState(() {
      _requestingNotifications = false;
      _notificationsGranted = granted;
    });
    if (!granted) return;

    // Android 12+ needs a separate grant to ring exactly on time.
    final canScheduleExact = await _notificationService.canScheduleExactAlarms();
    if (!canScheduleExact && mounted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => const _ExactAlarmDialog(),
      );
      if (open == true) await _notificationService.requestExactAlarmPermission();
    }
  }

  // ---------------------------------------------------------------------------
  // Finish
  // ---------------------------------------------------------------------------

  Future<void> _finish() async {
    final location = _location;
    if (location == null) {
      _goTo(1);
      return;
    }
    HapticService().heavy();
    FocusScope.of(context).unfocus();
    // The walk-through's sun or moon gives way to the live sky's.
    _celestialOpacity.value = 0;
    setState(() {
      _homeSky = _homeSkyNow();
      _finishing = true;
    });
    final cue = _cues.play(AthanCue.closing);

    final settings = _storageService.getSettings().copyWith(
      onboardingCompleted: true,
      location: location,
      calculationMethod: _method,
      madhab: _madhab,
      includeTahajjud: _tahajjud,
      includeIshraq: _ishraq,
      includeDuha: _duha,
      notificationsEnabled: true,
      endTimeWarningMinutes: _endWarning,
      sunnahNotificationsEnabled: _sunnahReminders,
      islamicEventsEnabled: _islamicEvents,
      quranSelectedScript: _script,
      quranShowTranslation: _translation,
      quranShowTransliteration: _transliteration,
    );
    final still = motionStill();
    await Future.wait([
      cue,
      _storageService.saveSettings(settings),
      // The takbir, then the tahlil, each shown in turn; home fades in as
      // the tahlil closes.
      Future.delayed(Duration(milliseconds: still ? 600 : 7400)),
    ]);
    if (!mounted) return;
    // The phrase lifts away as home fades in over it, so no empty beat of
    // sky falls between them.
    // The caption stays onboarding's (and hidden) until it has gone; dispose
    // hands it back.
    Navigator.of(context).pushReplacement(_HomeArrival());
    if (!still) await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() => _leaving = true);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final period = _finishing ? _homeSky : _skies[_page];
    return PopScope(
      canPop: _page == 0 && !_finishing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_finishing) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: CelestialBackground(
                prayerPeriod: period,
                reduceMotion: motionStill(),
                lite: lighterVisuals(),
                latitude: _location?.latitude ?? 0,
                transitionDuration: const Duration(milliseconds: 2200),
                // The welcome's wordmark sits where the Tahajjud moon would; the
                // stars carry that page, and the sun rises on the next.
                showCelestialBody: _page != 0 || _finishing,
                celestialOpacity: _celestialOpacity,
                child: const SizedBox.expand(),
              ),
            ),
            // On finishing, the sky home is about to draw (the real sun and
            // moon over this place) fades in over the day onboarding walked
            // through, so home opens under the very same sky.
            if (_finishing && _location != null)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: motionStill() ? 0 : 1200),
                  curve: Curves.easeInOut,
                  builder: (context, t, child) => Opacity(opacity: t, child: child),
                  child: CelestialBackground(
                    prayerPeriod: _homeSky,
                    reduceMotion: motionStill(),
                    lite: lighterVisuals(),
                    latitude: _location!.latitude,
                    longitude: _location!.longitude,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            // Dawn and noon skies are bright where the cards sit; a soft
            // shade keeps the glass and its text legible on every page. Home
            // has none, so it lifts as onboarding finishes.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _finishing ? 0 : 1,
                  duration: const Duration(milliseconds: 1200),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x33000000), Color(0x66000000)],
                        stops: [0.15, 0.5, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // The page's own content dissolves first, leaving only the sky.
            AnimatedOpacity(
              opacity: _finishing ? 0 : 1,
              duration: const Duration(milliseconds: 500),
              curve: AppCurves.emphasized,
              child: AnimatedSlide(
                offset: _finishing ? const Offset(0, 0.02) : Offset.zero,
                duration: const Duration(milliseconds: 600),
                curve: AppCurves.emphasized,
                child: IgnorePointer(
                  ignoring: _finishing,
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (page) {
                              _celestialOpacity.value = page == 0 ? 1 : 0.5;
                              setState(() => _page = page);
                            },
                            children: [
                              _WelcomePage(onBegin: _next),
                              _page1(),
                              _page2(),
                              _page3(),
                              _page4(),
                              _page5(),
                              _page6(),
                            ],
                          ),
                        ),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Floats over the page under the header, so a phrase coming and
            // going never moves the content. The finish shows its own.
            if (!_finishing)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 60,
                left: AppSpacing.gutter(context),
                right: AppSpacing.gutter(context),
                child: const IgnorePointer(child: Center(child: AthanCueCaption())),
              ),
            if (_finishing)
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _leaving ? 0 : 1,
                  duration: const Duration(milliseconds: 600),
                  curve: AppCurves.exit,
                  child: AnimatedSlide(
                    offset: _leaving ? const Offset(0, -0.04) : Offset.zero,
                    duration: const Duration(milliseconds: 600),
                    curve: AppCurves.exit,
                    child: _FinishVeil(now: _homeSky),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final gutter = AppSpacing.gutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter - 10, 8, gutter - 10, 0),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                AnimatedOpacity(
                  duration: AppDurations.normal,
                  opacity: _page > 0 && !_finishing ? 1 : 0,
                  child: Pressable(
                    onTap: _page > 0 && !_finishing ? _back : null,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
                const Spacer(),
                DayProgress(step: _finishing ? _skies.length : _page, steps: _skies.length + 1),
                const Spacer(),
                const CueMuteButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final gutter = AppSpacing.gutter(context);
    // The welcome page carries its own call to action.
    if (_page == 0) return const SizedBox(height: 8);
    final isLast = _page == _lastPage;
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 16),
      child: SizedBox(
        width: double.infinity,
        child: OnboardingButton(
          label: switch (_page) {
            1 when _location == null => 'Set your location first',
            5 || 6 when _notificationsGranted != true => 'Allow reminders to continue',
            6 => 'Begin with Wird',
            _ => 'Continue',
          },
          icon: isLast ? null : Icons.arrow_forward_rounded,
          gold: isLast,
          loading: _finishing,
          onPressed: !_canContinue ? null : (isLast ? _finish : _next),
        ),
      ),
    );
  }

  /// Fades and lifts a page's pieces in turn, when entrance motion is on.
  Widget _enter(Widget child, int order) {
    if (!AppEffects.entranceMotion) return child;
    final delay = 120.ms + AppDurations.stagger * order * 2;
    return child
        .animate()
        .fadeIn(delay: delay, duration: 420.ms, curve: AppCurves.emphasized)
        .slideY(begin: 0.06, delay: delay, duration: 420.ms, curve: AppCurves.emphasized);
  }

  Widget _scroll(List<Widget> children) {
    final gutter = AppSpacing.gutter(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < children.length; i++) _enter(children[i], i)],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1 · Fajr — location, answered with today's times and the Qibla
  // ---------------------------------------------------------------------------

  Widget _page1() {
    final location = _location;
    return _scroll([
      const OnboardingHeading(
        eyebrow: 'Fajr · dawn',
        title: 'Where do you pray?',
        body: 'Your times follow the sun where you stand, to the minute, and the Qibla is worked out from the same spot.',
      ),
      const SizedBox(height: AppSpacing.xl),
      GhostButton(
        label: location == null ? 'Use my location' : 'Detect again',
        icon: Icons.my_location_rounded,
        loading: _locating,
        onPressed: _locating || _searching ? null : _detectLocation,
      ),
      const SizedBox(height: AppSpacing.md),
      _CitySearchField(
        controller: _cityController,
        searching: _searching,
        onSubmit: _searchCity,
      ),
      if (_locationError != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(_locationError!, style: AppTextStyles.small(color: const Color(0xFFFFB4AB))),
      ],
      const SizedBox(height: AppSpacing.xl),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: AppCurves.emphasized,
        switchOutCurve: AppCurves.exit,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(animation), child: child),
        ),
        child: location == null
            ? const _LocationPlaceholder(key: ValueKey('none'))
            : _LocationResultCard(
                key: ValueKey('${location.latitude},${location.longitude}'),
                location: location,
                times: _times()!,
              ),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 2 · Sunrise — calculation method and madhab, with times that move
  // ---------------------------------------------------------------------------

  Widget _page2() {
    final times = _times();
    final methods = CalculationMethodType.values.where((m) => m != CalculationMethodType.other).toList();
    if (_suggestedMethod != null) {
      methods
        ..remove(_suggestedMethod)
        ..insert(0, _suggestedMethod!);
    }
    return _scroll([
      const OnboardingHeading(
        eyebrow: 'Sunrise · the day opens',
        title: 'Whose clock do you keep?',
        body: 'Scholars measure dawn and nightfall a little differently. Choose what your mosque follows and watch your times move.',
      ),
      const SizedBox(height: AppSpacing.xl),
      if (times != null) _LiveTimesStrip(times: times),
      const SizedBox(height: AppSpacing.xl),
      Text('CALCULATION', style: AppTextStyles.sectionLabel()),
      const SizedBox(height: AppSpacing.md),
      LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final m in methods)
              SizedBox(
                width: width,
                child: ChoiceTile(
                  selected: _method == m,
                  onTap: () => setState(() => _method = m),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(m.shortName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(weight: FontWeight.w600)),
                          ),
                          if (m == _suggestedMethod) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.spiritualGold),
                          ],
                        ],
                      ),
                      Text(
                        m == _suggestedMethod ? 'Suggested for you' : m.regions,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.tiny(
                          color: m == _suggestedMethod
                              ? AppColors.spiritualGold.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
      const SizedBox(height: AppSpacing.xl),
      Text('ASR', style: AppTextStyles.sectionLabel()),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: _MadhabTile(
              title: 'Standard',
              subtitle: "Shafi'i, Maliki, Hanbali",
              asr: _times(madhab: MadhabType.shafi)?[Prayer.asr]?.startTime,
              selected: _madhab == MadhabType.shafi,
              onTap: () => setState(() => _madhab = MadhabType.shafi),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MadhabTile(
              title: 'Hanafi',
              subtitle: 'Shadow twice its length',
              asr: _times(madhab: MadhabType.hanafi)?[Prayer.asr]?.startTime,
              selected: _madhab == MadhabType.hanafi,
              onTap: () => setState(() => _madhab = MadhabType.hanafi),
            ),
          ),
        ],
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 3 · Dhuhr — voluntary prayers and the Sunnah
  // ---------------------------------------------------------------------------

  Widget _page3() {
    final times = _times();
    String window(Prayer p, {bool startOnly = false}) {
      final t = times?[p];
      if (t == null) return '';
      final start = AppFormatters.formatTime(t.startTime);
      return startOnly ? 'from $start' : '$start – ${AppFormatters.formatTime(t.endTime)}';
    }

    Widget disc(Prayer p) => _SkyDisc(prayer: p, size: 40);

    return _scroll([
      const OnboardingHeading(
        eyebrow: 'Dhuhr · high noon',
        title: 'Beyond the five',
        body: 'Add the voluntary prayers to your day, and let Wird bring back one forgotten Sunnah at a time.',
      ),
      const SizedBox(height: AppSpacing.xl),
      ToggleTile(
        leading: disc(Prayer.tahajjud),
        title: 'Tahajjud',
        subtitle: 'Last third of the night ${window(Prayer.tahajjud, startOnly: true)}',
        value: _tahajjud,
        onChanged: (v) => setState(() => _tahajjud = v),
      ),
      const SizedBox(height: AppSpacing.sm),
      ToggleTile(
        leading: disc(Prayer.ishraq),
        title: 'Ishraq',
        subtitle: 'Once the sun has risen · ${window(Prayer.ishraq)}',
        value: _ishraq,
        onChanged: (v) => setState(() => _ishraq = v),
      ),
      const SizedBox(height: AppSpacing.sm),
      ToggleTile(
        leading: disc(Prayer.duha),
        title: 'Duha',
        subtitle: 'The forenoon prayer · ${window(Prayer.duha)}',
        value: _duha,
        onChanged: (v) => setState(() => _duha = v),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text('THE SUNNAH', style: AppTextStyles.sectionLabel()),
      const SizedBox(height: AppSpacing.md),
      ToggleTile(
        leading: const _GlyphBadge(WirdGlyph.sunnah),
        title: 'Sunnah revival',
        subtitle: 'A gentle nudge towards a practice of the Prophet ﷺ',
        value: _sunnahReminders,
        onChanged: (v) => setState(() => _sunnahReminders = v),
      ),
      const SizedBox(height: AppSpacing.sm),
      ToggleTile(
        leading: const _GlyphBadge(null, icon: Icons.nightlight_round),
        title: 'Islamic days',
        subtitle: 'Ramadan, the Eids and the white days, on the Hijri calendar',
        value: _islamicEvents,
        onChanged: (v) => setState(() => _islamicEvents = v),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 4 · Asr — the mushaf
  // ---------------------------------------------------------------------------

  Widget _page4() {
    return _scroll([
      const OnboardingHeading(
        eyebrow: 'Asr · the afternoon',
        title: 'Read in the hand you know',
        body: 'The whole Quran in two mushaf scripts, with translation, transliteration and verses you can share.',
      ),
      const SizedBox(height: AppSpacing.xl),
      Row(
        children: [
          Expanded(child: _scriptTile(QuranScript.indopak, _bismillahIndoPak, 'Indo-Pak', 'South Asian')),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _scriptTile(QuranScript.uthmani, _bismillahUthmani, 'Uthmani', 'Madinah')),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _VersePreview(script: _script, translation: _translation, transliteration: _transliteration),
      const SizedBox(height: AppSpacing.lg),
      ToggleTile(
        title: 'Translation',
        subtitle: 'Saheeh International, under each verse',
        value: _translation,
        onChanged: (v) => setState(() => _translation = v),
      ),
      const SizedBox(height: AppSpacing.sm),
      ToggleTile(
        title: 'Transliteration',
        subtitle: 'The Arabic spelled out, to read along',
        value: _transliteration,
        onChanged: (v) => setState(() => _transliteration = v),
      ),
    ]);
  }

  Widget _scriptTile(QuranScript script, String sample, String name, String note) {
    return ChoiceTile(
      selected: _script == script,
      onTap: () => setState(() => _script = script),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Center(
              child: FittedBox(
                child: Text(
                  sample,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.arabic(size: 22, color: Colors.white, script: script),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: AppTextStyles.body(weight: FontWeight.w600)),
          Text(note, style: AppTextStyles.tiny()),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5 · Maghrib — reminders, then the call to success
  // ---------------------------------------------------------------------------

  Widget _page5() {
    final granted = _notificationsGranted == true;
    final times = _times();
    final upcoming = times == null ? null : _nextFard(times);
    return _scroll([
      const OnboardingHeading(
        eyebrow: 'Maghrib · sunset',
        title: 'Never miss the call',
        body: 'Wird is built around the call to prayer: a notification as each prayer begins, and a quiet nudge before its time runs out. Allow them to begin.',
      ),
      const SizedBox(height: AppSpacing.xl),
      _NotificationMock(prayer: upcoming?.$1, time: upcoming?.$2),
      const SizedBox(height: AppSpacing.lg),
      AnimatedSwitcher(
        duration: AppDurations.slow,
        child: granted
            ? GlassPanel(
                key: const ValueKey('granted'),
                radius: AppRadii.pill,
                color: AppColors.statusOnTime.withValues(alpha: 0.2),
                edgeColor: AppColors.statusOnTime.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Reminders are on', style: AppTextStyles.button()),
                  ],
                ),
              )
            : GhostButton(
                key: const ValueKey('ask'),
                label: _notificationsGranted == false ? 'Open settings' : 'Allow reminders',
                icon: _notificationsGranted == false ? Icons.settings_rounded : Icons.notifications_active_rounded,
                loading: _requestingNotifications,
                onPressed: _requestNotifications,
              ),
      ),
      if (_notificationsGranted == false) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Notifications are off for Wird. Turn them on in Settings, then come back here.',
          textAlign: TextAlign.center,
          style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
      const SizedBox(height: AppSpacing.xl),
      Text('WARN ME BEFORE A PRAYER ENDS', style: AppTextStyles.sectionLabel()),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          for (final m in AppDurations.endWarningOptions) ...[
            Expanded(
              child: ChoiceTile(
                selected: _endWarning == m,
                onTap: () => setState(() => _endWarning = m),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text('$m', style: AppTextStyles.tabular(AppTextStyles.bodyLarge(weight: FontWeight.w600))),
                    Text('min', style: AppTextStyles.tiny()),
                  ],
                ),
              ),
            ),
            if (m != AppDurations.endWarningOptions.last) const SizedBox(width: 6),
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      if (_location != null) _Summary(
        city: _location!.city ?? _location!.displayName,
        method: _method.shortName,
        madhab: _madhab == MadhabType.hanafi ? 'Hanafi' : 'Standard',
        script: _script.displayName,
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 6 · Isha — the little touches
  // ---------------------------------------------------------------------------

  Future<void> _saveTouch(AppSettings Function(AppSettings) change) =>
      _storageService.saveSettings(change(_storageService.getSettings()));

  Widget _page6() {
    final shown = _iconFor(_homeSkyNow());
    return _scroll([
      const OnboardingHeading(
        eyebrow: 'Isha · nightfall',
        title: 'The little touches',
        body: 'How Wird sounds and feels in your hand. Each one plays as you switch it on, and all of them live in Settings.',
      ),
      const SizedBox(height: AppSpacing.xl),
      ToggleTile(
        leading: const _GlyphBadge(null, icon: Icons.graphic_eq_rounded),
        title: 'Sound effects',
        subtitle: 'Soft clicks as you tap, a chime when you\'ve prayed',
        value: _sounds,
        onChanged: (v) async {
          setState(() => _sounds = v);
          await _saveTouch((s) => s.copyWith(soundsEnabled: v));
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      ToggleTile(
        leading: const _GlyphBadge(null, icon: Icons.thunderstorm_rounded),
        title: 'Rain and thunder',
        subtitle: 'Heard under the home sky when it rains where you are',
        value: _weatherSounds,
        onChanged: (v) async {
          setState(() => _weatherSounds = v);
          await _saveTouch((s) => s.copyWith(weatherSoundsEnabled: v));
          if (v) WeatherSoundService().preview();
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      ToggleTile(
        leading: const _GlyphBadge(null, icon: Icons.vibration_rounded),
        title: 'Haptics',
        subtitle: 'A light touch under every tap',
        value: _haptics,
        onChanged: (v) async {
          setState(() => _haptics = v);
          await _saveTouch((s) => s.copyWith(hapticsEnabled: v));
          if (v) HapticService().medium();
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      ToggleTile(
        leading: const _GlyphBadge(null, icon: Icons.cloud_rounded),
        title: 'Weather on home',
        subtitle: 'Today\'s temperature beside the date',
        value: _weatherWidget,
        onChanged: (v) async {
          setState(() => _weatherWidget = v);
          await _saveTouch((s) => s.copyWith(showWeatherWidget: v));
        },
      ),
      const SizedBox(height: AppSpacing.xl),
      Text('HOME SCREEN ICON', style: AppTextStyles.sectionLabel()),
      const SizedBox(height: AppSpacing.md),
      ChoiceTile(
        selected: _appIcon == AppIconChoice.auto.key,
        onTap: () => _setIcon(AppIconChoice.auto.key),
        child: Row(
          children: [
            _IconThumb(name: shown, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Follow the prayers', style: AppTextStyles.body(weight: FontWeight.w600)),
                  Text(
                    'Your icon changes with each prayer\'s sky',
                    style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          for (final p in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) ...[
            Expanded(
              child: ChoiceTile(
                selected: _appIcon == p,
                onTap: () => _setIcon(p),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    _IconThumb(name: p, size: 34),
                    const SizedBox(height: 6),
                    Text(
                      '${p[0].toUpperCase()}${p.substring(1)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ),
            if (p != 'isha') const SizedBox(width: 6),
          ],
        ],
      ),
    ]);
  }

  void _setIcon(String key) {
    setState(() => _appIcon = key);
    _saveTouch((s) => s.copyWith(appIcon: key));
  }

  /// The sky for right now, from the chosen location and conventions.
  PrayerPeriod _homeSkyNow() {
    final location = _location;
    if (location == null) return PrayerPeriod.isha;
    final times = PrayerService().calculatePrayerTimes(
      date: DateTime.now(),
      location: location,
      calculationMethod: _method,
      madhab: _madhab,
      includeTahajjud: _tahajjud,
      includeIshraq: _ishraq,
      includeDuha: _duha,
    );
    return PrayerService().getCurrentPrayerPeriod(times, DateTime.now());
  }

  /// The icon a period's sky is drawn on.
  static String _iconFor(PrayerPeriod p) => switch (p) {
        PrayerPeriod.fajr => 'fajr',
        PrayerPeriod.sunrise || PrayerPeriod.dhuhr => 'dhuhr',
        PrayerPeriod.asr => 'asr',
        PrayerPeriod.maghrib => 'maghrib',
        PrayerPeriod.isha || PrayerPeriod.tahajjud => 'isha',
      };

  (Prayer, DateTime)? _nextFard(Map<Prayer, PrayerTimeData> times) {
    final now = DateTime.now();
    for (final p in _fard) {
      final t = times[p]?.startTime;
      if (t != null && t.isAfter(now)) return (p, t);
    }
    final fajr = times[Prayer.fajr]?.startTime;
    return fajr == null ? null : (Prayer.fajr, fajr.add(const Duration(days: 1)));
  }
}

// =============================================================================
// Welcome
// =============================================================================

/// The night sky, the name, and a glimpse of what's inside. The one call to
/// action sounds "come to prayer" as the day begins.
class _WelcomePage extends StatelessWidget {
  final VoidCallback onBegin;

  const _WelcomePage({required this.onBegin});

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);
    final animate = AppEffects.entranceMotion;
    Widget enter(Widget child, int order, {double rise = 0.08}) => animate
        ? child
            .animate()
            .fadeIn(delay: 200.ms + 140.ms * order, duration: 700.ms, curve: AppCurves.emphasized)
            .slideY(begin: rise, delay: 200.ms + 140.ms * order, duration: 700.ms, curve: AppCurves.emphasized)
        : child;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.1),
                    enter(const _Wordmark(), 0, rise: 0.15),
                    const SizedBox(height: AppSpacing.xl),
                    enter(
                      Text(
                        'Your daily portion of prayer,\nQuran and remembrance.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      2,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Column(
                  children: [
                    enter(const _DayStrip(), 3),
                    const SizedBox(height: AppSpacing.md),
                    enter(
                      Text(
                        'The sky here follows your prayers.',
                        style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      3,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    enter(const _FeatureChips(), 4),
                    const SizedBox(height: AppSpacing.xl),
                    enter(
                      SizedBox(
                        width: double.infinity,
                        child: OnboardingButton(label: 'Bismillah', onPressed: onBegin, icon: Icons.arrow_forward_rounded),
                      ),
                      5,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    enter(
                      Text(
                        'Sets up in about a minute',
                        style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      5,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ورد and Wird side by side, Arabic on the left, parted by a hairline of
/// gold. The Arabic goes without harakat: at this size Amiri lifts the sukun
/// far above the letters.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final glow = [Shadow(color: AppColors.spiritualGold.withValues(alpha: 0.35), blurRadius: 28)];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amiri's letters sit low in their line; lifted to centre on Wird.
          Transform.translate(
            offset: const Offset(0, -7),
            child: Text(
              'ورد',
              textDirection: TextDirection.rtl,
              style: AppTextStyles.arabic(size: 68, color: Colors.white).copyWith(height: 1.3, shadows: glow),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 1.2,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.spiritualGold.withValues(alpha: 0),
                  AppColors.spiritualGold.withValues(alpha: 0.8),
                  AppColors.spiritualGold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            'Wird',
            style: AppTextStyles.display(size: 54, weight: FontWeight.w200, letterSpacing: 1, height: 1.1, shadows: glow),
          ),
        ],
      ),
    );
  }
}

/// The five prayers as their home-screen skies, in a row.
class _DayStrip extends StatelessWidget {
  const _DayStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final p in _fard)
          Column(
            children: [
              _SkyDisc(prayer: p, size: 46),
              const SizedBox(height: 6),
              Text(p.displayName, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.75))),
            ],
          ),
      ],
    );
  }
}

class _FeatureChips extends StatelessWidget {
  const _FeatureChips();

  static const _features = <(WirdGlyph?, IconData?, String)>[
    (WirdGlyph.quran, null, 'Quran, offline'),
    (WirdGlyph.qibla, null, 'Qibla'),
    (WirdGlyph.tasbih, null, 'Tasbih & azkar'),
    (WirdGlyph.sunnah, null, 'Sunnah revival'),
    (null, Icons.calendar_month_rounded, 'Hijri calendar'),
    (WirdGlyph.stats, null, 'Streaks'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (glyph, icon, label) in _features)
          GlassPanel(
            radius: AppRadii.pill,
            fill: 0.08,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                glyph != null
                    ? WirdGlyphIcon(glyph, size: 15, color: AppColors.spiritualGold)
                    : Icon(icon, size: 15, color: AppColors.spiritualGold),
                const SizedBox(width: 7),
                Text(label, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Shared pieces
// =============================================================================

/// A prayer's glyph on a disc of its own sky, as on the home screen icon.
class _SkyDisc extends StatelessWidget {
  final Prayer prayer;
  final double size;

  const _SkyDisc({required this.prayer, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: prayerSky(prayer),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: PrayerGlyph.colored(prayer: prayer, size: size * 0.62),
    );
  }
}

/// A home screen icon, as the launcher would round it.
class _IconThumb extends StatelessWidget {
  final String name;
  final double size;

  const _IconThumb({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: Image.asset('assets/icon/thumbs/$name.png', width: size, height: size, fit: BoxFit.cover),
    );
  }
}

class _GlyphBadge extends StatelessWidget {
  final WirdGlyph? glyph;
  final IconData? icon;

  const _GlyphBadge(this.glyph, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.spiritualGold.withValues(alpha: 0.14),
        border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: glyph != null
          ? WirdGlyphIcon(glyph!, size: 20, color: AppColors.spiritualGold)
          : Icon(icon, size: 20, color: AppColors.spiritualGold),
    );
  }
}

class _CitySearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final VoidCallback onSubmit;

  const _CitySearchField({required this.controller, required this.searching, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: AppRadii.pill,
      fill: 0.08,
      padding: const EdgeInsets.only(left: 18, right: 6),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              style: AppTextStyles.body(),
              cursorColor: AppColors.spiritualGold,
              decoration: InputDecoration(
                hintText: 'Or search a city',
                hintStyle: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.5)),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: searching
                ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : Pressable(
                    onTap: onSubmit,
                    child: Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white.withValues(alpha: 0.8)),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocationPlaceholder extends StatelessWidget {
  const _LocationPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: AppRadii.group,
      fill: 0.05,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Opacity(
            opacity: 0.55,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final p in _fard) _SkyDisc(prayer: p, size: 30)],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Today's times will appear here",
            style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

/// Once the location is in: the city, today's five times and the Qibla.
class _LocationResultCard extends StatelessWidget {
  final LocationData location;
  final Map<Prayer, PrayerTimeData> times;

  const _LocationResultCard({super.key, required this.location, required this.times});

  static const _compass = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];

  @override
  Widget build(BuildContext context) {
    final qibla = PrayerService().getQiblaDirection(location);
    final point = _compass[((qibla % 360) / 22.5).round() % 16];
    final now = DateTime.now();
    Prayer? next;
    for (final p in _fard) {
      if (times[p]!.startTime.isAfter(now)) {
        next = p;
        break;
      }
    }

    return GlassPanel(
      radius: AppRadii.group,
      fill: 0.1,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place_rounded, size: 18, color: AppColors.spiritualGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(location.displayName,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final p in _fard)
                Column(
                  children: [
                    _SkyDisc(prayer: p, size: 34),
                    const SizedBox(height: 6),
                    Text(
                      p.displayName,
                      style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: p == next ? 1 : 0.7)),
                    ),
                    Text(
                      _shortTime(times[p]!.startTime),
                      style: AppTextStyles.tabular(AppTextStyles.small(
                        color: Colors.white.withValues(alpha: p == next ? 1 : 0.85),
                        weight: p == next ? FontWeight.w700 : FontWeight.w500,
                      )),
                    ),
                    const SizedBox(height: 4),
                    // Marks the prayer that comes next.
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p == next ? AppColors.spiritualGold : Colors.transparent,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 14),
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: qibla),
                duration: motionStill() ? Duration.zero : const Duration(milliseconds: 1400),
                curve: AppCurves.settle,
                builder: (context, angle, child) =>
                    Transform.rotate(angle: angle * math.pi / 180, child: child),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  alignment: Alignment.topCenter,
                  child: Icon(Icons.navigation_rounded, size: 16, color: AppColors.kaabaGold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Qibla  ', style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.7))),
                    TextSpan(
                      text: '${qibla.round()}° $point',
                      style: AppTextStyles.tabular(AppTextStyles.small(weight: FontWeight.w600, color: Colors.white)),
                    ),
                    TextSpan(text: '  from north', style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.7))),
                  ]),
                ),
              ),
              WirdGlyphIcon(WirdGlyph.qibla, size: 18, color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Short times ("5:12") for tight rows; the period is clear from the prayer.
String _shortTime(DateTime t) => AppFormatters.formatTime(t).replaceAll(RegExp(r'\s?[AP]M$'), '');

/// Fajr, Asr and Isha: the times the conventions disagree on, so the user
/// sees what each choice does.
class _LiveTimesStrip extends StatelessWidget {
  final Map<Prayer, PrayerTimeData> times;

  const _LiveTimesStrip({required this.times});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: AppRadii.group,
      fill: 0.1,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          for (final p in const [Prayer.fajr, Prayer.asr, Prayer.isha])
            Expanded(
              child: Column(
                children: [
                  PrayerGlyph(prayer: p, size: 22, color: Colors.white.withValues(alpha: 0.85)),
                  const SizedBox(height: 6),
                  Text(p.displayName, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: AppCurves.emphasized,
                    switchOutCurve: AppCurves.exit,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      AppFormatters.formatTime(times[p]!.startTime),
                      key: ValueKey(times[p]!.startTime),
                      style: AppTextStyles.tabular(AppTextStyles.bodyLarge(weight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MadhabTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime? asr;
  final bool selected;
  final VoidCallback onTap;

  const _MadhabTile({
    required this.title,
    required this.subtitle,
    required this.asr,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceTile(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.body(weight: FontWeight.w600)),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.tiny()),
          if (asr != null) ...[
            const SizedBox(height: 8),
            Text(
              'Asr ${AppFormatters.formatTime(asr!)}',
              style: AppTextStyles.tabular(AppTextStyles.small(
                weight: FontWeight.w600,
                color: selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.8),
              )),
            ),
          ],
        ],
      ),
    );
  }
}

/// Al-Fatiha's opening verse, drawn as the reader will draw it.
class _VersePreview extends StatelessWidget {
  final QuranScript script;
  final bool translation;
  final bool transliteration;

  const _VersePreview({required this.script, required this.translation, required this.transliteration});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: AppRadii.group,
      fill: 0.1,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: AnimatedSize(
        duration: AppDurations.slow,
        curve: AppCurves.emphasized,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.5)),
                  ),
                  child: Text('1:1', style: AppTextStyles.tabular(AppTextStyles.tiny(color: AppColors.spiritualGold))),
                ),
                const SizedBox(width: 8),
                Text('Al-Fatihah', style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: AppDurations.slow,
              child: Text(
                script == QuranScript.indopak ? _bismillahIndoPak : _bismillahUthmani,
                key: ValueKey(script),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.arabic(size: 28, color: Colors.white, script: script).copyWith(height: 1.8),
              ),
            ),
            if (transliteration) ...[
              const SizedBox(height: 6),
              Text(
                'Bismillāhir-raḥmānir-raḥīm',
                style: AppTextStyles.small(color: AppColors.spiritualGold.withValues(alpha: 0.9))
                    .copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            if (translation) ...[
              const SizedBox(height: 6),
              Text(
                'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
                style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What a reminder will look like, for the next prayer at this location.
class _NotificationMock extends StatelessWidget {
  final Prayer? prayer;
  final DateTime? time;

  const _NotificationMock({required this.prayer, required this.time});

  @override
  Widget build(BuildContext context) {
    final p = prayer ?? Prayer.maghrib;
    final when = time == null ? 'now' : AppFormatters.formatTime(time!);
    return GlassPanel(
      radius: AppRadii.group,
      fill: 0.16,
      edge: 0.2,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset('assets/icon/thumbs/${_thumbFor(p)}.png', width: 38, height: 38, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('WIRD', style: AppTextStyles.sectionLabel(color: Colors.white.withValues(alpha: 0.6)).copyWith(fontSize: 10)),
                    const Spacer(),
                    Text(when, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
                const SizedBox(height: 2),
                Text("It's time for ${p.displayName}", style: AppTextStyles.body(weight: FontWeight.w600)),
                Text(
                  'حَيَّ عَلَى الصَّلَاةِ · Come to prayer',
                  style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _thumbFor(Prayer p) => switch (p) {
        Prayer.fajr => 'fajr',
        Prayer.dhuhr => 'dhuhr',
        Prayer.asr => 'asr',
        Prayer.maghrib => 'maghrib',
        _ => 'isha',
      };
}

class _Summary extends StatelessWidget {
  final String city;
  final String method;
  final String madhab;
  final String script;

  const _Summary({required this.city, required this.method, required this.madhab, required this.script});

  @override
  Widget build(BuildContext context) {
    Widget item(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(label.toUpperCase(), style: AppTextStyles.sectionLabel().copyWith(fontSize: 10)),
              const SizedBox(height: 4),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small(color: Colors.white)),
            ],
          ),
        );
    return GlassPanel(
      radius: AppRadii.group,
      fill: 0.06,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [item('City', city), item('Method', method), item('Asr', madhab), item('Mushaf', script)],
      ),
    );
  }
}

/// The iqamah's closing takbir and tahlil, blooming in over the sky the
/// home screen is about to open with, then naming the hour they're
/// arriving in.
class _FinishVeil extends StatelessWidget {
  final PrayerPeriod now;

  const _FinishVeil({required this.now});

  static String _name(PrayerPeriod p) => switch (p) {
        PrayerPeriod.tahajjud => 'Tahajjud',
        PrayerPeriod.fajr => 'Fajr',
        PrayerPeriod.sunrise => 'Sunrise',
        PrayerPeriod.dhuhr => 'Dhuhr',
        PrayerPeriod.asr => 'Asr',
        PrayerPeriod.maghrib => 'Maghrib',
        PrayerPeriod.isha => 'Isha',
      };

  /// Follows the closing clip from the takbir to the tahlil, crossfading
  /// as each begins and holding the last once the caption clears.
  static Widget _phrase(Widget Function(CuePhrase) build) => ValueListenableBuilder<CuePhrase?>(
        valueListenable: AthanCueService.instance.playing,
        builder: (context, phrase, _) {
          final p = phrase ?? AthanCue.closing.later.last.$2;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: AppCurves.emphasized,
            switchOutCurve: AppCurves.exit,
            child: KeyedSubtree(key: ValueKey(p), child: build(p)),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final animate = !motionStill();
    Widget bloom(Widget child, Duration delay) => animate
        ? child
            .animate()
            .fadeIn(delay: delay, duration: 900.ms, curve: AppCurves.emphasized)
            .scaleXY(begin: 0.94, delay: delay, duration: 1200.ms, curve: AppCurves.emphasized)
        : child;
    final rule = Container(width: 72, height: 1, color: AppColors.spiritualGold.withValues(alpha: 0.7));

    return Container(
      color: AppColors.background.withValues(alpha: 0.25),
      // Below centre, clear of the sun or moon for most of the day.
      alignment: const Alignment(0, 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bloom(
            _phrase((p) => Text(
                  p.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.arabic(size: 44, color: Colors.white).copyWith(
                    height: 1.4,
                    shadows: [Shadow(color: AppColors.spiritualGold.withValues(alpha: 0.45), blurRadius: 28)],
                  ),
                )),
            200.ms,
          ),
          const SizedBox(height: 14),
          // A rule of gold drawn outwards from the centre.
          animate
              ? rule.animate().scaleX(begin: 0, delay: 600.ms, duration: 900.ms, curve: AppCurves.emphasized)
              : rule,
          const SizedBox(height: 14),
          bloom(
            _phrase((p) => Text(p.meaning, style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.85)))),
            700.ms,
          ),
          const SizedBox(height: 28),
          bloom(
            Text(
              'NOW · ${_name(now).toUpperCase()}',
              style: AppTextStyles.sectionLabel(color: AppColors.spiritualGold.withValues(alpha: 0.9)),
            ),
            1300.ms,
          ),
        ],
      ),
    );
  }
}

/// Home arriving over the sky onboarding finished on: it fades in while
/// settling from slightly larger, as if the view were coming to rest.
///
/// Home's first frame is heavy (it starts every bloc and the sky at once)
/// and stalls the screen for about 0.6s even in a release build, so the
/// fade starts late enough for that stall to pass behind the phrase.
class _HomeArrival extends PageRouteBuilder<void> {
  _HomeArrival()
      : super(
          settings: const RouteSettings(name: '/home'),
          transitionDuration: Duration(milliseconds: motionStill() ? 200 : 1600),
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (motionStill()) return FadeTransition(opacity: animation, child: child);
            final fade = CurvedAnimation(parent: animation, curve: const Interval(0.4, 0.85, curve: Curves.easeOut));
            final settle = CurvedAnimation(parent: animation, curve: const Interval(0.4, 1, curve: AppCurves.emphasized));
            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(scale: Tween(begin: 1.05, end: 1.0).animate(settle), child: child),
            );
          },
        );
}

/// Asks to open the "Alarms & reminders" setting on Android 12+.
class _ExactAlarmDialog extends StatelessWidget {
  const _ExactAlarmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: GlassPanel(
        radius: AppRadii.panel,
        color: AppColors.background.withValues(alpha: 0.9),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_on_rounded, color: AppColors.spiritualGold, size: 40),
            const SizedBox(height: 14),
            Text('On the minute', style: AppTextStyles.h3()),
            const SizedBox(height: 10),
            Text(
              "To ring exactly as a prayer begins, Wird needs 'Alarms & reminders' turned on in your phone's settings.",
              textAlign: TextAlign.center,
              style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 22),
            OnboardingButton(label: 'Open settings', onPressed: () => Navigator.pop(context, true)),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Not now', style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.6))),
            ),
          ],
        ),
      ),
    );
  }
}
