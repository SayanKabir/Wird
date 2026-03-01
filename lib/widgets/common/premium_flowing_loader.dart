import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A simple, elegant crescent moon that smoothly "fills up" with light,
/// surrounded by tiny, twinkling 4-pointed stars.
class PremiumFlowingLoader extends StatefulWidget {
  final double size;
  final Color color;

  const PremiumFlowingLoader({
    super.key,
    this.size = 55.0, // Slightly bumped to accommodate the sparkles
    this.color = const Color(0xFFD4AF37), // AppColors.spiritualGold
  });

  @override
  State<PremiumFlowingLoader> createState() => _PremiumFlowingLoaderState();
}

class _PremiumFlowingLoaderState extends State<PremiumFlowingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();

    // A soothing 2-second cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true); // Fills up, then empties smoothly

    // Ease-in-out makes the liquid/fill motion feel natural
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fillAnimation,
      builder: (context, child) {
        return Transform.rotate(
          // Tilt the moon slightly back for a natural celestial look
          angle: -math.pi / 6,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _FillingCrescentPainter(
                color: widget.color,
                progress: _fillAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FillingCrescentPainter extends CustomPainter {
  final Color color;
  final double progress;

  _FillingCrescentPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Scale the moon down slightly to leave padding for the stars
    final moonRadius = (size.width / 2) * 0.75;

    // 1. Mathematically carve a perfect crescent shape
    final outer = Path()..addOval(Rect.fromCircle(center: center, radius: moonRadius));

    // Shift the inner circle up and to the right to create the cut-out
    final innerOffset = Offset(center.dx + moonRadius * 0.4, center.dy - moonRadius * 0.1);
    final inner = Path()..addOval(Rect.fromCircle(center: innerOffset, radius: moonRadius * 0.95));

    final crescent = Path.combine(PathOperation.difference, outer, inner);

    // 2. Draw the "Empty" Glass Background
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(crescent, bgPaint);
    canvas.drawPath(crescent, borderPaint);

    // 3. Draw the "Filled" Foreground (Clipped to the progress)
    if (progress > 0) {
      canvas.save();

      // Create a bounding box that grows from the bottom to the top
      // We use the full size.height to ensure the moon is fully covered
      final fillHeight = size.height * progress;
      final clipRect = Rect.fromLTRB(
          0,
          size.height - fillHeight,
          size.width,
          size.height
      );

      // Only draw inside the current fill level
      canvas.clipRect(clipRect);

      // Add a glowing bloom to the filled portion
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawPath(crescent, glowPaint);

      // Solid color fill
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(crescent, fillPaint);

      canvas.restore();
    }

    // 4. Draw the Twinkling Stars
    // Star 1: Top right (glows as the moon fills)
    _drawSparkle(canvas, Offset(size.width * 0.85, size.height * 0.25), size.width * 0.12, progress);

    // Star 2: Bottom left (glows as the moon empties)
    _drawSparkle(canvas, Offset(size.width * 0.15, size.height * 0.8), size.width * 0.1, 1.0 - progress);

    // Star 3: Top left (fast twinkle using sine wave)
    _drawSparkle(canvas, Offset(size.width * 0.2, size.height * 0.2), size.width * 0.08, math.sin(progress * math.pi));
  }

  /// Draws a mathematically perfect 4-pointed star using bezier curves
  void _drawSparkle(Canvas canvas, Offset pos, double maxRadius, double twinkle) {
    if (twinkle <= 0.01) return; // Don't draw if invisible

    // Scale the star based on the twinkle value
    final r = maxRadius * (0.4 + 0.6 * twinkle);

    final path = Path()
      ..moveTo(pos.dx, pos.dy - r) // Top
      ..quadraticBezierTo(pos.dx, pos.dy, pos.dx + r, pos.dy) // Right
      ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + r) // Bottom
      ..quadraticBezierTo(pos.dx, pos.dy, pos.dx - r, pos.dy) // Left
      ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - r) // Back to Top
      ..close();

    // Star Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.6 * twinkle)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(path, glowPaint);

    // Star Core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * twinkle)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _FillingCrescentPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}