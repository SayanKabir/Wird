import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/features/home/widgets/live_sky.dart';

void main() {
  // Dhaka, a waning crescent week: the moon is up through the morning.
  LiveSky dhaka(DateTime utc) => LiveSky.at(utc, 23.8103, 90.4125);

  group('the moon by day', () {
    test('is only a faint trace once the sun is bright', () {
      final noon = dhaka(DateTime.utc(2026, 11, 6, 6));
      expect(noon.sunAltitude, greaterThan(15));
      expect(noon.moonOpacity, closeTo(0.12, 0.01));
    });

    test('is whole at night', () {
      final midnight = dhaka(DateTime.utc(2026, 11, 5, 18));
      expect(midnight.sunAltitude, lessThan(-6));
      expect(midnight.moonOpacity, 1);
    });

    test('fades as the sun climbs, still clear at sunrise', () {
      var last = 1.0;
      for (var m = 0; m <= 180; m += 10) {
        // From before dawn to mid-morning, 5:00 to 8:00 local.
        final o = dhaka(DateTime.utc(2026, 11, 5, 23).add(Duration(minutes: m))).moonOpacity;
        expect(o, lessThanOrEqualTo(last));
        last = o;
      }
      final sunrise = dhaka(DateTime.utc(2026, 11, 6, 0, 10));
      expect(sunrise.sunAltitude.abs(), lessThan(3));
      expect(sunrise.moonOpacity, greaterThan(0.5));
    });
  });
}
