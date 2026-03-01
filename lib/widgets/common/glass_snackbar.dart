import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import 'glass_container.dart';

class GlassSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        duration: duration,
        content: GlassContainer(
          opacity: 0.15,
          blur: 20,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderOpacity: 0.2,
          color: isError ? AppColors.statusMissed.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.4),
          child: Row(
            children: [
              if (isError) ...[
                const Icon(Icons.error_outline_rounded, color: AppColors.statusMissed, size: 20),
                const SizedBox(width: 12),
              ] else if (icon != null) ...[
                Icon(icon, color: AppColors.spiritualGold, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body(color: Colors.white),
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
    );
  }
}
