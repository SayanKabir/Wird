import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wird2/widgets/common/premium_flowing_loader.dart';
import '../../../widgets/common/glass_snackbar.dart';
import '../../../core/repositories/sunnah_repository.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/location_service.dart';
import '../../../models/settings.dart';
import '../../../models/prayer.dart';
import '../../home/bloc/prayer_bloc.dart';
import '../../../core/services/debug_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/utils/moon_phase_utils.dart';
import 'package:url_launcher/url_launcher.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();
  final DebugService _debugService = DebugService();

  late AppSettings _settings;
  bool _isLoadingLocation = false;
  bool _canScheduleExactAlarms = true; // Assume true until checked

  @override
  void initState() {
    super.initState();
    _settings = _storageService.getSettings();
    _checkExactAlarmPermission();
  }

  Future<void> _checkExactAlarmPermission() async {
    final canSchedule = await _notificationService.canScheduleExactAlarms();
    if (mounted) {
      setState(() => _canScheduleExactAlarms = canSchedule);
    }
  }

  Future<void> _saveSettings(AppSettings settings) async {
    HapticFeedback.lightImpact();
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
        HapticFeedback.mediumImpact();
      } else {
        if (mounted) _showError(result.error ?? 'Failed to update location');
      }
    } catch (e) {
      if (mounted) _showError('Error updating location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _resetSettings() async {
    // Custom "Celestial" Glass Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // Darker backdrop for focus
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restore_rounded, size: 48, color: Colors.white70),
                  const SizedBox(height: 16),
                  Text('Reset Settings?', style: AppTextStyles.h2()),
                  const SizedBox(height: 12),
                  Text(
                    'This will restore all preferences to their default values. This action cannot be undone.',
                    style: AppTextStyles.body(color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Cancel', style: AppTextStyles.body(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(c, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusMissed.withOpacity(0.2),
                            foregroundColor: AppColors.statusMissed,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: AppColors.statusMissed.withOpacity(0.5))
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      // Logic to reset to defaults
    }
  }

  void _showError(String message) {
    if (mounted) {
      GlassSnackBar.show(
        context,
        message: message,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PREFERENCES",
                      style: AppTextStyles.tiny(color: Colors.white.withOpacity(0.5))
                          .copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Settings",
                      style: AppTextStyles.h1(),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Location Hero Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildLocationCard(),
              ),
            ),

            // ── PRAYER SETTINGS ──
            _buildSectionHeader("PRAYER SETTINGS"),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildGlassSection([
                  _buildSettingTile(
                    title: "Calculation Method",
                    value: _settings.calculationMethod.displayName,
                    icon: Icons.public,
                    onTap: () => _showSelectionDialog(
                      title: 'Calculation Method',
                      options: CalculationMethodType.values.map((e) => e.displayName).toList(),
                      currentValue: _settings.calculationMethod.displayName,
                      onSelected: (index) {
                        _saveSettings(_settings.copyWith(
                            calculationMethod: CalculationMethodType.values[index]
                        ));
                      },
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    title: "Asr Method",
                    value: _settings.madhab == MadhabType.shafi ? 'Standard' : 'Hanafi',
                    icon: Icons.access_time,
                    onTap: () => _showSelectionDialog(
                      title: 'Asr Method',
                      options: ['Standard (Shafi, Maliki, Hanbali)', 'Hanafi'],
                      currentValue: _settings.madhab == MadhabType.shafi ? 'Standard (Shafi, Maliki, Hanbali)' : 'Hanafi',
                      onSelected: (index) {
                        _saveSettings(_settings.copyWith(
                            madhab: index == 0 ? MadhabType.shafi : MadhabType.hanafi
                        ));
                      },
                    ),
                  ),
                  _buildDivider(),
                  _buildSwitchRow(
                    title: "Tahajjud",
                    subtitle: "Last third of the night",
                    value: _settings.includeTahajjud,
                    onChanged: (v) => _saveSettings(_settings.copyWith(includeTahajjud: v)),
                  ),
                  _buildDivider(),
                  _buildSwitchRow(
                    title: "Ishraq",
                    subtitle: "15 min after sunrise",
                    value: _settings.includeIshraq,
                    onChanged: (v) => _saveSettings(_settings.copyWith(includeIshraq: v)),
                  ),
                  _buildDivider(),
                  _buildSwitchRow(
                    title: "Duha",
                    subtitle: "Forenoon prayer",
                    value: _settings.includeDuha,
                    onChanged: (v) => _saveSettings(_settings.copyWith(includeDuha: v)),
                  ),
                ]),
              ),
            ),

            // ── NOTIFICATIONS ──
            _buildSectionHeader("NOTIFICATIONS"),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildGlassSection([
                  _buildSwitchRow(
                    title: "Prayer Notifications",
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
                  // Exact alarm permission warning (Android 12+)
                  if (_settings.notificationsEnabled && !_canScheduleExactAlarms) ...[
                    _buildDivider(),
                    GestureDetector(
                      onTap: () async {
                        await _notificationService.requestExactAlarmPermission();
                        _checkExactAlarmPermission();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Exact Alarms Required",
                                    style: AppTextStyles.body(color: Colors.white)
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tap to enable 'Alarms & reminders' in settings for accurate prayer notifications.",
                                    style: AppTextStyles.small(color: Colors.white.withOpacity(0.7)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_settings.notificationsEnabled) ...[
                    _buildDivider(),
                    ...fardhPrayers.map((prayer) {
                      final pSettings = _settings.notificationSettings[prayer.name] ??
                          PrayerNotificationSettings(startNotification: true, endWarning: true);

                      return Column(
                        children: [
                          _buildSwitchRow(
                            title: prayer.displayName,
                            value: pSettings.startNotification,
                            compact: true,
                            onChanged: (val) {
                              final newMap = Map<String, PrayerNotificationSettings>.from(_settings.notificationSettings);
                              newMap[prayer.name] = pSettings.copyWith(startNotification: val);
                              _saveSettings(_settings.copyWith(notificationSettings: newMap));
                            },
                          ),
                          if (prayer != fardhPrayers.last) _buildDivider(),
                        ],
                      );
                    }),
                  ],
                  _buildDivider(),
                  _buildSwitchRow(
                    title: "Weekly Sunnah Reminder",
                    subtitle: "Every Monday at 9:00 AM",
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
                  _buildDivider(),
                  _buildSwitchRow(
                    title: "Islamic Events",
                    subtitle: "Notify on special Islamic days",
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
              ),
            ),

            // ── APPEARANCE ──
            _buildSectionHeader("APPEARANCE"),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildGlassSection([
                  _buildSwitchRow(
                    title: "Show Weather",
                    subtitle: "Display weather widget on dashboard",
                    value: _settings.showWeatherWidget,
                    onChanged: (val) {
                      _saveSettings(_settings.copyWith(showWeatherWidget: val));
                    },
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    title: "Background Theme",
                    value: _getThemeDisplayName(_settings.weatherTheme),
                    icon: Icons.wallpaper_rounded,
                    onTap: () => _showSelectionDialog(
                      title: 'Background Theme',
                      options: WeatherTheme.values.map(_getThemeDisplayName).toList(),
                      currentValue: _getThemeDisplayName(_settings.weatherTheme),
                      onSelected: (index) {
                        _saveSettings(_settings.copyWith(
                            weatherTheme: WeatherTheme.values[index]
                        ));
                      },
                    ),
                  ),
                ]),
              ),
            ),

            // ── SUPPORT ──
            _buildSectionHeader("SUPPORT"),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildGlassSection([
                  _buildActionTile(
                    title: "Report an Issue",
                    icon: Icons.mail_outline_rounded,
                    onTap: _launchReportEmail,
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    title: "Reset Settings",
                    icon: Icons.restore_rounded,
                    isDestructive: true,
                    onTap: _resetSettings,
                  ),
                ]),
              ),
            ),


            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
  // --- Helper Methods ---

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

  Widget _buildLocationCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08), // Increased opacity for visibility
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1), // Glassy icon bg
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.spiritualGold, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Location",
                      style: AppTextStyles.tiny(color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _settings.location?.city ?? "Detecting...",
                      style: AppTextStyles.h3(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isLoadingLocation)
                const SizedBox(
                    width: 20, height: 20,
                    child: PremiumFlowingLoader(size: 20, color: Colors.white)
                )
              else
                IconButton(
                  onPressed: _updateLocation,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  tooltip: "Update Location",
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 24, 12),
        child: Text(
          title,
          style: AppTextStyles.tiny(color: AppColors.spiritualGold)
              .copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildGlassSection(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Higher blur
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08), // Slightly more visible glass
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTextStyles.small(color: Colors.white54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: compact ? 12 : 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge()),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.small(color: Colors.white54)),
                ]
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.spiritualGold,
            activeTrackColor: AppColors.spiritualGold.withOpacity(0.3),
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.statusMissed : Colors.white70;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyLarge(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  void _showSelectionDialog({
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(int) onSelected,
  }) {
    // Custom Celestial Modal Bottom Sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Crucial for glass effect
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.6), // Darken background
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(title, style: AppTextStyles.h2()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Options List
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final isSelected = options[index] == currentValue;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onSelected(index);
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      options[index],
                                      style: isSelected
                                          ? AppTextStyles.bodyLarge(color: AppColors.spiritualGold, weight: FontWeight.bold)
                                          : AppTextStyles.bodyLarge(color: Colors.white70),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: AppColors.spiritualGold, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
  String _getThemeDisplayName(WeatherTheme theme) {
    switch (theme) {
      case WeatherTheme.auto: return 'Dynamic (Live)';
      case WeatherTheme.clear: return 'Clear Sky';
      case WeatherTheme.cloudy: return 'Cloudy';
      case WeatherTheme.rain: return 'Rainy';
      case WeatherTheme.thunderstorm: return 'Thunderstorm';
      case WeatherTheme.snow: return 'Snow';
      case WeatherTheme.fog: return 'Foggy';
    }
  }
}