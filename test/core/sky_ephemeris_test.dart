import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/utils/sky_ephemeris.dart';

void main() {
  group('sun', () {
    test('rises in the east at the equinox on the equator', () {
      // 2024-03-20, lat 0 / lng 0: sunrise is close to 06:05 UTC.
      final sky = SkyEphemeris.at(DateTime.utc(2024, 3, 20, 6, 5), 0, 0);
      expect(sky.sunAltitude, closeTo(0, 1.5));
      expect(sky.sunAzimuth, closeTo(90, 2));
      expect(sky.morning, isTrue);
    });

    test('stands due south at noon in London in midsummer', () {
      // 2024-06-21 13:02 BST = 12:02 UTC; peak altitude 90 - 51.5 + 23.4.
      final sky = SkyEphemeris.at(DateTime.utc(2024, 6, 21, 12, 2), 51.5, -0.13);
      expect(sky.sunAltitude, closeTo(61.9, 1));
      expect(sky.sunAzimuth, closeTo(180, 3));
      expect(sky.sunPeakAltitude, closeTo(61.9, 1));
    });

    test('sets in Dhaka at the published time', () {
      // 2024-10-26, Dhaka (23.81, 90.41): sunset 17:20 local = 11:20 UTC.
      final sky = SkyEphemeris.at(DateTime.utc(2024, 10, 26, 11, 20), 23.81, 90.41);
      expect(sky.sunAltitude, closeTo(-0.8, 1.2));
      expect(sky.sunAzimuth, closeTo(256, 3));
      expect(sky.morning, isFalse);
    });
  });

  group('moon', () {
    test('is full on 2024-04-23 23:49 UTC', () {
      final sky = SkyEphemeris.at(DateTime.utc(2024, 4, 23, 23, 49), 0, 0);
      expect(sky.moonPhase, closeTo(0.5, 0.01));
      expect(sky.moonIllumination, greaterThan(0.99));
    });

    test('is new on 2024-04-08 18:21 UTC', () {
      final sky = SkyEphemeris.at(DateTime.utc(2024, 4, 8, 18, 21), 0, 0);
      final fromNew = sky.moonPhase > 0.5 ? 1 - sky.moonPhase : sky.moonPhase;
      expect(fromNew, lessThan(0.01));
    });

    test('a full moon rises opposite the setting sun', () {
      // Around sunset on a full-moon day the moon is low in the east.
      final sky = SkyEphemeris.at(DateTime.utc(2024, 4, 23, 18, 0), 0, 0);
      expect(sky.sunAltitude, closeTo(0, 1.5));
      expect(sky.moonAltitude, closeTo(0, 8));
      expect(sky.moonAzimuth, closeTo(100, 15));
    });
  });
}
