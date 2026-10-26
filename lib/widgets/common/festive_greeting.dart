import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/festive/festive_occasion.dart';
import '../../core/services/device_profile.dart';
import 'festive_canopy.dart';

/// The full-screen greeting on the first open of an Eid or Arafah day: a
/// crescent, the greeting, the Hijri date and a short blessing, with
/// lanterns rising behind. Tap anywhere, or wait a few seconds, and it
/// fades away; [onDone] then records that today's greeting was seen.
class FestiveGreeting extends StatefulWidget {
  final FestiveOccasion occasion;
  final VoidCallback onDone;

  const FestiveGreeting({super.key, required this.occasion, required this.onDone});

  @override
  State<FestiveGreeting> createState() => _FestiveGreetingState();
}

class _FestiveGreetingState extends State<FestiveGreeting> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  Timer? _auto;
  bool _leaving = false;

  static const _glass = [Color(0xFFFFB347), Color(0xFF4FD1C5), Color(0xFFFF7A90), Color(0xFFFFD27D)];

  @override
  void initState() {
    super.initState();
    if (!motionStill()) _rise.repeat();
    _auto = Timer(const Duration(milliseconds: 4500), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_leaving) return;
    _leaving = true;
    _auto?.cancel();
    await _in.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _in.dispose();
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final fade = CurvedAnimation(parent: _in, curve: Curves.easeOutCubic);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss,
      child: FadeTransition(
        opacity: fade,
        child: Container(
          color: const Color(0xFF070C20).withValues(alpha: 0.9),
          child: Stack(
            children: [
              // Lanterns drifting up, each on its own part of the loop.
              for (var i = 0; i < 4; i++)
                AnimatedBuilder(
                  animation: _rise,
                  builder: (context, child) {
                    final p = (_rise.value + i / 4) % 1.0;
                    return Positioned(
                      left: size.width * (0.14 + 0.24 * i) - 20,
                      top: size.height * (1.05 - 1.2 * p),
                      child: Opacity(
                        opacity: (p < 0.15 ? p / 0.15 : (1 - p) / 0.85).clamp(0.0, 1.0) * 0.85,
                        child: child,
                      ),
                    );
                  },
                  child: FestiveLantern(glass: _glass[i], size: 40, phase: i * 0.3),
                ),
              Center(
                child: ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(fade),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _GlowingCrescent(size: 96),
                      const SizedBox(height: 28),
                      Text(widget.occasion.greeting, style: AppTextStyles.display(size: 42)),
                      const SizedBox(height: 10),
                      Text(
                        widget.occasion.hijri.formatEnglish().toUpperCase(),
                        style: AppTextStyles.tiny(color: AppColors.spiritualGold)
                            .copyWith(letterSpacing: 3, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        widget.occasion.blessing,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(color: Colors.white70).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.paddingOf(context).bottom + 32,
                child: Text(
                  'Tap to continue',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small(color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowingCrescent extends StatelessWidget {
  final double size;

  const _GlowingCrescent({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _CrescentPainter());
  }
}

class _CrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s * 0.5, s * 0.5);
    canvas.drawCircle(
      c,
      s * 0.62,
      Paint()
        ..color = const Color(0xFFFFE7A8).withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.18),
    );
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.4)),
      Path()..addOval(Rect.fromCircle(center: c + Offset(s * 0.18, -s * 0.14), radius: s * 0.34)),
    );
    canvas.drawPath(
      moon,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4D6), Color(0xFFE9B95A)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _CrescentPainter old) => false;
}
