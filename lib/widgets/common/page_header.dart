import 'package:flutter/material.dart';

import '../../core/constants/text_styles.dart';

/// The standard hero header for a top-level page: a small letter-spaced
/// overline above the screen title.
///
/// Every top-level page should use this instead of re-implementing the pattern.
/// It had previously been hand-rolled on each screen and drifted apart — the gap
/// between overline and title was 4, 6 or 8 depending on the page, and the
/// overline opacity was 0.4 on one screen and 0.5 on the others.
///
/// [AppTextStyles.h1] is the documented "screen title" style, so the title is
/// always h1 here. Pass [overlineColor] for pages that accent the overline
/// (Quran and Sunnah use [AppColors.spiritualGold]); it defaults to muted white.
class PageHeader extends StatelessWidget {
  /// Small letter-spaced label above the title, e.g. 'INSIGHTS'.
  final String overline;

  /// The screen title, e.g. 'Statistics'.
  final String title;

  /// Optional accent colour for the overline. Defaults to white at 50% opacity.
  final Color? overlineColor;

  const PageHeader({
    super.key,
    required this.overline,
    required this.title,
    this.overlineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          overline,
          style: AppTextStyles.tiny(
            color: overlineColor ?? Colors.white.withValues(alpha: 0.5),
          ).copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(title, style: AppTextStyles.h1()),
      ],
    );
  }
}
