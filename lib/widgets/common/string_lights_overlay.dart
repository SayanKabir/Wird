import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A reusable animated string‑lights overlay.
///
/// Renders three catenary curves of twinkling bulbs using a [CustomPainter].
/// Wrap it in a [Positioned] or [SizedBox] to control where / how large
/// the lights appear. The widget is wrapped in [IgnorePointer] so it never
/// intercepts gestures.
class StringLightsOverlay extends StatefulWidget {
  const StringLightsOverlay({super.key});

  @override
  State<StringLightsOverlay> createState() => _StringLightsOverlayState();
}

class _StringLightsOverlayState extends State<StringLightsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _StringLightsPainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _StringLightsPainter extends CustomPainter {
  final double animValue;

  _StringLightsPainter(this.animValue);

  // Configuration: (sag ratio, y-offset ratio, number of bulbs, phase offset)
  static const _strings = [
    (0.65, 0.05, 11, 0.0),
    (0.85, 0.25, 13, 0.33),
    (0.45, -0.02, 8, 0.66),
  ];

  // A warm, festive palette for the bulbs
  static const _bulbColors = [
    Color(0xFFFFD27D), // Amber gold
    Color(0xFFFFF4E0), // Warm white
    Color(0xFFFFB677), // Soft peach/orange
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (final (sagRatio, yOffRatio, bulbCount, phase) in _strings) {
      final startX = -20.0;
      final endX = size.width + 20.0;
      final span = endX - startX;

      final yOff = size.height * yOffRatio;
      final sagPx = size.height * sagRatio;

      // Draw the wire as a quadratic bezier curve
      final wirePath = Path()
        ..moveTo(startX, yOff)
        ..quadraticBezierTo(startX + span / 2, yOff + sagPx, endX, yOff);
      canvas.drawPath(wirePath, wirePaint);

      // Draw individual bulbs along the curve
      for (var i = 1; i < bulbCount; i++) {
        final t = i / bulbCount;
        final x = startX + span * t;

        // Calculate Y position on the quadratic bezier curve
        final y = (1 - t) * (1 - t) * yOff +
            2 * (1 - t) * t * (yOff + sagPx) +
            t * t * yOff;

        final baseColor = _bulbColors[i % _bulbColors.length];

        // Complex wave logic for organic twinkling
        final bulbPhase = (animValue * math.pi * 2) + phase + (i * 1.3);
        final twinkle =
            (math.sin(bulbPhase) * math.cos(bulbPhase * 0.6) + 1) / 2;

        final opacity = 0.35 + (twinkle * 0.65);
        final radius = 1.8 + (twinkle * 0.8);

        // 1. Bulb Socket
        final socketPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y + 1), width: 2.5, height: 4),
          socketPaint,
        );

        // 2. Wide Ambient Glow
        final outerGlow = Paint()
          ..color = baseColor.withValues(alpha: opacity * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(Offset(x, y + 5), radius * 4.0, outerGlow);

        // 3. Tight, Intense Core Glow
        final innerGlow = Paint()
          ..color = baseColor.withValues(alpha: opacity * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(x, y + 5), radius * 1.5, innerGlow);

        // 4. Solid Glass Bulb (elongated teardrop/oval shape)
        final bulbPaint = Paint()
          ..color = Color.lerp(
                  Colors.white.withValues(alpha: 0.8), baseColor, twinkle)!
              .withValues(alpha: opacity);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y + 5),
            width: radius * 1.6,
            height: radius * 2.4,
          ),
          bulbPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StringLightsPainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}
