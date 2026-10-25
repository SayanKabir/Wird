import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import 'app_backdrop_filter.dart';

/// The one snackbar in Wird: dark glass, an icon in a soft gold disc, and
/// text that wraps. Use it sparingly, for things the user would otherwise
/// miss; actions that show their own result on screen don't need one.
class GlassSnackBar {
  /// Clears the floating tab bar on the home pages.
  static const double aboveNavBar = 96;

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    IconData? icon,
    double bottomMargin = 24,
  }) {
    final accent = isError ? AppColors.statusMissed : AppColors.spiritualGold;
    final shownIcon = isError ? Icons.error_outline_rounded : icon;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        padding: EdgeInsets.zero,
        duration: duration,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AppBackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            fallbackTint: AppBackdropFilter.sheetTint,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
              ),
              child: Row(
                children: [
                  if (shownIcon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), shape: BoxShape.circle),
                      child: Icon(shownIcon, color: accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      message,
                      style: AppTextStyles.small(color: Colors.white).copyWith(height: 1.4),
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: action.onPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.spiritualGold,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(action.label),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
