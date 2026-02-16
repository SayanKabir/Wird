import 'package:flutter/material.dart';
import '../services/prayer_service.dart' show PrayerPeriod;

/// Wird App Colors - Celestial Zen Design System
/// 
/// Dynamic gradient colors based on prayer time periods
class AppColors {
  AppColors._();

  // ============================================
  // BASE COLORS
  // ============================================

  /// Primary dark background
  static const Color background = Color(0xFF0A0E21);

  /// Card surfaces with glassmorphism
  static const Color cardBackground = Color(0x1AFFFFFF); // 10% white
  static const Color cardBackgroundHover = Color(0x33FFFFFF); // 20% white

  /// Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xCCFFFFFF); // 80% white
  static const Color textTertiary = Color(0x99FFFFFF); // 60% white
  static const Color textDisabled = Color(0x4DFFFFFF); // 30% white

  // ============================================
  // STATUS COLORS
  // ============================================

  /// Prayer status colors
  static const Color statusOnTime = Color(0xFF4CAF50);
  static const Color statusLate = Color(0xFFFF9800);
  static const Color statusMissed = Color(0xFFE53935);
  static const Color statusPending = Color(0xFF4DD0E1);
  static const Color statusUpcoming = Color(0x99FFFFFF);

  /// Active prayer glow
  static const Color activeGlow = Color(0xFF80CBC4); // Soft Teal 200
  static const Color activeGlowSoft = Color(0x4D80CBC4);

  // ============================================
  // CELESTIAL GRADIENTS
  // ============================================

  /// Tahajjud (Last third of night) - Deep spiritual stillness
  static const List<Color> tahajjudGradient = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
    Color(0xFF0F3460),
  ];

  /// Fajr (Dawn) - Hopeful awakening
  static const List<Color> fajrGradient = [
    Color(0xFF2E1A47),
    Color(0xFF4A2C6A),
    Color(0xFFFFB88C),
    Color(0xFF87CEEB),
  ];

  /// Sunrise - Warm golden rose (beautiful & readable)
  static const List<Color> sunriseGradient = [
    Color(0xFFE55D87),  // Rose pink
    Color(0xFFF2994A),  // Warm tangerine
    Color(0xFFD4546A),  // Dusty coral rose
  ];

  /// Dhuhr (Noon) - Clear sky (muted for contrast)
  static const List<Color> dhuhrGradient = [
    Color(0xFF1E5799),  // Deep sky blue
    Color(0xFF2980B9),  // Belize blue
    Color(0xFF3498B8),  // Muted teal
  ];

  /// Asr (Afternoon) - Warm golden hour with better text contrast
  static const List<Color> asrGradient = [
    Color(0xFFD97706), // Deep amber
    Color(0xFFC2410C), // Burnt orange
    Color(0xFF92400E), // Russet brown
  ];

  /// Maghrib (Sunset) - Contemplative beauty
  static const List<Color> maghribGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFEE5A24),
    Color(0xFF8E44AD),
    Color(0xFF2C3E50),
  ];

  /// Isha (Night) - Peaceful closure
  static const List<Color> ishaGradient = [
    Color(0xFF2C3E50),
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
  ];

  // ============================================
  // PRAYER ACCENT COLORS
  // ============================================

  static const Color fajrAccent = Color(0xFFB19CD9);
  static const Color dhuhrAccent = Color(0xFFFFD93D);
  static const Color asrAccent = Color(0xFFFFB347);
  static const Color maghribAccent = Color(0xFFFF6B6B);
  static const Color ishaAccent = Color(0xFF6C5CE7);
  static const Color tahajjudAccent = Color(0xFF0984E3);
  static const Color ishraqAccent = Color(0xFFFFBE76);
  static const Color duhaAccent = Color(0xFFF9CA24);
  static const Color jumuahAccent = Color(0xFF00CEC9);

  // ============================================
  // QIBLA COLORS
  // ============================================

  static const Color qiblaAligned = Color(0xFF4CAF50);
  static const Color qiblaClose = Color(0xFFFFC107);
  static const Color qiblaFar = Color(0xFFE53935);
  static const Color compassRose = Color(0x99FFFFFF);
  static const Color kaabaGold = Color(0xFFD4AF37);

  // The primary gold used for active states, streaks, and guidance
  static const Color spiritualGold = Color(0xFFFDE047);

  // ============================================
  // UI ELEMENTS
  // ============================================

  static const Color divider = Color(0x1AFFFFFF);
  static const Color border = Color(0x33FFFFFF);
  static const Color shadow = Color(0x1A000000);

  /// Button colors
  static const Color buttonPrimary = Color(0xFF4DB6AC); // Teal 300
  static const Color buttonSecondary = Color(0x33FFFFFF);
  static const Color buttonDisabled = Color(0x1AFFFFFF);

  // ============================================
  // STREAK COLORS
  // ============================================

  static const Color streakFire = Color(0xFFFF6B6B);
  static const Color streakGold = Color(0xFFFFD700);

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get gradient colors for a specific prayer period
  static List<Color> getGradientForPeriod(PrayerPeriod period) {
    switch (period) {
      case PrayerPeriod.tahajjud:
        return tahajjudGradient;
      case PrayerPeriod.fajr:
        return fajrGradient;
      case PrayerPeriod.sunrise:
        return sunriseGradient;
      case PrayerPeriod.dhuhr:
        return dhuhrGradient;
      case PrayerPeriod.asr:
        return asrGradient;
      case PrayerPeriod.maghrib:
        return maghribGradient;
      case PrayerPeriod.isha:
        return ishaGradient;
    }
  }

  /// Check if the period constitutes a light/bright background
  static bool isLightBackground(PrayerPeriod period) {
    return period == PrayerPeriod.sunrise ||
           period == PrayerPeriod.dhuhr;
  }

  /// Get appropriate content color (text/icons) for the period
  static Color getContentColor(PrayerPeriod period) {
    // if (isLightBackground(period)) {
    //   return const Color(0xFF1A1A2E); // Dark text for bright backgrounds
    // }
    return Colors.white; // White text for dark backgrounds
  }

  /// Get semi-transparent glass color optimized for contrast
  static Color getGlassColor(PrayerPeriod period) {
    if (isLightBackground(period)) {
      return Colors.black.withOpacity(0.08); // Dark tint on light bg
    }
    return Colors.white.withOpacity(0.1); // White tint on dark bg
  }

}
