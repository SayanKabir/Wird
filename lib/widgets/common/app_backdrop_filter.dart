import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/services/device_profile.dart';

/// [BackdropFilter] that steps aside when lighter visuals are in effect
/// (Reduce motion, or a weak device by default). Live blur is the most
/// expensive effect in the app; without it the glass gets a flat tint of the
/// app's night colour instead, painted inside the same clip.
///
/// [fallbackTint] is how opaque that tint is: light for cards over the sky,
/// denser for sheets and dialogs that sit over busy content.
class AppBackdropFilter extends StatelessWidget {
  final ImageFilter filter;
  final Widget child;
  final double fallbackTint;

  const AppBackdropFilter({
    super.key,
    required this.filter,
    required this.child,
    this.fallbackTint = 0.18,
  });

  /// For bottom sheets and dialogs: nearly opaque, since without the blur
  /// the page behind would otherwise read straight through.
  static const double sheetTint = 0.97;

  @override
  Widget build(BuildContext context) {
    if (!lighterVisuals()) return BackdropFilter(filter: filter, child: child);
    return ColoredBox(
      color: AppColors.background.withValues(alpha: fallbackTint),
      child: child,
    );
  }
}
