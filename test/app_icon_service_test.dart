import 'package:flutter_test/flutter_test.dart';
import 'package:wird2/core/services/app_icon_service.dart';
import 'package:wird2/core/services/prayer_service.dart';
import 'package:wird2/models/prayer.dart';
import 'package:wird2/models/settings.dart';

void main() {
  const settings = AppSettings(
    location: LocationData(latitude: 51.5074, longitude: -0.1278, city: 'London'),
  );
  final day = DateTime(2026, 3, 10);
  final times = PrayerService().calculatePrayerTimes(
    date: day,
    location: settings.location!,
    calculationMethod: settings.calculationMethod,
    madhab: settings.madhab,
    includeTahajjud: false,
    includeIshraq: false,
    includeDuha: false,
  );
  DateTime start(Prayer p) => times[p]!.startTime;
  const minute = Duration(minutes: 1);

  test('the icon follows the prayer period through the day', () {
    expect(AppIconService.iconFor(settings, start(Prayer.fajr).subtract(minute)), AppIconChoice.isha);
    expect(AppIconService.iconFor(settings, start(Prayer.fajr).add(minute)), AppIconChoice.fajr);
    // After sunrise the dawn icon stays until Dhuhr.
    expect(AppIconService.iconFor(settings, start(Prayer.dhuhr).subtract(minute)), AppIconChoice.fajr);
    expect(AppIconService.iconFor(settings, start(Prayer.dhuhr).add(minute)), AppIconChoice.dhuhr);
    expect(AppIconService.iconFor(settings, start(Prayer.asr).add(minute)), AppIconChoice.asr);
    expect(AppIconService.iconFor(settings, start(Prayer.maghrib).add(minute)), AppIconChoice.maghrib);
    expect(AppIconService.iconFor(settings, start(Prayer.isha).add(minute)), AppIconChoice.isha);
  });

  test('unknown stored keys fall back to following prayer times', () {
    expect(AppIconChoice.fromKey('isha'), AppIconChoice.isha);
    expect(AppIconChoice.fromKey('something-else'), AppIconChoice.auto);
  });
}
