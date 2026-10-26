import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wird2/widgets/common/premium_flowing_loader.dart';
import '../../../widgets/common/glass_snackbar.dart';
import '../../../widgets/common/glass_sheet.dart';
import '../../../core/repositories/sunnah_repository.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/device_profile.dart';
import '../../../core/services/app_icon_service.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/location_service.dart';
import '../../../models/settings.dart';
import '../../../models/prayer.dart';
import '../../home/bloc/prayer_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widgets/common/page_header.dart';
import '../../../widgets/common/pressable.dart';
import '../../../core/constants/durations.dart';
import '../../../core/services/haptic_service.dart';
import '../../../widgets/common/location_off_prompt.dart';
import '../../../core/quran/quran_translations.dart';
import '../../../core/quran/transliterator.dart';
import '../../../core/repositories/quran_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Settings, grouped by what the user is trying to change:
///
/// 1. Location (the hero card) — everything else depends on it.
/// 2. Prayer times — how times are calculated and which optional prayers show.
/// 3. Notifications — prayer alerts (per-prayer toggles fold away) and the
///    sunnah / occasion reminders.
/// 4. Quran — mirrors the reader's settings sheet.
/// 5. Look & feel — performance mode, background, weather, motion, haptics.
/// 6. Support.
///
/// Every row shares one shape: a tinted icon, a title, an optional value or
/// subtitle, and a chevron or switch.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

/// Public so the dashboard can hold a [GlobalKey] to it and jump straight to a
/// section — tapping the weather widget on the home screen calls
/// [revealWeatherSection].
class SettingsScreenState extends State<SettingsScreen> {
  /// Anchor for [revealWeatherSection].
  final GlobalKey _weatherSectionKey = GlobalKey();

  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();

  late AppSettings _settings;
  bool _isLoadingLocation = false;
  bool _canScheduleExactAlarms = true; // Assume true until checked
  bool _showPerPrayerAlerts = false;

  @override
  void initState() {
    super.initState();
    _settings = _storageService.getSettings();
    _checkExactAlarmPermission();
    // Location can be updated in the background (auto-detect on resume).
    // Without this, the copy held here would go stale and the next toggle
    // would save the old location back over the new one.
    _settingsListenable = _storageService.getSettingsListenable()..addListener(_onStoredSettingsChanged);
  }

  late final ValueListenable<Box<AppSettings>> _settingsListenable;

  void _onStoredSettingsChanged() {
    if (mounted) setState(() => _settings = _storageService.getSettings());
  }

  @override
  void dispose() {
    _settingsListenable.removeListener(_onStoredSettingsChanged);
    super.dispose();
  }

  /// Scrolls the Look & Feel section into view and flashes it, so the user can
  /// see which controls the tap brought them to.
  Future<void> revealWeatherSection() async {
    final target = _weatherSectionKey.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      // Sits the controls a little way down the viewport so the section
      // label above them stays visible too.
      alignment: 0.18,
    );
    if (!mounted) return;
    setState(() => _highlightWeatherSection = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _highlightWeatherSection = false);
  }

  bool _highlightWeatherSection = false;

  Future<void> _checkExactAlarmPermission() async {
    final canSchedule = await _notificationService.canScheduleExactAlarms();
    if (mounted) {
      setState(() => _canScheduleExactAlarms = canSchedule);
    }
  }

  Future<void> _saveSettings(AppSettings settings) async {
    HapticService().light();
    await _storageService.saveSettings(settings);
    setState(() {
      _settings = settings;
    });
    if (mounted) {
      context.read<PrayerBloc>().add(RefreshPrayerTimes());
    }
  }

  Future<void> _updateLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final result = await _locationService.getCurrentLocation();
      if (result.isSuccess && result.data != null) {
        final newSettings = _settings.copyWith(location: result.data);
        await _saveSettings(newSettings);
        HapticService().medium();
      } else if (result.serviceDisabled) {
        if (mounted) await showLocationOffPrompt(context);
      } else {
        if (mounted) _showError(result.error ?? 'Failed to update location');
      }
    } catch (e) {
      if (mounted) _showError('Error updating location: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showGlassSheet<bool>(
      context: context,
      title: 'Reset settings?',
      subtitle: 'Every preference goes back to its default. Your location, '
          'notification switches, prayer history and bookmarks are kept.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
        child: Builder(
          builder: (c) => Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: 'Cancel',
                  onTap: () => Navigator.pop(c, false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SheetButton(
                  label: 'Reset',
                  color: AppColors.statusMissed,
                  onTap: () => Navigator.pop(c, true),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    HapticService().medium();
    // Restore preferences, but keep what isn't a preference: where the
    // user is, that onboarding is done, and the notification switches
    // (turning those on needs a permission prompt and schedules alarms).
    // Reduce motion and Performance go back to the device-based default.
    final restored = AppSettings.defaults().copyWith(
      location: _settings.location,
      onboardingCompleted: _settings.onboardingCompleted,
      notificationsEnabled: _settings.notificationsEnabled,
      sunnahNotificationsEnabled: _settings.sunnahNotificationsEnabled,
      islamicEventsEnabled: _settings.islamicEventsEnabled,
    );
    await _saveSettings(restored);
    if (mounted) {
      GlassSnackBar.show(
        context,
        message: 'Settings restored to defaults',
        icon: Icons.restore_rounded,
        bottomMargin: GlassSnackBar.aboveNavBar,
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      GlassSnackBar.show(
        context,
        bottomMargin: GlassSnackBar.aboveNavBar,
        message: message,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.gutter(context);

    Widget section(String label, List<Widget> rows, {Key? key, bool highlight = false}) {
      return SliverToBoxAdapter(
        child: Padding(
          key: key,
          padding: EdgeInsets.fromLTRB(gutter, AppSpacing.section, gutter, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.md),
                child: Text(label, style: AppTextStyles.sectionLabel(color: AppColors.spiritualGold)),
              ),
              _GlassSection(highlight: highlight, children: rows),
            ],
          ),
        ),
      );
    }

    final translation = QuranTranslations.resolve(_settings.quranSelectedTranslation);
    final mode = PerformanceMode.fromKey(_settings.performanceMode);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.header(context).copyWith(bottom: 0),
                child: const PageHeader(overline: 'PREFERENCES', title: 'Settings'),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, AppSpacing.belowHeader, gutter, 0),
                child: _buildLocationCard(),
              ),
            ),

            // ── PRAYER TIMES ──
            section('PRAYER TIMES', [
              _SettingRow(
                icon: Icons.public_rounded,
                title: 'Calculation method',
                value: _settings.calculationMethod.displayName,
                onTap: () => _showSelectionDialog(
                  title: 'Calculation method',
                  options: CalculationMethodType.values.map((e) => e.displayName).toList(),
                  currentValue: _settings.calculationMethod.displayName,
                  onSelected: (index) => _saveSettings(
                    _settings.copyWith(calculationMethod: CalculationMethodType.values[index]),
                  ),
                ),
              ),
              _SettingRow(
                icon: Icons.wb_twilight_rounded,
                title: 'Asr method',
                value: _settings.madhab == MadhabType.shafi ? 'Standard' : 'Hanafi',
                onTap: () => _showSelectionDialog(
                  title: 'Asr method',
                  options: const ['Standard (Shafi, Maliki, Hanbali)', 'Hanafi'],
                  currentValue: _settings.madhab == MadhabType.shafi
                      ? 'Standard (Shafi, Maliki, Hanbali)'
                      : 'Hanafi',
                  onSelected: (index) => _saveSettings(
                    _settings.copyWith(madhab: index == 0 ? MadhabType.shafi : MadhabType.hanafi),
                  ),
                ),
              ),
              _SwitchRow(
                icon: Icons.nights_stay_rounded,
                title: 'Tahajjud',
                subtitle: 'Last third of the night',
                value: _settings.includeTahajjud,
                onChanged: (v) => _saveSettings(_settings.copyWith(includeTahajjud: v)),
              ),
              _SwitchRow(
                icon: Icons.wb_sunny_outlined,
                title: 'Ishraq',
                subtitle: '15 minutes after sunrise',
                value: _settings.includeIshraq,
                onChanged: (v) => _saveSettings(_settings.copyWith(includeIshraq: v)),
              ),
              _SwitchRow(
                icon: Icons.light_mode_rounded,
                title: 'Duha',
                subtitle: 'Forenoon prayer',
                value: _settings.includeDuha,
                onChanged: (v) => _saveSettings(_settings.copyWith(includeDuha: v)),
              ),
            ]),

            // ── NOTIFICATIONS ──
            section('NOTIFICATIONS', [
              _SwitchRow(
                icon: Icons.notifications_rounded,
                title: 'Prayer alerts',
                subtitle: 'A reminder as each prayer begins',
                value: _settings.notificationsEnabled,
                onChanged: (val) async {
                  if (val) {
                    final granted = await _notificationService.requestPermission();
                    if (granted) _saveSettings(_settings.copyWith(notificationsEnabled: true));
                  } else {
                    _saveSettings(_settings.copyWith(notificationsEnabled: false));
                  }
                },
              ),
              if (_settings.notificationsEnabled && !_canScheduleExactAlarms)
                _SettingRow(
                  icon: Icons.warning_amber_rounded,
                  tint: Colors.orange,
                  title: 'Allow exact alarms',
                  value: "Turn on 'Alarms & reminders' so alerts arrive on time",
                  onTap: () async {
                    await _notificationService.requestExactAlarmPermission();
                    _checkExactAlarmPermission();
                  },
                ),
              if (_settings.notificationsEnabled) ...[
                _SettingRow(
                  icon: Icons.tune_rounded,
                  title: 'Per-prayer alerts',
                  value: _perPrayerSummary(),
                  trailing: AnimatedRotation(
                    turns: _showPerPrayerAlerts ? 0.25 : 0,
                    duration: AppDurations.normal,
                    child: const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
                  ),
                  onTap: () => setState(() => _showPerPrayerAlerts = !_showPerPrayerAlerts),
                ),
                if (_showPerPrayerAlerts)
                  for (final prayer in fardhPrayers) _buildPrayerAlertRow(prayer),
              ],
              _SwitchRow(
                icon: Icons.auto_stories_rounded,
                title: 'Weekly sunnah',
                subtitle: 'Mondays at 9:00 AM',
                value: _settings.sunnahNotificationsEnabled,
                onChanged: (v) async {
                  await _saveSettings(_settings.copyWith(sunnahNotificationsEnabled: v));
                  if (v && mounted) {
                    try {
                      final sunnah = await context.read<SunnahRepository>().getWeeklySunnah();
                      await _notificationService.scheduleWeeklySunnahReminder(sunnah.title);
                    } catch (e) {
                      debugPrint('Error scheduling sunnah reminder: $e');
                    }
                  } else {
                    await _notificationService.cancelSunnahNotifications();
                  }
                },
              ),
              _SwitchRow(
                icon: Icons.celebration_rounded,
                title: 'Islamic occasions',
                subtitle: 'Ramadan, Eid and other special days',
                value: _settings.islamicEventsEnabled,
                onChanged: (v) async {
                  await _saveSettings(_settings.copyWith(islamicEventsEnabled: v));
                  if (v) {
                    await _notificationService.scheduleSpecialDayNotification();
                  } else {
                    await _notificationService.cancelEventNotifications();
                  }
                },
              ),
            ]),

            // ── QURAN ──
            // Mirrors the in-reader settings sheet; both write the same fields.
            section('QURAN', [
              _SettingRow(
                icon: Icons.font_download_rounded,
                title: 'Arabic script',
                value: _settings.quranSelectedScript.displayName,
                onTap: () => _showSelectionDialog(
                  title: 'Arabic script',
                  options: QuranScript.values.map((s) => s.displayName).toList(),
                  currentValue: _settings.quranSelectedScript.displayName,
                  onSelected: (index) => _saveSettings(
                    _settings.copyWith(quranSelectedScript: QuranScript.values[index]),
                  ),
                ),
              ),
              _SettingRow(
                icon: Icons.translate_rounded,
                title: 'Translation',
                value: '${translation.language} · ${translation.name}',
                onTap: () => _showSelectionDialog(
                  title: 'Translation',
                  options: [for (final t in QuranTranslations.all) '${t.language} · ${t.name}'],
                  currentValue: '${translation.language} · ${translation.name}',
                  onSelected: (index) {
                    final t = QuranTranslations.all[index];
                    _saveSettings(_settings.copyWith(quranSelectedTranslation: '${t.id}'));
                    // Save the whole translation for offline reading.
                    context.read<QuranRepository>().downloadTranslation(t.id).catchError((_) {});
                  },
                ),
              ),
              _SettingRow(
                icon: Icons.text_fields_rounded,
                title: 'Transliteration script',
                value: TransliterationScript.fromKey(_settings.quranTransliterationScript).label,
                onTap: () => _showSelectionDialog(
                  title: 'Transliteration script',
                  options: [for (final t in TransliterationScript.values) t.label],
                  currentValue: TransliterationScript.fromKey(_settings.quranTransliterationScript).label,
                  onSelected: (index) => _saveSettings(_settings.copyWith(
                    quranTransliterationScript: TransliterationScript.values[index].key,
                  )),
                ),
              ),
              _SwitchRow(
                icon: Icons.subject_rounded,
                title: 'Show translation',
                value: _settings.quranShowTranslation,
                onChanged: (v) => _saveSettings(_settings.copyWith(quranShowTranslation: v)),
              ),
              _SwitchRow(
                icon: Icons.record_voice_over_rounded,
                title: 'Show transliteration',
                value: _settings.quranShowTransliteration,
                onChanged: (v) => _saveSettings(_settings.copyWith(quranShowTransliteration: v)),
              ),
            ]),

            // ── LOOK & FEEL ──
            // Tapping the weather widget on the dashboard scrolls here; see
            // revealWeatherSection().
            section(
              'LOOK & FEEL',
              key: _weatherSectionKey,
              highlight: _highlightWeatherSection,
              [
                _PerformanceModePicker(
                  mode: mode,
                  autoNote: mode == PerformanceMode.auto ? DeviceProfile.instance.reason : null,
                  onChanged: (m) => _saveSettings(_settings.copyWith(performanceMode: m.key)),
                ),
                _AppIconPicker(
                  choice: AppIconChoice.fromKey(_settings.appIcon),
                  showing: _shownAppIcon(),
                  onChanged: (c) => _saveSettings(_settings.copyWith(appIcon: c.key)),
                ),
                _SwitchRow(
                  icon: Icons.schedule_rounded,
                  title: 'Follow prayer times',
                  subtitle: 'Icon shows the current prayer',
                  value: _settings.appIcon == AppIconChoice.auto.key,
                  // Turning it off keeps whichever icon is showing now.
                  onChanged: (v) => _saveSettings(_settings.copyWith(
                    appIcon: v ? AppIconChoice.auto.key : _shownAppIcon().key,
                  )),
                ),
                _SettingRow(
                  icon: Icons.wallpaper_rounded,
                  title: 'Background',
                  value: _getThemeDisplayName(_settings.weatherTheme),
                  onTap: () => _showSelectionDialog(
                    title: 'Background',
                    options: WeatherTheme.values.map(_getThemeDisplayName).toList(),
                    currentValue: _getThemeDisplayName(_settings.weatherTheme),
                    onSelected: (index) => _saveSettings(
                      _settings.copyWith(weatherTheme: WeatherTheme.values[index]),
                    ),
                  ),
                ),
                _SwitchRow(
                  icon: Icons.cloud_rounded,
                  title: 'Weather on dashboard',
                  value: _settings.showWeatherWidget,
                  onChanged: (v) => _saveSettings(_settings.copyWith(showWeatherWidget: v)),
                ),
                // Only steers the Auto level; a manual Performance choice wins.
                _SwitchRow(
                  icon: Icons.motion_photos_off_rounded,
                  title: 'Reduce motion',
                  subtitle: _reduceMotionSubtitle(mode),
                  value: lighterVisuals(),
                  // Flipping it makes the choice the user's own, so the
                  // device-based default stops applying.
                  onChanged: mode == PerformanceMode.auto
                      ? (v) => _saveSettings(
                            _settings.copyWith(reduceMotion: v, reduceMotionUserSet: true),
                          )
                      : null,
                ),
                _SwitchRow(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic feedback',
                  value: _settings.hapticsEnabled,
                  onChanged: (v) => _saveSettings(_settings.copyWith(hapticsEnabled: v)),
                ),
              ],
            ),

            // ── SUPPORT ──
            section('SUPPORT', [
              _SettingRow(
                icon: Icons.mail_outline_rounded,
                title: 'Report an issue',
                onTap: _launchReportEmail,
              ),
              _SettingRow(
                icon: Icons.restore_rounded,
                tint: AppColors.statusMissed,
                title: 'Reset settings',
                destructive: true,
                onTap: _resetSettings,
              ),
            ]),

            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.navClearance(context))),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods ---

  String _reduceMotionSubtitle(PerformanceMode mode) {
    const base = 'Lighter animations and effects for smoother performance';
    if (DeviceProfile.instance.animationsOff) {
      return '$base. Kept to fades because system animations are off';
    }
    if (mode != PerformanceMode.auto) return 'Set by Performance: ${mode.label}';
    if (_settings.reduceMotionUserSet) return base;
    final reason = DeviceProfile.instance.reason;
    return reason == null ? base : '$base. $reason';
  }

  PrayerNotificationSettings _alertSettingsFor(Prayer prayer) =>
      _settings.notificationSettings[prayer.name] ??
      PrayerNotificationSettings(startNotification: true, endWarning: true);

  String _perPrayerSummary() {
    final on = fardhPrayers.where((p) => _alertSettingsFor(p).startNotification).length;
    if (on == fardhPrayers.length) return 'All five prayers';
    if (on == 0) return 'None';
    return '$on of ${fardhPrayers.length} prayers';
  }

  Widget _buildPrayerAlertRow(Prayer prayer) {
    final pSettings = _alertSettingsFor(prayer);
    return _SwitchRow(
      title: prayer.displayName,
      indent: true,
      value: pSettings.startNotification,
      onChanged: (val) {
        final newMap = Map<String, PrayerNotificationSettings>.from(_settings.notificationSettings);
        newMap[prayer.name] = pSettings.copyWith(startNotification: val);
        _saveSettings(_settings.copyWith(notificationSettings: newMap));
      },
    );
  }

  Future<void> _launchReportEmail() async {
    final deviceInfo = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    final uri = Uri(
      scheme: 'mailto',
      path: 'sayan.kabir.official@gmail.com',
      queryParameters: {
        'subject': 'Wird Bug Report',
        'body': '\n\n--- Device Info ---\n$deviceInfo\n',
      },
    );
    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) _showError('Could not open email app');
    }
  }

  // --- Widget Components ---

  /// The city gets the whole width of the card. The pin sits in the caption
  /// and Update is a round icon button, so a long name like "Bhubaneswar" no
  /// longer has to squeeze between a large icon and a labelled pill.
  Widget _buildLocationCard() {
    return _GlassSection(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.spiritualGold, size: 14),
                        const SizedBox(width: 4),
                        Text('Prayer times for', style: AppTextStyles.tiny()),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _settings.location?.city ?? 'Detecting…',
                      style: AppTextStyles.h3(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: SizedBox(width: 20, height: 20, child: PremiumFlowingLoader(size: 20, color: Colors.white)),
                  ),
                )
              else
                Semantics(
                  button: true,
                  label: 'Update location',
                  child: Pressable(
                    onTap: _updateLocation,
                    pressedScale: 0.88,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSelectionDialog({
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(int) onSelected,
  }) {
    showGlassSheet<void>(
      context: context,
      title: title,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final isSelected = options[index] == currentValue;
          return Pressable(
            haptic: PressableHaptic.selection,
            pressedScale: 0.98,
            onTap: () {
              onSelected(index);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      options[index],
                      style: AppTextStyles.body(
                        color: isSelected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.8),
                        weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check_rounded, color: AppColors.spiritualGold, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The icon on the home screen right now (or about to be).
  AppIconChoice _shownAppIcon() {
    final choice = AppIconChoice.fromKey(_settings.appIcon);
    if (choice != AppIconChoice.auto) return choice;
    if (!_settings.isValid) return AppIconChoice.fallback;
    return AppIconService.iconFor(_settings, DateTime.now());
  }

  String _getThemeDisplayName(WeatherTheme theme) {
    switch (theme) {
      case WeatherTheme.auto: return 'Live weather';
      case WeatherTheme.clear: return 'Clear sky';
      case WeatherTheme.cloudy: return 'Cloudy';
      case WeatherTheme.rain: return 'Rain';
      case WeatherTheme.thunderstorm: return 'Thunderstorm';
      case WeatherTheme.snow: return 'Snow';
      case WeatherTheme.fog: return 'Fog';
    }
  }
}

// =============================================================================
// BUILDING BLOCKS
// =============================================================================

/// A rounded group of rows with hairline dividers between them. Frosted in
/// Balanced and Smooth, a flat fill in Lite.
class _GlassSection extends StatelessWidget {
  final List<Widget> children;
  final bool highlight;

  const _GlassSection({required this.children, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    final blur = !lighterVisuals();

    Widget body = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: blur ? 0.08 : 0.11),
        borderRadius: radius,
        border: Border.all(
          color: highlight
              ? AppColors.spiritualGold.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                margin: const EdgeInsets.only(left: 60),
                height: 1,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            children[i],
          ],
        ],
      ),
    );

    if (blur) {
      body = BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: body);
    }
    return ClipRRect(borderRadius: radius, child: body);
  }
}

/// The tinted square every row leads with.
class _RowIcon extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const _RowIcon({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 18, color: tint),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;
  final Color? tint;
  final bool destructive;
  final Widget? trailing;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.tint,
    this.destructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      // Full-width rows only need a hint of movement.
      pressedScale: 0.985,
      haptic: destructive ? PressableHaptic.medium : PressableHaptic.light,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          children: [
            _RowIcon(icon: icon, tint: tint ?? Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(
                      color: destructive ? AppColors.statusMissed : Colors.white,
                      weight: FontWeight.w500,
                    ),
                  ),
                  if (value != null)
                    // The value animates when it changes, so picking a new
                    // option visibly lands on the row you came from.
                    AnimatedSwitcher(
                      duration: AppDurations.normal,
                      child: Text(
                        value!,
                        key: ValueKey(value),
                        style: AppTextStyles.small(color: Colors.white54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                (destructive
                    ? const SizedBox.shrink()
                    : const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20)),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;

  /// Null shows the switch disabled.
  final ValueChanged<bool>? onChanged;

  /// Nested under a parent row (the per-prayer alerts): no icon, indented.
  final bool indent;

  const _SwitchRow({
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.indent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(indent ? 60 : 14, indent ? 6 : 10, 8, indent ? 6 : 10),
      child: Row(
        children: [
          if (icon != null) ...[
            _RowIcon(icon: icon!, tint: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: indent
                      ? AppTextStyles.small(color: Colors.white.withValues(alpha: 0.85))
                      : AppTextStyles.body(weight: FontWeight.w500),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.small(color: Colors.white54)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.spiritualGold,
            activeTrackColor: AppColors.spiritualGold.withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}

/// Lite / Balanced / Smooth as an inline segmented control, with a line
/// underneath saying what the chosen level does.
class _PerformanceModePicker extends StatelessWidget {
  final PerformanceMode mode;
  final ValueChanged<PerformanceMode> onChanged;

  /// On Auto, why lighter visuals are currently on (e.g. Battery Saver).
  final String? autoNote;

  const _PerformanceModePicker({required this.mode, required this.onChanged, this.autoNote});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RowIcon(icon: Icons.speed_rounded, tint: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 14),
              Text('Performance', style: AppTextStyles.body(weight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                for (final m in PerformanceMode.values)
                  Expanded(
                    child: Pressable(
                      haptic: PressableHaptic.selection,
                      pressedScale: 0.95,
                      onTap: () {
                        if (m != mode) onChanged(m);
                      },
                      child: AnimatedContainer(
                        duration: AppDurations.normal,
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: m == mode ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          m.label,
                          maxLines: 1,
                          style: AppTextStyles.small(
                            color: m == mode ? Colors.white : Colors.white.withValues(alpha: 0.55),
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            child: Text(
              autoNote == null ? mode.description : '${mode.description} $autoNote.',
              key: ValueKey('$mode$autoNote'),
              style: AppTextStyles.small(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

/// The five home screen icons, one per prayer. Tapping one fixes the icon;
/// the "Follow prayer times" switch below hands it back to the clock.
class _AppIconPicker extends StatelessWidget {
  final AppIconChoice choice;

  /// The icon on the home screen now; ringed in gold.
  final AppIconChoice showing;
  final ValueChanged<AppIconChoice> onChanged;

  const _AppIconPicker({required this.choice, required this.showing, required this.onChanged});

  String get _note {
    final auto = choice == AppIconChoice.auto;
    if (Platform.isIOS) {
      return auto
          ? 'Changes to the current prayer when you open Wird. iOS confirms each change.'
          : 'iOS confirms the change with a short message.';
    }
    return auto
        ? 'Changes with each prayer through the day.'
        : 'The new icon appears once you leave Wird.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RowIcon(icon: Icons.apps_rounded, tint: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 14),
              Text('App icon', style: AppTextStyles.body(weight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final c in AppIconChoice.prayers) ...[
                if (c != AppIconChoice.prayers.first) const SizedBox(width: 10),
                Expanded(child: _tile(c)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            child: Text(
              _note,
              key: ValueKey(choice == AppIconChoice.auto),
              style: AppTextStyles.small(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(AppIconChoice c) {
    final selected = c == showing;
    return Pressable(
      haptic: PressableHaptic.selection,
      pressedScale: 0.92,
      onTap: () {
        if (c != choice) onChanged(c);
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: AppDurations.normal,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.spiritualGold : Colors.transparent,
                width: 2,
              ),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                // Roughly the curve of a real home screen icon.
                borderRadius: BorderRadius.circular(11),
                child: Image.asset('assets/icon/thumbs/${c.key}.png', fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            c.label,
            maxLines: 1,
            style: AppTextStyles.small(
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
              weight: FontWeight.w600,
            ).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetButton({required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.withValues(alpha: color == null ? 0.06 : 0.16),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: c.withValues(alpha: color == null ? 0.1 : 0.45)),
        ),
        child: Text(label, style: AppTextStyles.button(color: c)),
      ),
    );
  }
}
