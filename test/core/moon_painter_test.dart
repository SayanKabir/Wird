import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/features/home/widgets/celestial_background.dart' show MoonPainter;

void main() {
  const center = Offset(100, 100);
  const radius = 100.0;

  /// Share of the disc inside the lit shape, and of it on the right half.
  (double lit, double rightShare) sample(double phase) {
    final path = MoonPainter.litPath(phase, center, radius);
    var inDisc = 0, inLit = 0, litRight = 0;
    for (var x = 0.5; x < 200; x += 2) {
      for (var y = 0.5; y < 200; y += 2) {
        final p = Offset(x, y);
        if ((p - center).distance > radius) continue;
        inDisc++;
        if (path.contains(p)) {
          inLit++;
          if (x > center.dx) litRight++;
        }
      }
    }
    return (inLit / inDisc, inLit == 0 ? 0 : litRight / inLit);
  }

  test('the lit share of the disc matches the moon\'s illumination at every phase', () {
    for (var i = 1; i < 40; i++) {
      final phase = i / 40;
      final illumination = (1 - math.cos(phase * 2 * math.pi)) / 2;
      final (lit, _) = sample(phase);
      expect(lit, closeTo(illumination, 0.03), reason: 'phase $phase');
    }
  });

  test('waxing moons are lit on the right, waning on the left', () {
    // Crescents and quarters sit wholly on their side.
    for (final phase in [0.05, 0.15, 0.25]) {
      expect(sample(phase).$2, greaterThan(0.95), reason: 'phase $phase');
    }
    for (final phase in [0.75, 0.85, 0.95]) {
      expect(sample(phase).$2, lessThan(0.05), reason: 'phase $phase');
    }
    // A gibbous moon reaches past the middle, but most of it is on its side.
    expect(sample(0.35).$2, greaterThan(0.6));
    expect(sample(0.65).$2, lessThan(0.4));
  });

  test('the quarters split the disc down the middle; new is dark, full is whole', () {
    expect(sample(0.25).$1, closeTo(0.5, 0.02));
    expect(sample(0.75).$1, closeTo(0.5, 0.02));
    expect(sample(0.0).$1, lessThan(0.01));
    expect(sample(0.5).$1, greaterThan(0.99));
  });
}
