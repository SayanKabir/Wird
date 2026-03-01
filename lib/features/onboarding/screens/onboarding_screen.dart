import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/settings.dart';
import '../../../widgets/common/premium_flowing_loader.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  int _currentPage = 0;
  bool _isLoading = false;
  String? _error;
  LocationData? _location;
  CalculationMethodType _calculationMethod = CalculationMethodType.muslimWorldLeague;
  MadhabType _madhab = MadhabType.shafi;

  bool? _notificationPermissionGranted;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    }
  }

  Future<void> _getLocation() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _locationService.getCurrentLocation();

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _location = result.data;
        _error = null;
      } else {
        _error = result.error;
      }
    });
  }

  Future<void> _requestNotificationPermission() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    // Request basic notification permission
    final granted = await _notificationService.requestPermission();
    debugPrint('[Onboarding] Notification permission granted: $granted');

    setState(() {
      _isLoading = false;
      _notificationPermissionGranted = granted;
    });

    if (granted) {
      // Also request exact alarm permission (Android 12+)
      final canScheduleExact = await _notificationService.canScheduleExactAlarms();
      debugPrint('[Onboarding] Can schedule exact alarms: $canScheduleExact');
      if (!canScheduleExact) {
        // Show dialog explaining why exact alarms are needed
        if (mounted) {
          final shouldOpen = await showDialog<bool>(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.alarm_on_rounded, color: Colors.orange, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          "Precise Reminders",
                          style: AppTextStyles.h3(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "To notify you exactly when prayer time begins, please enable 'Alarms & reminders' for Wird in your device settings.",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text("Skip", style: TextStyle(color: Colors.white54)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text("Open Settings"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          if (shouldOpen == true) {
            await _notificationService.requestExactAlarmPermission();
          }
        }
      }

      await _notificationService.showTestNotification();
    }
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.heavyImpact();
    if (_location == null) {
      setState(() => _error = 'Please set your location first');
      return;
    }

    setState(() => _isLoading = true);

    final settings = AppSettings(
      onboardingCompleted: true,
      location: _location,
      calculationMethod: _calculationMethod,
      madhab: _madhab,
      notificationsEnabled: true,
    );

    await _storageService.saveSettings(settings);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Deep Celestial Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Color(0xFF1E1B4B), // Deep Indigo
                    Color(0xFF0F172A), // Slate 900
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // 2. Ambient Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.spiritualGold.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.buttonPrimary.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                _buildProgressHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildWelcomePage(),
                      _buildLocationPage(),
                      _buildCalculationPage(),
                      _buildNotificationPage(),
                    ],
                  ),
                ),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Components ---

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isActive = index <= _currentPage;
          final isCurrent = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            width: isCurrent ? 32 : 12,
            decoration: BoxDecoration(
              color: isActive ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isActive ? [
                BoxShadow(
                  color: AppColors.spiritualGold.withValues(alpha: 0.5),
                  blurRadius: 8,
                )
              ] : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Hero Icon
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.activeGlow.withValues(alpha: 0.1),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: const Icon(Icons.mosque_rounded, size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 40),

                    Text("Wird", style: AppTextStyles.h1(color: Colors.white)),
                    const SizedBox(height: 16),
                    Text(
                      "Your mindful companion for\nstaying connected to the Divine.",
                      style: AppTextStyles.bodyLarge(color: Colors.white.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Features List (Single Column)
                    Column(
                      children: [
                        _buildFeatureRow(Icons.menu_book_rounded, "Quran with Translation"),
                        _buildFeatureRow(Icons.access_time_rounded, "Precise Prayer Times"),
                        _buildFeatureRow(Icons.explore_rounded, "Qibla Direction"),
                        _buildFeatureRow(Icons.auto_stories_rounded, "Sunnah Revival"),
                        _buildFeatureRow(Icons.fingerprint_rounded, "Digital Tasbih"),
                        _buildFeatureRow(Icons.notifications_active_rounded, "Adhan Reminders"),
                        _buildFeatureRow(Icons.wallpaper_rounded, "Dynamic Backgrounds"),
                      ],
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.spiritualGold),
          const SizedBox(width: 12),
          Text(text, style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeroIcon(Icons.location_on_rounded, AppColors.spiritualGold),
                    const SizedBox(height: 32),
                    Text("Set Location", style: AppTextStyles.h2()),
                    const SizedBox(height: 12),
                    Text(
                      "We calculate prayer times based on\nthe sun's position at your coordinates.",
                      style: AppTextStyles.body(color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Glass Card for Status
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              if (_location != null) ...[
                                const Icon(Icons.check_circle, color: AppColors.statusOnTime, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  _location!.displayName,
                                  style: AppTextStyles.h3(),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Coordinates set successfully",
                                  style: AppTextStyles.tiny(color: Colors.white54),
                                ),
                              ] else ...[
                                const Icon(Icons.public, color: Colors.white30, size: 32),
                                const SizedBox(height: 12),
                                Text("Location not set", style: AppTextStyles.body(color: Colors.white54)),
                              ],

                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Text(_error!, style: AppTextStyles.small(color: AppColors.statusMissed)),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildPrimaryButton(
                      label: _location != null ? "Refresh Location" : "Detect Location",
                      icon: Icons.my_location,
                      onPressed: _isLoading ? null : _getLocation,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalculationPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildHeroIcon(Icons.calculate_rounded, Colors.white),
          const SizedBox(height: 24),
          Text("Calculation Method", style: AppTextStyles.h2()),
          const SizedBox(height: 8),
          Text(
            "Select the convention used in your region.",
            style: AppTextStyles.body(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Methods List
          ...CalculationMethodType.values.take(5).map((method) {
            return _buildGlassSelectionTile(
              title: method.shortName,
              subtitle: method.regions,
              isSelected: _calculationMethod == method,
              onTap: () => setState(() => _calculationMethod = method),
            );
          }),

          const SizedBox(height: 32),
          Text("Asr Juristic Method", style: AppTextStyles.tiny(color: AppColors.spiritualGold).copyWith(letterSpacing: 2)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildGlassSelectionTile(
                  title: "Standard",
                  subtitle: "Shafi, Maliki, Hanbali",
                  isSelected: _madhab == MadhabType.shafi,
                  onTap: () => setState(() => _madhab = MadhabType.shafi),
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassSelectionTile(
                  title: "Hanafi",
                  subtitle: "Later Asr Time",
                  isSelected: _madhab == MadhabType.hanafi,
                  onTap: () => setState(() => _madhab = MadhabType.hanafi),
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeroIcon(Icons.notifications_active_rounded, AppColors.spiritualGold),
                    const SizedBox(height: 32),
                    Text("Stay Connected", style: AppTextStyles.h2()),
                    const SizedBox(height: 12),
                    Text(
                      "Gentle reminders for the 5 daily prayers.",
                      style: AppTextStyles.body(color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Status Card
                    if (_notificationPermissionGranted == true)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.statusOnTime.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.statusOnTime.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.statusOnTime),
                            const SizedBox(width: 12),
                            Text("Enabled Successfully", style: AppTextStyles.body(color: AppColors.statusOnTime)),
                          ],
                        ),
                      )
                    else
                      _buildPrimaryButton(
                        label: "Enable Notifications",
                        icon: Icons.notifications_none_rounded,
                        onPressed: _isLoading ? null : _requestNotificationPermission,
                        isLoading: _isLoading,
                      ),

                    const Spacer(),

                    // Summary Card
                    if (_location != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              children: [
                                Text("SUMMARY", style: AppTextStyles.tiny(color: Colors.white30)),
                                const SizedBox(height: 16),
                                _buildSummaryRow("City", _location!.city ?? "Unknown"),
                                const Divider(color: Colors.white10),
                                _buildSummaryRow("Method", _calculationMethod.shortName),
                                const Divider(color: Colors.white10),
                                _buildSummaryRow("Asr", _madhab == MadhabType.hanafi ? "Hanafi" : "Standard"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeroIcon(IconData icon, Color glowColor) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 5,
          )
        ],
      ),
      child: Icon(icon, size: 40, color: Colors.white),
    );
  }

  Widget _buildGlassSelectionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.spiritualGold.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.spiritualGold.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: compact
                        ? AppTextStyles.body(weight: FontWeight.bold)
                        : AppTextStyles.bodyLarge(weight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.tiny(color: Colors.white54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.spiritualGold, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.small(color: Colors.white54)),
          Text(
              value,
              style: AppTextStyles.small(color: Colors.white).copyWith(fontFamily: 'JetBrains Mono')
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: isLoading
            ? const PremiumFlowingLoader(size: 20, color: Colors.white)
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.button()),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final isLastPage = _currentPage == 3;
    final canProceed = (_currentPage != 1) || (_location != null);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background,
            AppColors.background.withValues(alpha: 0),
          ],
        ),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _previousPage,
              child: Text("Back", style: AppTextStyles.body(color: Colors.white60)),
            )
          else
            const SizedBox(width: 64), // Placeholder to balance layout

          const Spacer(),

          if (isLastPage)
            ElevatedButton(
              onPressed: (_isLoading || _location == null) ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.spiritualGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const PremiumFlowingLoader(size: 20, color: Colors.black)
                  : const Text("Get Started", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton(
              onPressed: canProceed ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.all(16),
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.arrow_forward_rounded),
            ),
        ],
      ),
    );
  }
}