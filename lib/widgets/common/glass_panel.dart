import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/effects.dart';

/// The app's one glass surface: a translucent panel with a hairline edge
/// that frosts whatever is behind it.
///
/// Blur follows one rule everywhere: on in Balanced and Smooth, off in Lite
/// (and whenever the device asks for lighter visuals; see [AppEffects.blur]).
/// Without the blur the fill thickens a little so text stays as legible.
/// Screens used to decide this one by one, so some frosted and some didn't.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;

  /// White fill opacity with blur on.
  final double fill;

  /// Hairline edge opacity.
  final double edge;
  final double edgeWidth;

  /// Replaces the white fill, e.g. a gold-tinted highlight card.
  final Gradient? gradient;

  /// A solid tint in place of the white fill.
  final Color? color;

  /// Replaces the white edge colour.
  final Color? edgeColor;

  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.margin,
    this.width,
    this.fill = 0.06,
    this.edge = 0.1,
    this.edgeWidth = 1,
    this.gradient,
    this.color,
    this.edgeColor,
  });

  static const double _sigma = 12;

  @override
  Widget build(BuildContext context) {
    final blur = AppEffects.blur;
    final shape = BorderRadius.circular(radius);

    Widget panel = Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient != null ? null : color ?? Colors.white.withValues(alpha: blur ? fill : fill + 0.05),
        gradient: gradient,
        borderRadius: shape,
        border: Border.all(
          color: edgeColor ?? Colors.white.withValues(alpha: edge),
          width: edgeWidth,
        ),
      ),
      child: child,
    );

    if (blur) {
      panel = ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: _sigma, sigmaY: _sigma), child: panel),
      );
    }
    return margin == null ? panel : Padding(padding: margin!, child: panel);
  }
}
