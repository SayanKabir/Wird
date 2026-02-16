import 'package:adhan/adhan.dart' as adhan;
import '../../models/prayer.dart';
import '../../models/settings.dart';
import '../utils/date_utils.dart';

/// Prayer time calculation data for a single prayer
class PrayerTimeData {
  final Prayer prayer;
  final DateTime startTime;
  final DateTime endTime;

  const PrayerTimeData({
    required this.prayer,
    required this.startTime,
    required this.endTime,
  });


  /// [FIX] This getter was missing, causing the error in PrayerCard
  Duration get duration => endTime.difference(startTime);

  /// Check if the given time is within this prayer's window
  bool isWithinWindow(DateTime time) {
    return time.isAfter(startTime) && time.isBefore(endTime) ||
           time.isAtSameMomentAs(startTime);
  }

  /// Get remaining time until prayer ends
  Duration getRemainingTime(DateTime now) {
    if (now.isBefore(startTime)) {
      return startTime.difference(now);
    } else if (now.isBefore(endTime)) {
      return endTime.difference(now);
    }
    return Duration.zero;
  }

  /// Get time until prayer starts
  Duration getTimeUntilStart(DateTime now) {
    if (now.isBefore(startTime)) {
      return startTime.difference(now);
    }
    return Duration.zero;
  }
}

/// Service for calculating prayer times using the adhan package
class PrayerService {
  /// Singleton instance
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal();

  /// Calculate prayer times for a specific date and location
  Map<Prayer, PrayerTimeData> calculatePrayerTimes({
    required DateTime date,
    required LocationData location,
    required CalculationMethodType calculationMethod,
    required MadhabType madhab,
    required bool includeTahajjud,
    required bool includeIshraq,
    required bool includeDuha,
  }) {
    final coords = location.toCoordinates();
    final params = _getCalculationParameters(calculationMethod, madhab);
    
    // Get prayer times for the date
    final dateComponents = adhan.DateComponents.from(date);
    final prayerTimes = adhan.PrayerTimes(coords, dateComponents, params);
    
    // Get sunrise and sunset for additional calculations
    final sunTimes = adhan.SunnahTimes(prayerTimes);
    
    // Get tomorrow's Fajr for Isha end time
    final tomorrowDate = date.add(const Duration(days: 1));
    final tomorrowComponents = adhan.DateComponents.from(tomorrowDate);
    final tomorrowPrayers = adhan.PrayerTimes(coords, tomorrowComponents, params);
    
    final result = <Prayer, PrayerTimeData>{};
    
    // Fajr: Starts at Fajr adhan, ends at sunrise
    result[Prayer.fajr] = PrayerTimeData(
      prayer: Prayer.fajr,
      startTime: prayerTimes.fajr,
      endTime: prayerTimes.sunrise,
    );
    
    // Dhuhr: Starts at Dhuhr adhan, ends at Asr adhan
    result[Prayer.dhuhr] = PrayerTimeData(
      prayer: Prayer.dhuhr,
      startTime: prayerTimes.dhuhr,
      endTime: prayerTimes.asr,
    );
    
    // Asr: Starts at Asr adhan, ends at Maghrib adhan
    result[Prayer.asr] = PrayerTimeData(
      prayer: Prayer.asr,
      startTime: prayerTimes.asr,
      endTime: prayerTimes.maghrib,
    );
    
    // Maghrib: Starts at Maghrib adhan, ends at Isha adhan
    result[Prayer.maghrib] = PrayerTimeData(
      prayer: Prayer.maghrib,
      startTime: prayerTimes.maghrib,
      endTime: prayerTimes.isha,
    );
    
    // Isha: Starts at Isha adhan, ends at Islamic midnight
    final islamicMidnight = AppDateUtils.calculateIslamicMidnight(
      prayerTimes.maghrib,
      tomorrowPrayers.fajr,
    );
    result[Prayer.isha] = PrayerTimeData(
      prayer: Prayer.isha,
      startTime: prayerTimes.isha,
      endTime: islamicMidnight,
    );
    
    // Optional Sunnah prayers
    if (includeTahajjud) {
      // Tahajjud: Last third of night until Fajr
      final lastThird = AppDateUtils.calculateLastThirdOfNight(
        prayerTimes.isha,
        tomorrowPrayers.fajr,
      );
      result[Prayer.tahajjud] = PrayerTimeData(
        prayer: Prayer.tahajjud,
        startTime: lastThird,
        endTime: tomorrowPrayers.fajr,
      );
    }
    
    if (includeIshraq) {
      // Ishraq: 15 minutes after sunrise for 30 minutes
      // Distinct window: Sunrise+15 -> Sunrise+45
      result[Prayer.ishraq] = PrayerTimeData(
        prayer: Prayer.ishraq,
        startTime: prayerTimes.sunrise.add(const Duration(minutes: 15)),
        endTime: prayerTimes.sunrise.add(const Duration(minutes: 45)),
      );
    }
    
    if (includeDuha) {
      // Duha: Starts after Ishraq ends until 15 min before Dhuhr
      // Distinct window: Sunrise+45 -> Dhuhr-15
      final duhaStart = prayerTimes.sunrise.add(const Duration(minutes: 45));
      result[Prayer.duha] = PrayerTimeData(
        prayer: Prayer.duha,
        startTime: duhaStart,
        endTime: prayerTimes.dhuhr.subtract(const Duration(minutes: 15)),
      );
    }
    
    return result;
  }

  /// Get calculation parameters from settings
  adhan.CalculationParameters _getCalculationParameters(
    CalculationMethodType method,
    MadhabType madhab,
  ) {
    final params = method.toAdhanMethod().getParameters();
    params.madhab = madhab.toAdhanMadhab();
    return params;
  }

  /// Get the current prayer based on time
  Prayer? getCurrentPrayer(
    Map<Prayer, PrayerTimeData> prayerTimes,
    DateTime now,
  ) {
    // Check prayers in order of the day
    final orderedPrayers = [
      Prayer.tahajjud,
      Prayer.fajr,
      Prayer.ishraq,
      Prayer.duha,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (final prayer in orderedPrayers) {
      final timeData = prayerTimes[prayer];
      if (timeData != null && timeData.isWithinWindow(now)) {
        return prayer;
      }
    }

    return null;
  }

  /// Get the next upcoming prayer
  Prayer? getNextPrayer(
    Map<Prayer, PrayerTimeData> prayerTimes,
    DateTime now,
  ) {
    final orderedPrayers = [
      Prayer.fajr,
      Prayer.ishraq,
      Prayer.duha,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
      Prayer.tahajjud,
    ];

    PrayerTimeData? nextPrayerData;
    Prayer? nextPrayer;

    for (final prayer in orderedPrayers) {
      final timeData = prayerTimes[prayer];
      if (timeData != null && timeData.startTime.isAfter(now)) {
        if (nextPrayerData == null || 
            timeData.startTime.isBefore(nextPrayerData.startTime)) {
          nextPrayerData = timeData;
          nextPrayer = prayer;
        }
      }
    }

    // If no prayer found today, return the first prayer of the day (will be tomorrow)
    // This allows showing "Up next: Tahajjud" when all today's prayers are done
    if (nextPrayer == null) {
      // Return first enabled prayer in order (typically Tahajjud or Fajr)
      for (final prayer in orderedPrayers) {
        if (prayerTimes.containsKey(prayer)) {
          return prayer;
        }
      }
    }

    return nextPrayer;
  }
  
  /// Get countdown to next prayer, including next day if needed
  Duration getCountdownToNextPrayer(
    Map<Prayer, PrayerTimeData> prayerTimes,
    DateTime now,
    Prayer nextPrayer,
  ) {
    final timeData = prayerTimes[nextPrayer];
    if (timeData == null) return Duration.zero;
    
    // If the prayer time has already passed today, calculate time until tomorrow
    if (timeData.startTime.isBefore(now)) {
      // Calculate tomorrow's prayer time
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final tomorrowStart = DateTime(
        tomorrow.year, 
        tomorrow.month, 
        tomorrow.day,
        timeData.startTime.hour,
        timeData.startTime.minute,
      );
      return tomorrowStart.difference(now);
    }
    
    return timeData.startTime.difference(now);
  }

  /// Get countdown duration to next event (prayer start or end)
  Duration getCountdownDuration(
    Map<Prayer, PrayerTimeData> prayerTimes,
    DateTime now,
  ) {
    final currentPrayer = getCurrentPrayer(prayerTimes, now);
    
    if (currentPrayer != null) {
      // Show countdown to prayer end
      final timeData = prayerTimes[currentPrayer];
      if (timeData != null) {
        return timeData.endTime.difference(now);
      }
    }
    
    // Show countdown to next prayer start
    final nextPrayer = getNextPrayer(prayerTimes, now);
    if (nextPrayer != null) {
      final timeData = prayerTimes[nextPrayer];
      if (timeData != null) {
        return timeData.startTime.difference(now);
      }
    }
    
    return Duration.zero;
  }

  /// Check if it's Friday (for Jumuah)
  bool isFriday(DateTime date) {
    return date.weekday == DateTime.friday;
  }

  /// Get display name for prayer (handles Jumuah on Friday)
  String getPrayerDisplayName(Prayer prayer, DateTime date) {
    return prayer.displayNameForDay(date);
  }

  /// Get Qibla direction from coordinates
  double getQiblaDirection(LocationData location) {
    final coords = location.toCoordinates();
    final qibla = adhan.Qibla(coords);
    return qibla.direction;
  }

  /// Get current prayer period for gradient selection
  PrayerPeriod getCurrentPrayerPeriod(
    Map<Prayer, PrayerTimeData> prayerTimes,
    DateTime now,
  ) {
    final fajr = prayerTimes[Prayer.fajr];
    final dhuhr = prayerTimes[Prayer.dhuhr];
    final asr = prayerTimes[Prayer.asr];
    final maghrib = prayerTimes[Prayer.maghrib];
    final isha = prayerTimes[Prayer.isha];
    final tahajjud = prayerTimes[Prayer.tahajjud];

    // Check if we're in Tahajjud period (before Fajr)
    if (tahajjud != null && now.isAfter(tahajjud.startTime) && now.isBefore(tahajjud.endTime)) {
      return PrayerPeriod.tahajjud;
    }

    if (fajr != null && now.isAfter(fajr.startTime) && now.isBefore(fajr.endTime)) {
      return PrayerPeriod.fajr;
    }

    // Between sunrise and Dhuhr
    if (fajr != null && dhuhr != null && 
        now.isAfter(fajr.endTime) && now.isBefore(dhuhr.startTime)) {
      return PrayerPeriod.sunrise;
    }

    if (dhuhr != null && now.isAfter(dhuhr.startTime) && now.isBefore(dhuhr.endTime)) {
      return PrayerPeriod.dhuhr;
    }

    if (asr != null && now.isAfter(asr.startTime) && now.isBefore(asr.endTime)) {
      return PrayerPeriod.asr;
    }

    if (maghrib != null && now.isAfter(maghrib.startTime) && now.isBefore(maghrib.endTime)) {
      return PrayerPeriod.maghrib;
    }

    if (isha != null && now.isAfter(isha.startTime)) {
      return PrayerPeriod.isha;
    }

    // Default to Isha (night)
    return PrayerPeriod.isha;
  }
}

/// Prayer period enum for UI gradient selection
enum PrayerPeriod {
  tahajjud,
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}
