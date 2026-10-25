import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import 'pressable.dart';

/// The standard hero header for a top-level page: a small letter-spaced
/// overline above the screen title.
///
/// Every top-level page should use this instead of re-implementing the pattern.
/// It had previously been hand-rolled on each screen and drifted apart — the gap
/// between overline and title was 4, 6 or 8 depending on the page, and the
/// overline opacity was 0.4 on one screen and 0.5 on the others.
///
/// [AppTextStyles.h1] is the documented "screen title" style, so the title is
/// always h1 here. The overline is the app's gold accent on every page;
/// [overlineColor] exists only for a deliberate exception.
///
/// Pushed pages pass [onBack] to get the shared back button above the overline,
/// and any page can put a small action in [trailing], aligned with the title.
class PageHeader extends StatelessWidget {
  /// Small letter-spaced label above the title, e.g. 'INSIGHTS'.
  final String overline;

  /// The screen title, e.g. 'Statistics'.
  final String title;

  /// Overrides the overline's gold. Leave null to match the rest of the app.
  final Color? overlineColor;

  /// Shows the back button when set.
  final VoidCallback? onBack;

  /// Optional action beside the title, such as a "Today" chip.
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.overline,
    required this.title,
    this.overlineColor,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          overline,
          style: AppTextStyles.tiny(
            color: overlineColor ?? AppColors.spiritualGold,
          ).copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(title, style: AppTextStyles.h1()),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null) ...[
          PageBackButton(onTap: onBack!),
          const SizedBox(height: 20),
        ],
        if (trailing == null)
          heading
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: heading),
              const SizedBox(width: 12),
              Padding(padding: const EdgeInsets.only(bottom: 4), child: trailing),
            ],
          ),
      ],
    );
  }
}

/// The round back button used at the top of pushed pages.
class PageBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const PageBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.88,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
