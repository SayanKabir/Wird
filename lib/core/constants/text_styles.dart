import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/settings.dart';

/// Wird App Typography - Text Styles
///
/// One family, one scale. Inter carries all Latin text; Arabic UI text uses
/// Amiri and Quran text uses the bundled mushaf fonts (see [arabic]).
///
/// | Style        | Size | Use                                            |
/// |--------------|------|------------------------------------------------|
/// | h1           | 32   | Page titles (via PageHeader)                   |
/// | h2           | 24   | Sheet and dialog titles, hero numbers          |
/// | h3           | 20   | Card titles                                    |
/// | bodyLarge    | 18   | Emphasised single lines                        |
/// | body         | 16   | Row titles, paragraphs                         |
/// | small        | 14   | Secondary lines, values                        |
/// | tiny         | 12   | Metadata, captions                             |
/// | sectionLabel | 12   | Spaced caps above a group of rows              |
///
/// Numbers that tick or sit in columns (times, counters, dates) go through
/// [tabular] so their digits keep the same width. Pages used to reach for
/// 'JetBrains Mono' for this, a font the app never bundled, so those numbers
/// silently fell back to the platform font and looked out of place.
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
  // FONT RESOLUTION (memoised)
  // ============================================
  //
  // Every GoogleFonts.*() call re-runs the package's variant matching and
  // loader bookkeeping — roughly 200x the cost of building a plain TextStyle —
  // and these helpers are called from inside build() all over the app. A single
  // Quran surah row builds five of them, so it added up on every scroll frame.
  //
  // The lookup is cached PER WEIGHT, not as one base style. Caching a single
  // base and copyWith-ing the weight would be wrong: google_fonts resolves a
  // different font file per weight, so overriding fontWeight afterwards yields
  // synthetic bold instead of real Inter Bold. Keying on weight keeps the
  // correct variant while skipping the repeat lookup. fontSize / color /
  // height / letterSpacing / shadows are all safe to copyWith — none of them
  // selects a different font file.

  static final Map<FontWeight, TextStyle> _interByWeight = {};

  static TextStyle _inter(FontWeight weight) => _interByWeight.putIfAbsent(
        weight,
        () => GoogleFonts.inter(fontWeight: weight),
      );

  static TextStyle? _amiriBase;

  static TextStyle _amiri() => _amiriBase ??= GoogleFonts.amiri();

  // Bundled mushaf fonts (see pubspec.yaml). Each is drawn for the matching
  // Quran.com text, so waqf marks and ligatures render as in a printed mushaf.
  static const TextStyle _uthmanicHafs = TextStyle(fontFamily: 'UthmanicHafs');
  static const TextStyle _indoPakNastaleeq = TextStyle(fontFamily: 'IndoPakNastaleeq');

  /// Inter at an arbitrary size, through the same per-weight cache. For the
  /// few places (the Quran reader's user-sized text) that can't use a step
  /// of the scale above. Prefer the named styles everywhere else.
  static TextStyle inter({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
  }) =>
      _inter(fontWeight).copyWith(fontSize: fontSize, color: color, height: height);

  // ============================================
  // HEADING STYLES
  // ============================================

  /// H1 - Screen titles (32px Bold)
  static TextStyle h1({Color? color}) => _inter(FontWeight.w700).copyWith(
    fontSize: 32,
    color: color ?? Colors.white,
    height: 1.2,
    shadows: _shadows,
  );

  /// Large light numerals for dhikr counters; tabular so digits don't shift
  /// sideways as the count changes.
  static TextStyle counter({Color? color, double size = 68}) => _inter(FontWeight.w300).copyWith(
    fontSize: size,
    color: color ?? Colors.white,
    height: 1.1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// H2 - Section headers (24px Semibold)
  static TextStyle h2({Color? color}) => _inter(FontWeight.w600).copyWith(
    fontSize: 24,
    color: color ?? Colors.white,
    height: 1.3,
    shadows: _shadows,
  );

  /// H3 - Subsection headers (20px Semibold)
  static TextStyle h3({Color? color}) => _inter(FontWeight.w600).copyWith(
    fontSize: 20,
    color: color ?? Colors.white,
    height: 1.3,
    shadows: _shadows,
  );

  // ============================================
  // BODY STYLES
  // ============================================

  /// Body Large - Prayer names, important info (18px Regular)
  static TextStyle bodyLarge({Color? color, FontWeight? weight}) =>
      _inter(weight ?? FontWeight.w400).copyWith(
    fontSize: 18,
    color: color ?? Colors.white,
    height: 1.5,
    shadows: _shadows,
  );

  /// Body - Times, descriptions (16px Regular)
  static TextStyle body({Color? color, FontWeight? weight}) =>
      _inter(weight ?? FontWeight.w400).copyWith(
    fontSize: 16,
    color: color ?? Colors.white,
    height: 1.5,
    shadows: _shadows,
  );

  /// Body Medium - Medium emphasis body text
  static TextStyle bodyMedium({Color? color}) => _inter(FontWeight.w500).copyWith(
    fontSize: 16,
    color: color ?? Colors.white,
    height: 1.5,
    shadows: _shadows,
  );

  // ============================================
  // SMALL STYLES
  // ============================================

  /// Small - Labels, captions (14px Regular)
  static TextStyle small({Color? color, FontWeight? weight}) =>
      _inter(weight ?? FontWeight.w400).copyWith(
    fontSize: 14,
    color: color ?? Colors.white.withOpacity(0.8),
    height: 1.4,
    shadows: _shadows,
  );

  /// Tiny - Metadata (12px Regular)
  static TextStyle tiny({Color? color}) => _inter(FontWeight.w400).copyWith(
    fontSize: 12,
    color: color ?? Colors.white.withOpacity(0.6),
    height: 1.4,
    shadows: _shadows,
  );

  // ============================================
  // SPECIAL STYLES
  // ============================================

  /// Countdown - Large countdown display (48px Bold)
  static TextStyle countdown({Color? color}) => _inter(FontWeight.w700).copyWith(
    fontSize: 48,
    color: color ?? Colors.white,
    height: 1.1,
    letterSpacing: 2,
    shadows: _shadows,
  );

  /// Countdown Medium - Medium countdown (32px Bold)
  static TextStyle countdownMedium({Color? color}) => _inter(FontWeight.w700).copyWith(
    fontSize: 32,
    color: color ?? Colors.white,
    height: 1.1,
    letterSpacing: 1,
    shadows: _shadows,
  );

  /// Streak number display
  static TextStyle streak({Color? color}) => _inter(FontWeight.w800).copyWith(
    fontSize: 40,
    color: color ?? Colors.white,
    height: 1.1,
  );

  /// Button text
  static TextStyle button({Color? color}) => _inter(FontWeight.w600).copyWith(
    fontSize: 16,
    color: color ?? Colors.white,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Prayer time display
  static TextStyle prayerTime({Color? color}) => _inter(FontWeight.w500).copyWith(
    fontSize: 14,
    color: color ?? Colors.white.withOpacity(0.9),
    height: 1.3,
  );

  // ============================================
  // ARABIC STYLES
  // ============================================

  /// Arabic text.
  ///
  /// Pass [script] when rendering Quran verses so the matching mushaf font is
  /// used: IndoPak Nastaleeq for Indo-Pak (the South Asian mushaf hand, with
  /// its own waqf marks) and KFGQPC Uthmanic Hafs for Uthmani (the Madinah
  /// mushaf). Both are bundled and drawn for Quran.com's text of that script.
  ///
  /// Leave [script] null for ordinary Arabic UI text — prayer names, dhikr,
  /// duas — which keeps using plain Amiri.
  static TextStyle arabic({Color? color, double? size, QuranScript? script}) {
    switch (script) {
      case QuranScript.indopak:
        return _indoPakNastaleeq.copyWith(
          fontSize: size ?? 18,
          fontWeight: FontWeight.w400,
          color: color ?? Colors.white.withOpacity(0.8),
          height: 1.5,
        );
      case QuranScript.uthmani:
        return _uthmanicHafs.copyWith(
          fontSize: size ?? 18,
          fontWeight: FontWeight.w400,
          color: color ?? Colors.white.withOpacity(0.8),
          height: 1.5,
        );
      case null:
        return _amiri().copyWith(
          fontSize: size ?? 18,
          fontWeight: FontWeight.w400,
          color: color ?? Colors.white.withOpacity(0.8),
          height: 1.5,
        );
    }
  }

  /// Arabic large (for display). See [arabic] for the [script] semantics.
  static TextStyle arabicLarge({Color? color, QuranScript? script}) {
    switch (script) {
      case QuranScript.indopak:
        return _indoPakNastaleeq.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: color ?? Colors.white,
          height: 1.4,
        );
      case QuranScript.uthmani:
        return _uthmanicHafs.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: color ?? Colors.white,
          height: 1.4,
        );
      case null:
        return _amiri().copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: color ?? Colors.white,
          height: 1.4,
        );
    }
  }

  // ============================================
  // LABEL STYLES
  // ============================================

  /// Label - Form labels, section titles
  static TextStyle label({Color? color}) => _inter(FontWeight.w600).copyWith(
    fontSize: 14,
    color: color ?? Colors.white.withOpacity(0.9),
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Section label - spaced capitals above a group of rows or cards.
  static TextStyle sectionLabel({Color? color}) => _inter(FontWeight.w700).copyWith(
    fontSize: 12,
    color: color ?? Colors.white.withOpacity(0.5),
    height: 1.2,
    letterSpacing: 2,
  );

  /// Same glyphs, fixed-width digits, so a ticking time doesn't jitter.
  static TextStyle tabular(TextStyle style) => style.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Overline - Small caps style labels
  static TextStyle overline({Color? color}) => _inter(FontWeight.w600).copyWith(
    fontSize: 12,
    color: color ?? Colors.white.withOpacity(0.7),
    height: 1.2,
    letterSpacing: 1.5,
  );
}
