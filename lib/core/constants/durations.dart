/// Wird App Durations - Animation & Timing Constants
class AppDurations {
  AppDurations._();

  // ============================================
  // ANIMATION DURATIONS
  // ============================================

  /// Quick interactions (button press)
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard state changes
  static const Duration normal = Duration(milliseconds: 200);

  /// Screen transitions
  static const Duration slow = Duration(milliseconds: 300);

  /// Number roll animation
  static const Duration numberRoll = Duration(milliseconds: 400);

  /// Background gradient transition
  static const Duration gradientTransition = Duration(milliseconds: 5000);

  /// Active prayer card breathing pulse
  static const Duration breathingPulse = Duration(milliseconds: 2000);

  // ============================================
  // COUNTDOWN UPDATE INTERVALS
  // ============================================

  /// Update frequency when > 1 hour remaining
  static const Duration countdownUpdateLong = Duration(seconds: 60);

  /// Update frequency when < 1 hour remaining
  static const Duration countdownUpdateMedium = Duration(seconds: 30);

  /// Update frequency when < 5 minutes remaining
  static const Duration countdownUpdateShort = Duration(seconds: 1);

  // ============================================
  // NOTIFICATION TIMING
  // ============================================

  /// Default end-time warning before prayer ends
  static const int defaultEndWarningMinutes = 15;

  /// Available end-time warning options
  static const List<int> endWarningOptions = [5, 10, 15, 20, 30];

  /// Available snooze duration options
  static const List<int> snoozeDurationOptions = [5, 10, 15, 20];

  /// Maximum snoozes per prayer
  static const int maxSnoozesPerPrayer = 3;

  // ============================================
  // GRADIENT UPDATE TIMING
  // ============================================

  /// How often to check and update gradient (in seconds)
  static const int gradientUpdateSeconds = 60;

  /// Sun/moon position update interval (in seconds)
  static const int celestialUpdateSeconds = 300;

  // ============================================
  // MISC TIMING
  // ============================================

  /// Debounce for settings changes
  static const Duration settingsDebounce = Duration(milliseconds: 500);

  /// Toast display duration
  static const Duration toastDuration = Duration(seconds: 3);

  /// Splash screen minimum display
  static const Duration splashMinDuration = Duration(seconds: 2);

  /// Calibration animation duration
  static const Duration calibrationAnimation = Duration(milliseconds: 800);
}
