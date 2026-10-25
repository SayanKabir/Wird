import 'package:flutter/widgets.dart';

/// Wird App Spacing - one layout grid for every page.
///
/// Pages had each picked their own gutters (16, 20, 24 or a percentage of the
/// screen) and their own gap under the title, so swiping between tabs made the
/// content jump sideways. Everything top-level now reads from here.
class AppSpacing {
  AppSpacing._();

  /// Base step. Every gap below is a multiple of it.
  static const double unit = 4;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page margin: 24 on most phones, easing to 16 on narrow ones.
  static double gutter(BuildContext context) =>
      (MediaQuery.sizeOf(context).width * 0.06).clamp(16.0, 24.0);

  /// Space above a page title, below the status bar.
  static const double pageTop = 24;

  /// Space between a page title and the first piece of content.
  static const double belowHeader = 24;

  /// Gap between two sections on a page.
  static const double section = 32;

  /// Clearance for the floating navigation capsule at the bottom of a tab.
  static double navClearance(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 100;

  /// Padding for the [PageHeader] block of a top-level page.
  static EdgeInsets header(BuildContext context) {
    final g = gutter(context);
    return EdgeInsets.fromLTRB(g, pageTop, g, belowHeader);
  }

  /// Corner radii, from row-sized to sheet-sized.
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
}
