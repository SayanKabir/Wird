import 'package:flutter/animation.dart';

/// Shared easing curves. Use these instead of hand-picking a curve per
/// widget, so the whole app moves with one personality: quick to respond,
/// soft to settle.
class AppCurves {
  AppCurves._();

  /// Things entering, exiting or responding to a tap. Starts fast, so the
  /// change begins the moment the finger lands.
  static const Curve emphasized = Cubic(0.23, 1, 0.32, 1);

  /// Things moving from one place on screen to another.
  static const Curve move = Cubic(0.77, 0, 0.175, 1);

  /// Sheets and panels sliding in from an edge (iOS drawer curve).
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  /// Exits, for AnimatedSwitcher's switchOutCurve or a reverseCurve. Those
  /// play backwards, so this ease-in shape makes the leaving element start
  /// moving at once rather than lingering.
  static const Curve exit = Curves.easeInCubic;

  /// A single soft overshoot for small things settling into place (a
  /// released press, a tick, a filled bead). Never more than one wobble.
  static const Curve settle = Curves.easeOutBack;
}

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

  /// Pushing a new screen, and popping back from it (exits are quicker).
  static const Duration route = Duration(milliseconds: 300);
  static const Duration routeReverse = Duration(milliseconds: 240);

  /// Switching to a neighbouring tab by tapping its icon.
  static const Duration tabSlide = Duration(milliseconds: 300);

  /// Fading in a distant tab after jumping to it.
  static const Duration tabFade = Duration(milliseconds: 220);

  /// Gap between items in a staggered list entrance, and the most items that
  /// are staggered before the rest simply appear together.
  static const Duration stagger = Duration(milliseconds: 40);
  static const int staggerMaxItems = 6;

  /// Number roll animation
  static const Duration numberRoll = Duration(milliseconds: 400);

  /// Background gradient transition
  static const Duration gradientTransition = Duration(milliseconds: 5000);

  /// Scale-down/up on press for tappable elements. Deliberately brisk so the
  /// UI still feels responsive rather than laggy.
  static const Duration press = Duration(milliseconds: 120);

  /// Cross-fade when the weather reading replaces the placeholder, or when
  /// conditions change. Slow enough to read as a transition, not a glitch.
  static const Duration weatherFade = Duration(milliseconds: 600);

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
