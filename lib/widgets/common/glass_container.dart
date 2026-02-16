import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable container that implements the glassmorphism effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderOpacity;
  final Color? color;
  final BoxShape shape;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.opacity = 0.20,
    this.blur = 12.0,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.borderOpacity = 0.3,
    this.color,
    this.shape = BoxShape.rectangle,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;
    final shouldBlur = blur > 0;

    Widget glassContent = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        // Use a semi-transparent overlay for the glass effect
        color: effectiveColor.withValues(alpha: opacity),
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveColor.withValues(alpha: borderOpacity),
          width: 1.0,
        ),
        // Removed dark shadow - no more grey appearance on bright backgrounds
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );

    if (shouldBlur) {
      glassContent = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: glassContent,
      );
    }

    Widget content = ClipRRect(
      borderRadius: shape == BoxShape.circle 
          ? BorderRadius.circular(1000) 
          : BorderRadius.circular(borderRadius),
      child: glassContent,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
