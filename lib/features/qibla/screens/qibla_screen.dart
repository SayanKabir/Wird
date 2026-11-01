import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/device_profile.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/qibla_math.dart';
import '../../../models/settings.dart';
import '../../../widgets/common/page_header.dart';
import '../../../widgets/common/wird_icons.dart';

/// Qibla finder. The dial turns with the phone; the Kaaba rides outside the
/// ring at the Qibla's true bearing, joined to it by a short stem, and a gold
/// arc runs from the "you are facing" notch at the top to it. Turning until the
/// arc closes and the Kaaba reaches the notch faces the Qibla.
class QiblaScreen extends StatefulWidget {
  /// Replaces the device compass in tests.
  @visibleForTesting
  final Stream<CompassEvent>? compassEvents;

  const QiblaScreen({super.key, this.compassEvents});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final LocationService _locationService = LocationService();

  StreamSubscription<CompassEvent>? _compassSubscription;
  ValueListenable<Box<AppSettings>>? _settingsListenable;

  LocationData? _location;
  double _qibla = 0;

  bool _hasCompass = true;
  bool _hasReading = false;

  /// Android reports 15 / 30 / 45 for high / medium / low; iOS reports the
  /// error in degrees. Only a low reading asks for calibration: the needle
  /// keeps moving either way (it used to freeze on medium, which some phones
  /// sit at all day).
  bool _needsCalibration = false;

  final QiblaLock _lock = QiblaLock();
  bool _aligned = false;

  bool _locating = false;
  String? _locationError;
  bool _locationServiceOff = false;

  /// Eases the dial between compass samples.
  late final AnimationController _smooth =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  Animation<double> _heading = const AlwaysStoppedAnimation(0);

  /// Slow float and glow on the Kaaba.
  late final AnimationController _ambient =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

  /// Gold-to-green as the phone locks on.
  late final AnimationController _alignment =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 360));

  /// One swell of the Kaaba's glow when it locks on.
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    _readLocation();
    if (_storage.isInitialized) {
      _settingsListenable = _storage.getSettingsListenable()..addListener(_readLocation);
    }
    if (!motionStill()) _ambient.repeat();
    _startCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _settingsListenable?.removeListener(_readLocation);
    _smooth.dispose();
    _ambient.dispose();
    _alignment.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _readLocation() {
    final location = _storage.getSettings().location;
    final valid = location != null && location.isValid ? location : null;
    if (!mounted) return;
    setState(() {
      _location = valid;
      if (valid != null) _qibla = PrayerService().getQiblaDirection(valid);
    });
  }

  void _startCompass() {
    final events = widget.compassEvents ?? FlutterCompass.events;
    if (events == null) {
      _hasCompass = false;
      return;
    }
    _compassSubscription = events.listen(_onCompass, onError: (_) {
      if (mounted) setState(() => _hasCompass = false);
    });
  }

  void _onCompass(CompassEvent event) {
    final heading = event.heading;
    if (heading == null || !mounted) return;

    // Shortest way round from wherever the dial is drawn right now, so a
    // sample that lands mid-animation doesn't jump.
    final from = _heading.value;
    var diff = (heading - from) % 360;
    if (diff > 180) diff -= 360;
    _heading = Tween<double>(begin: from, end: from + diff)
        .animate(CurvedAnimation(parent: _smooth, curve: Curves.easeOut));
    _smooth.forward(from: 0);

    final accuracy = event.accuracy;
    final aligned = _lock.update(QiblaMath.turn(heading, _qibla));
    if (aligned != _aligned) {
      _aligned = aligned;
      _alignment.animateTo(aligned ? 1 : 0);
      if (aligned) {
        HapticService().selection();
        if (!motionStill()) _burst.forward(from: 0);
      }
    }
    final needsCalibration = accuracy != null && accuracy >= 40;
    if (!_hasReading || needsCalibration != _needsCalibration) {
      setState(() {
        _hasReading = true;
        _needsCalibration = needsCalibration;
      });
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
      _locationServiceOff = false;
    });
    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    if (result.data != null) {
      await _locationService.saveLocation(result.data!);
      _readLocation();
    }
    if (!mounted) return;
    setState(() {
      _locating = false;
      _locationError = result.data == null ? (result.error ?? "Couldn't find your location. Try again.") : null;
      _locationServiceOff = result.serviceDisabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            // Leaves room for the floating tab bar.
            final bottomGap = math.max(96.0, height * 0.13);
            final dial = math.min(width - AppSpacing.gutter(context) * 2, height * 0.6).clamp(220.0, 440.0);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: AppSpacing.header(context).copyWith(bottom: 8),
                        child: const PageHeader(overline: 'FIND QIBLA', title: 'Qibla'),
                      ),
                    ),
                    if (_location != null) _RouteLine(location: _location!, qibla: _qibla),
                    SizedBox(height: height * 0.03),
                    if (_location == null)
                      _NoLocation(
                        locating: _locating,
                        error: _locationError,
                        serviceOff: _locationServiceOff,
                        onUseLocation: _useMyLocation,
                        onOpenSettings: _locationService.openLocationSettings,
                      )
                    else if (!_hasCompass)
                      _NoCompass(qibla: _qibla)
                    else ...[
                      AnimatedBuilder(
                        animation: Listenable.merge([_smooth, _ambient, _alignment, _burst]),
                        builder: (context, _) => _QiblaDial(
                          size: dial,
                          heading: _heading.value,
                          qibla: _qibla,
                          hasReading: _hasReading,
                          aligned: _aligned,
                          alignment: Curves.easeOut.transform(_alignment.value),
                          float: motionStill() ? 0 : math.sin(_ambient.value * 2 * math.pi),
                          burst: _burst.value,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _needsCalibration
                            ? _CalibrationCard(key: const ValueKey('calibrate'), animation: _ambient)
                            : AnimatedBuilder(
                                key: const ValueKey('status'),
                                animation: _smooth,
                                builder: (context, _) => _HeadingLine(heading: _heading.value, qibla: _qibla),
                              ),
                      ),
                    ],
                    SizedBox(height: bottomGap),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────────

/// "Dhaka · 5,170 km to Makkah", under the title.
class _RouteLine extends StatelessWidget {
  final LocationData location;
  final double qibla;

  const _RouteLine({required this.location, required this.qibla});

  @override
  Widget build(BuildContext context) {
    final km = QiblaMath.distanceToKaabaKm(location.latitude, location.longitude);
    final distance = km < 1 ? 'at the Kaaba' : '${_thousands(km.round())} km to Makkah';
    final place = location.city ?? location.displayName;
    final muted = Colors.white.withValues(alpha: 0.6);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter(context)),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, size: 15, color: AppColors.kaabaGold.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$place · $distance',
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

String _thousands(int n) {
  final s = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// The compass itself: dial, arc, stem, the Kaaba, and the turn readout in
/// the middle.
class _QiblaDial extends StatelessWidget {
  final double size;
  final double heading;
  final double qibla;
  final bool hasReading;
  final bool aligned;

  /// 0 = searching, 1 = facing the Qibla; eases the colour between the two.
  final double alignment;

  /// -1..1 phase of the Kaaba's float.
  final double float;

  /// 0..1 progress of the lock-on swell.
  final double burst;

  const _QiblaDial({
    required this.size,
    required this.heading,
    required this.qibla,
    required this.hasReading,
    required this.aligned,
    required this.alignment,
    required this.float,
    required this.burst,
  });

  static double ringRadius(double size) => size * 0.355;
  static double kaabaRadius(double size) => size * 0.455;
  static double kaabaSize(double size) => size * 0.12;

  @override
  Widget build(BuildContext context) {
    final turn = QiblaMath.turn(heading, qibla);
    final accent = Color.lerp(AppColors.kaabaGold, AppColors.qiblaAligned, alignment)!;
    final angle = turn * math.pi / 180;
    final kSize = kaabaSize(size);
    final kaabaCenter = Offset(size / 2, size / 2) +
        Offset(math.sin(angle), -math.cos(angle)) * kaabaRadius(size) +
        Offset(0, -float * size * 0.008);

    return Semantics(
      label: !hasReading
          ? 'Finding direction'
          : aligned
              ? 'Facing the Qibla'
              : 'Turn ${turn > 0 ? 'right' : 'left'} ${turn.abs().round()} degrees',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _DialPainter(
                heading: heading,
                turn: turn,
                accent: accent,
                alignment: alignment,
                kaabaCenter: kaabaCenter,
                kaabaSize: kSize,
                float: float,
                burst: burst,
                showGuide: hasReading,
              ),
            ),
            if (hasReading)
              Positioned(
                left: kaabaCenter.dx - kSize / 2,
                top: kaabaCenter.dy - kSize / 2,
                child: KaabaIcon(size: kSize),
              ),
            Positioned.fill(
              child: Center(child: _TurnReadout(size: size, turn: turn, hasReading: hasReading, aligned: aligned)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "35°  Turn right" in the middle of the dial, or "Facing the Qibla".
class _TurnReadout extends StatelessWidget {
  final double size;
  final double turn;
  final bool hasReading;
  final bool aligned;

  const _TurnReadout({required this.size, required this.turn, required this.hasReading, required this.aligned});

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.6);
    if (!hasReading) {
      return Text('Finding direction…', style: AppTextStyles.small(color: muted));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: aligned
          ? Column(
              key: const ValueKey('aligned'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, size: size * 0.1, color: AppColors.qiblaAligned),
                const SizedBox(height: 4),
                Text('Facing the Qibla', style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w500)),
              ],
            )
          : Column(
              key: const ValueKey('turn'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${turn.abs().round()}°',
                  style: AppTextStyles.tabular(
                    AppTextStyles.counter(color: Colors.white, size: size * 0.15).copyWith(height: 1),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  turn > 0 ? 'Turn right' : 'Turn left',
                  style: AppTextStyles.small(color: AppColors.kaabaGold, weight: FontWeight.w500),
                ),
              ],
            ),
    );
  }
}

/// "Heading 247° · Qibla 277° W": the raw numbers, for checking against
/// another compass.
class _HeadingLine extends StatelessWidget {
  final double heading;
  final double qibla;

  const _HeadingLine({required this.heading, required this.qibla});

  @override
  Widget build(BuildContext context) {
    final h = ((heading % 360) + 360) % 360;
    return Text(
      'Heading ${h.round() % 360}° · Qibla ${AppFormatters.formatBearing(qibla)}',
      style: AppTextStyles.tabular(AppTextStyles.small(color: Colors.white.withValues(alpha: 0.5))),
    );
  }
}

class _CalibrationCard extends StatelessWidget {
  final Animation<double> animation;

  const _CalibrationCard({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.gutter(context)),
      padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kaabaGold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 36,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => CustomPaint(
                painter: _FigureEightPainter(progress: motionStill() ? 0.15 : animation.value),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calibrate your compass',
                    style: AppTextStyles.body(color: Colors.white, weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  'Move your phone in a figure 8 a few times, away from metal and magnets.',
                  style: AppTextStyles.small(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoLocation extends StatelessWidget {
  final bool locating;
  final String? error;
  final bool serviceOff;
  final VoidCallback onUseLocation;
  final VoidCallback onOpenSettings;

  const _NoLocation({
    required this.locating,
    required this.error,
    required this.serviceOff,
    required this.onUseLocation,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter(context) * 1.5, vertical: 32),
      child: Column(
        children: [
          const KaabaIcon(size: 64),
          const SizedBox(height: 20),
          Text('Set your location', style: AppTextStyles.h3(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'The Qibla is worked out from where you are, so Wird needs your location first.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: locating ? null : onUseLocation,
            icon: locating
                ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(locating ? 'Finding you…' : 'Use my location'),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(error!, textAlign: TextAlign.center, style: AppTextStyles.small(color: AppColors.statusMissed)),
            if (serviceOff)
              TextButton(onPressed: onOpenSettings, child: const Text('Open location settings')),
          ],
        ],
      ),
    );
  }
}

class _NoCompass extends StatelessWidget {
  final double qibla;

  const _NoCompass({required this.qibla});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter(context) * 1.5, vertical: 32),
      child: Column(
        children: [
          Icon(Icons.explore_off_rounded, size: 52, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(height: 18),
          Text('This phone has no compass', style: AppTextStyles.h3(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'The Qibla is ${AppFormatters.formatBearing(qibla)} from north. '
            'A separate compass will point you to it.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────

class _DialPainter extends CustomPainter {
  final double heading;
  final double turn;
  final Color accent;
  final double alignment;
  final Offset kaabaCenter;
  final double kaabaSize;
  final double float;
  final double burst;
  final bool showGuide;

  _DialPainter({
    required this.heading,
    required this.turn,
    required this.accent,
    required this.alignment,
    required this.kaabaCenter,
    required this.kaabaSize,
    required this.float,
    required this.burst,
    required this.showGuide,
  });

  static Offset _at(Offset c, double r, double degrees) {
    final a = degrees * math.pi / 180;
    return c + Offset(math.sin(a), -math.cos(a)) * r;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final ring = _QiblaDial.ringRadius(size.width);
    final s = size.width;

    // Face.
    canvas.drawCircle(c, ring, Paint()..color = Colors.white.withValues(alpha: 0.035));
    canvas.drawCircle(
      c,
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.14),
    );

    // Ticks turn with the phone; every 30° is longer.
    final minor = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final major = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var d = 0; d < 360; d += 5) {
      final isMajor = d % 30 == 0;
      final len = isMajor ? s * 0.035 : s * 0.018;
      final a = d - heading;
      canvas.drawLine(_at(c, ring - 3, a), _at(c, ring - 3 - len, a), isMajor ? major : minor);
    }

    // Cardinal letters sit on the turning dial but stay upright.
    final tp = TextPainter(textDirection: TextDirection.ltr);
    const names = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final isNorth = i == 0;
      tp.text = TextSpan(
        text: names[i],
        style: AppTextStyles.body(weight: FontWeight.w600).copyWith(
          shadows: const [],
          fontSize: isNorth ? s * 0.052 : s * 0.042,
          color: isNorth ? AppColors.statusMissed : Colors.white.withValues(alpha: 0.75),
        ),
      );
      tp.layout();
      final p = _at(c, ring - s * 0.085, i * 90 - heading);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    // "You are facing" notch, fixed at the top just outside the ring.
    final notch = Path()
      ..moveTo(c.dx, c.dy - ring - 4)
      ..lineTo(c.dx - s * 0.018, c.dy - ring - 4 - s * 0.03)
      ..lineTo(c.dx + s * 0.018, c.dy - ring - 4 - s * 0.03)
      ..close();
    canvas.drawPath(notch, Paint()..color = Color.lerp(Colors.white70, accent, alignment)!);

    if (!showGuide) return;

    // Arc from the notch to the Qibla: what's left to turn.
    if (turn.abs() > 0.5) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: ring),
        -math.pi / 2,
        turn * math.pi / 180,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.9),
      );
    }

    // Stem joining the ring to the Kaaba.
    final stemStart = _at(c, ring + 2, turn);
    final toKaaba = kaabaCenter - stemStart;
    final stemEnd = stemStart + toKaaba * (1 - (kaabaSize * 0.62) / toKaaba.distance.clamp(1, double.infinity));
    canvas.drawLine(
      stemStart,
      stemEnd,
      Paint()
        ..color = accent
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(stemStart, 3.2, Paint()..color = accent);

    // Glow behind the Kaaba: breathes slowly, swells once on lock-on.
    final swell = math.sin(burst * math.pi);
    final glowR = kaabaSize * (0.78 + 0.06 * float + 0.45 * swell);
    canvas.drawCircle(
      kaabaCenter,
      glowR,
      Paint()
        ..color = accent.withValues(alpha: 0.14 + 0.06 * float.abs() + 0.2 * swell + 0.08 * alignment)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, kaabaSize * 0.25),
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.heading != heading ||
      old.turn != turn ||
      old.accent != accent ||
      old.alignment != alignment ||
      old.kaabaCenter != kaabaCenter ||
      old.float != float ||
      old.burst != burst ||
      old.showGuide != showGuide;
}

/// A phone tracing a figure 8, for the calibration card.
class _FigureEightPainter extends CustomPainter {
  final double progress;

  _FigureEightPainter({required this.progress});

  Offset _point(Size size, double t) {
    final a = t * 2 * math.pi;
    return Offset(
      size.width / 2 + math.sin(a) * size.width * 0.42,
      size.height / 2 + math.sin(2 * a) * size.height * 0.32,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(_point(size, 0).dx, _point(size, 0).dy);
    for (var i = 1; i <= 64; i++) {
      final p = _point(size, i / 64);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.kaabaGold.withValues(alpha: 0.45),
    );
    final p = _point(size, progress);
    final phone = RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 9, height: 15), const Radius.circular(2.5));
    canvas.drawRRect(phone, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_FigureEightPainter old) => old.progress != progress;
}
