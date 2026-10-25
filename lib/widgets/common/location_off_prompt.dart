import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/location_service.dart';
import 'glass_snackbar.dart';
import 'app_backdrop_filter.dart';

/// Follow-up when device location is still off after [LocationService]
/// asked for it.
///
/// On Android the user has already seen (and dismissed) the system
/// "Turn on location" dialog, so we only leave a quiet snackbar with a
/// shortcut to settings. iOS can't show that system dialog at all, so there
/// we explain and offer to open Settings.
/// Pass [aboveNavBar] when shown from a home tab, so the snackbar clears
/// the floating tab bar.
Future<void> showLocationOffPrompt(BuildContext context, {bool aboveNavBar = false}) async {
  if (Platform.isAndroid) {
    GlassSnackBar.show(
      context,
      message: 'Location is off. Turn it on to detect your city.',
      isError: true,
      bottomMargin: aboveNavBar ? GlassSnackBar.aboveNavBar : 24,
      action: SnackBarAction(
        label: 'Settings',
        textColor: AppColors.spiritualGold,
        onPressed: () => LocationService().openLocationSettings(),
      ),
    );
    return;
  }

  final open = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (c) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AppBackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          fallbackTint: AppBackdropFilter.sheetTint,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_rounded, size: 48, color: AppColors.spiritualGold),
                const SizedBox(height: 16),
                Text('Turn On Location', style: AppTextStyles.h2(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Location Services are off. Turn them on in Settings › Privacy & Security › Location Services so Wird can find accurate prayer times for your city.',
                  style: AppTextStyles.body(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Not Now', style: AppTextStyles.body(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(c, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.spiritualGold.withValues(alpha: 0.2),
                          foregroundColor: AppColors.spiritualGold,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppColors.spiritualGold.withValues(alpha: 0.5)),
                          ),
                        ),
                        child: const Text('Open Settings'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (open == true) {
    await LocationService().openLocationSettings();
  }
}
