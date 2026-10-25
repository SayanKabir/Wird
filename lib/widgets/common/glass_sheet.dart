import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/effects.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';

/// Opens a bottom sheet in the app's frosted-glass style: drag handle, an
/// optional title, and [child] beneath. Blur is skipped in Lite mode.
///
/// Settings pickers, the Quran list options and the exit prompt all go through
/// this so the three sheets look and move alike.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? subtitle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) => GlassSheet(title: title, subtitle: subtitle, child: child),
  );
}

class GlassSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;

  const GlassSheet({super.key, this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl));
    final blur = AppEffects.blur;

    Widget body = Container(
      decoration: BoxDecoration(
        // Without the blur behind it the sheet needs a near-solid fill to read.
        color: blur
            ? const Color(0xFF151A2E).withValues(alpha: 0.72)
            : const Color(0xFF151A2E),
        borderRadius: radius,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
                child: Text(title!, style: AppTextStyles.h2()),
              ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
                child: Text(subtitle!, style: AppTextStyles.small(color: Colors.white60)),
              ),
            if (title != null || subtitle != null) const SizedBox(height: AppSpacing.sm),
            Flexible(child: child),
          ],
        ),
      ),
    );

    if (blur) {
      body = BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: body);
    }
    return ClipRRect(borderRadius: radius, child: body);
  }
}
