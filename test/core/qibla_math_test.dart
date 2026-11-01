import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/utils/qibla_math.dart';

void main() {
  group('distanceToKaabaKm', () {
    test('matches known great-circle distances', () {
      expect(QiblaMath.distanceToKaabaKm(23.8103, 90.4125), closeTo(5170, 30)); // Dhaka
      expect(QiblaMath.distanceToKaabaKm(51.5074, -0.1278), closeTo(4790, 60)); // London
      expect(QiblaMath.distanceToKaabaKm(-33.8688, 151.2093), closeTo(13140, 120)); // Sydney
      expect(QiblaMath.distanceToKaabaKm(21.4225, 39.8262), closeTo(0, 0.001));
    });

    test('works from the far side of the world', () {
      final antipode = QiblaMath.distanceToKaabaKm(-21.4225, 39.8262 - 180);
      expect(antipode, closeTo(20015, 5));
    });
  });

  group('turn', () {
    test('is signed and takes the short way round', () {
      expect(QiblaMath.turn(0, 90), 90);
      expect(QiblaMath.turn(90, 0), -90);
      expect(QiblaMath.turn(350, 10), 20);
      expect(QiblaMath.turn(10, 350), -20);
      expect(QiblaMath.turn(277, 277), 0);
      expect(QiblaMath.turn(0, 180).abs(), 180);
      expect(QiblaMath.turn(-30, 30), 60);
      expect(QiblaMath.turn(720, 10), 10);
    });
  });

  group('QiblaLock', () {
    test('locks within 3 degrees and releases only past 6', () {
      final lock = QiblaLock();
      expect(lock.update(10), isFalse);
      expect(lock.update(4), isFalse);
      expect(lock.update(2.9), isTrue);
      // Wavering around the lock boundary keeps it locked.
      expect(lock.update(4), isTrue);
      expect(lock.update(-5.9), isTrue);
      expect(lock.update(6.1), isFalse);
      expect(lock.update(5), isFalse);
      expect(lock.update(-3), isTrue);
    });
  });
}
