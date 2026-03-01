import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/prayer_service.dart';

/// Qibla compass screen with Celestial Zen design
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with SingleTickerProviderStateMixin {
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _heading = 0;
  double _qiblaDirection = 0;
  bool _hasCompass = true;
  bool _isCalibrating = false;

  // Smoothing animation
  late AnimationController _smoothController;
  late Animation<double> _smoothHeading;

  // We track the visual heading separately to handle the 360-0 wrap correctly
  double _currentVisualHeading = 0;

  @override
  void initState() {
    super.initState();
    _initQibla();

    _smoothController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _smoothHeading = AlwaysStoppedAnimation(0);

    _startCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _smoothController.dispose();
    super.dispose();
  }

  void _initQibla() {
    final storageService = StorageService();
    final settings = storageService.getSettings();
    if (settings.location != null) {
      final prayerService = PrayerService();
      _qiblaDirection = prayerService.getQiblaDirection(settings.location!);
    }
  }

  void _startCompass() {
    FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        // 1. Check calibration status
        bool needsCal = false;
        if (event.accuracy != null) {
          final acc = event.accuracy!;
          // Android: -1 (Unreliable), 0 (Unreliable), 1 (Low) => Needs Cal
          // iOS: Degrees error. > 15 => Needs Cal
          needsCal = (acc == -1) || (acc < 2 && acc >= 0) || (acc > 15);
        }

        if (needsCal) {
          if (!_isCalibrating) setState(() => _isCalibrating = true);
          return; // PAUSE: Do not update heading logic
        }

        final double targetHeading = event.heading!;

        // --- Shortest Path Interpolation ---
        // Calculate the difference between where we are and where we want to be
        double diff = targetHeading - _currentVisualHeading;

        // Normalize the difference to -180...180 to find shortest path
        while (diff < -180) {
          diff += 360;
        }
        while (diff > 180) {
          diff -= 360;
        }

        final double endHeading = _currentVisualHeading + diff;

        setState(() {
          _isCalibrating = false;
          _heading = targetHeading;
        });

        // Animate from current visual state to the calculated end state
        _smoothHeading = Tween<double>(
            begin: _currentVisualHeading,
            end: endHeading
        ).animate(CurvedAnimation(parent: _smoothController, curve: Curves.easeOut));

        _currentVisualHeading = endHeading;
        _smoothController.forward(from: 0);
      }
    }, onError: (_) {
      if (mounted) setState(() => _hasCompass = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCompass) return _buildNoCompassView();

    // Calculate offset logic
    double offset = _qiblaDirection - _heading;
    if (offset < 0) offset += 360;
    if (offset > 180) offset -= 360;

    final isAligned = offset.abs() < 3; // Stricter alignment (3 degrees)

    if (isAligned) HapticFeedback.selectionClick();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            final double screenHeight = constraints.maxHeight;

            // Dynamically scale compass based on available screen space
            final double compassSize = math.min(screenWidth * 0.8, screenHeight * 0.45);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),

                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pass the dynamic size down
                            _buildCompassVisual(isAligned, compassSize),
                            if (_isCalibrating)
                              Positioned(
                                top: 20,
                                child: _buildCalibrationBadge(),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusFooter(isAligned, offset),
                      // Responsive bottom padding to avoid nav overlap
                      SizedBox(height: math.max(80, screenHeight * 0.15)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 0),
      child: Column(
        children: [
          Text(
            "FIND QIBLA",
            style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.5))
                .copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.spiritualGold),
              const SizedBox(width: 8),
              Text(
                "Mecca",
                style: AppTextStyles.h2(color: Colors.white).copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompassVisual(bool isAligned, double compassSize) {
    return AnimatedBuilder(
      animation: _smoothHeading,
      builder: (context, child) {
        // -_smoothHeading rotates the dial COUNTER-CLOCKWISE when heading increases.
        // This keeps "North" stationary relative to the world as the phone turns Right.
        return Transform.rotate(
          angle: -_smoothHeading.value * (math.pi / 180),
          child: SizedBox(
            width: compassSize,
            height: compassSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // A. Outer Tick Ring
                CustomPaint(
                  size: Size(compassSize, compassSize),
                  painter: _CompassTickPainter(),
                ),

                // B. Cardinal Directions (N, S, E, W) scaled down slightly
                CustomPaint(
                  size: Size(compassSize * 0.86, compassSize * 0.86),
                  painter: _CardinalPainter(),
                ),

                // C. The Qibla Pointer
                Transform.rotate(
                  angle: _qiblaDirection * (math.pi / 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        // Proportional margin pushes it up relative to screen size
                        margin: EdgeInsets.only(bottom: compassSize * 0.6),
                        child: Column(
                          children: [
                            Text(
                              '🕋',
                              style: TextStyle(
                                fontSize: compassSize * 0.15, // Scales with screen
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compassSize * 0.04),
                            Container(
                              width: 4,
                              height: compassSize * 0.13,
                              decoration: BoxDecoration(
                                color: isAligned ? AppColors.qiblaAligned : AppColors.spiritualGold,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAligned ? AppColors.qiblaAligned : AppColors.spiritualGold)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusFooter(bool isAligned, double offset) {
    String status = "Searching";
    Color color = Colors.white.withValues(alpha: 0.5);

    if (isAligned) {
      status = "ALIGNED";
      color = AppColors.qiblaAligned;
    } else if (offset > 0) {
      status = "TURN RIGHT";
      color = AppColors.statusLate;
    } else {
      status = "TURN LEFT";
      color = AppColors.statusLate;
    }

    return Column(
      children: [
        Text(
          "${_heading.round()}°",
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 64,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(status),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    isAligned ? Icons.check_circle : (offset > 0 ? Icons.turn_right : Icons.turn_left),
                    size: 16,
                    color: color
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: AppTextStyles.small(color: color).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalibrationBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.kaabaGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.statusMissed.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.screen_rotation_rounded, color: AppColors.statusMissed, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "SENSOR UNRELIABLE",
                    style: AppTextStyles.body(color: AppColors.statusMissed)
                        .copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Wave phone in figure-8",
                style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoCompassView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_off, size: 48, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text("Compass Unavailable", style: AppTextStyles.h3()),
        ],
      ),
    );
  }
}

// --- Painters ---

class _CompassTickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 2) {
      final isMajor = i % 10 == 0;
      final isCardinal = i % 90 == 0;
      if (isCardinal) continue;

      final angle = i * (math.pi / 180);
      // Tick length now scales with canvas size
      final double length = isMajor ? size.width * 0.04 : size.width * 0.02;

      final start = Offset(
        center.dx + (radius - length) * math.sin(angle),
        center.dy - (radius - length) * math.cos(angle),
      );
      final end = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );

      canvas.drawLine(start, end, isMajor ? majorTickPaint : tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardinalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final textPainter = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0.0, 90.0, 180.0, 270.0];

    final double padding = size.width * 0.05; // Dynamic padding from edge

    for (int i = 0; i < 4; i++) {
      final angle = angles[i] * (math.pi / 180);
      final isNorth = directions[i] == 'N';

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: isNorth ? size.width * 0.075 : size.width * 0.06, // Scales text seamlessly
          fontWeight: FontWeight.bold,
          color: isNorth ? AppColors.statusMissed : Colors.white.withValues(alpha: 0.9),
        ),
      );
      textPainter.layout();

      // Auto-centers the text exactly on the offset instead of guessing
      final textOffset = Offset(
        center.dx + (radius - padding) * math.sin(angle) - textPainter.width / 2,
        center.dy - (radius - padding) * math.cos(angle) - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}