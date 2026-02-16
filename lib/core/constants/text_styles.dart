import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wird App Typography - Text Styles
/// 
/// Uses Inter font for primary text (via Google Fonts)
/// Arabic text uses Amiri or system Arabic font
class AppTextStyles {
  AppTextStyles._();

  /// Default text shadow for better readability
  static final List<Shadow> _shadows = [
    Shadow(
      color: Colors.black.withOpacity(0.2),
      offset: const Offset(0, 1),
      blurRadius: 4,
    ),
  ];

  // ============================================
  // HEADING STYLES
  // ============================================

  /// H1 - Screen titles (32px Bold)
  static TextStyle h1({Color? color}) => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: color ?? Colors.white,
    height: 1.2,
    shadows: _shadows,
  );

  /// H2 - Section headers (24px Semibold)
  static TextStyle h2({Color? color}) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white,
    height: 1.3,
    shadows: _shadows,
  );

  /// H3 - Subsection headers (20px Semibold)
  static TextStyle h3({Color? color}) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white,
    height: 1.3,
    shadows: _shadows,
  );

  // ============================================
  // BODY STYLES
  // ============================================

  /// Body Large - Prayer names, important info (18px Regular)
  static TextStyle bodyLarge({Color? color, FontWeight? weight}) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? Colors.white,
    height: 1.5,
    shadows: _shadows,
  );

  /// Body - Times, descriptions (16px Regular)
  static TextStyle body({Color? color, FontWeight? weight}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? Colors.white,
    height: 1.5,
    shadows: _shadows,
  );

  /// Body Medium - Medium emphasis body text
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.white,
    height: 1.5,
    shadows: _shadows,
  );

  // ============================================
  // SMALL STYLES
  // ============================================

  /// Small - Labels, captions (14px Regular)
  static TextStyle small({Color? color, FontWeight? weight}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? Colors.white.withOpacity(0.8),
    height: 1.4,
    shadows: _shadows,
  );

  /// Tiny - Metadata (12px Regular)
  static TextStyle tiny({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.white.withOpacity(0.6),
    height: 1.4,
    shadows: _shadows,
  );

  // ============================================
  // SPECIAL STYLES
  // ============================================

  /// Countdown - Large countdown display (48px Bold)
  static TextStyle countdown({Color? color}) => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: color ?? Colors.white,
    height: 1.1,
    letterSpacing: 2,
    shadows: _shadows,
  );

  /// Countdown Medium - Medium countdown (32px Bold)
  static TextStyle countdownMedium({Color? color}) => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: color ?? Colors.white,
    height: 1.1,
    letterSpacing: 1,
    shadows: _shadows,
  );

  /// Streak number display
  static TextStyle streak({Color? color}) => GoogleFonts.inter(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: color ?? Colors.white,
    height: 1.1,
  );

  /// Button text
  static TextStyle button({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Prayer time display
  static TextStyle prayerTime({Color? color}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color ?? Colors.white.withOpacity(0.9),
    height: 1.3,
  );

  // ============================================
  // ARABIC STYLES
  // ============================================

  /// Arabic prayer name
  static TextStyle arabic({Color? color, double? size}) => TextStyle(
    fontFamily: 'Amiri',
    fontSize: size ?? 18,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.white.withOpacity(0.8),
    height: 1.5,
  );

  /// Arabic large (for display)
  static TextStyle arabicLarge({Color? color}) => TextStyle(
    fontFamily: 'Amiri',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.white,
    height: 1.4,
  );

  // ============================================
  // LABEL STYLES
  // ============================================

  /// Label - Form labels, section titles
  static TextStyle label({Color? color}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white.withOpacity(0.9),
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Overline - Small caps style labels
  static TextStyle overline({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white.withOpacity(0.7),
    height: 1.2,
    letterSpacing: 1.5,
  );
}
