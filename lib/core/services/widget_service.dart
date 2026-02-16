import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:wird2/models/prayer.dart';
import 'package:wird2/core/services/prayer_service.dart';
import 'package:wird2/core/services/weather_service.dart';

class WidgetService {
  static const String _androidWidgetName = 'WirdWidgetProvider';
  // Note: qualifiedAndroidName needs to match the package + class name
  static const String _androidPackageName = 'com.SayanKabir.wird2.WirdWidgetProvider';

  /// Updates the widget with the latest prayer and weather data.
  Future<void> updateWidgetData({
    required Map<Prayer, PrayerTimeData> prayerTimes,
    required Prayer nextPrayer,
    required Prayer? currentPrayer,
    required Set<Prayer> completedPrayers,
    required WeatherData? weatherData,
  }) async {
    // Logic:
    // 1. If we are in a prayer window AND it's not completed: Show NOW
    // 2. Otherwise: Show UP NEXT
    
    // Default: Show Next
    String headerText = "UP NEXT";
    String mainName = nextPrayer.name.toUpperCase();
    String mainTime = DateFormat('h:mm a').format(prayerTimes[nextPrayer]!.startTime);
    String secondaryText = ""; // Empty implies no secondary info needed or handled differently

    // Check if we should show "NOW"
    // Conditions:
    // - currentPrayer is not null (we are in a window)
    // - currentPrayer is NOT in completedPrayers (user hasn't prayed yet)
    // - currentPrayer is NOT 'none' or 'duha' (strictly 5 fard? or all?)
    // User said "Show now prayer if not completed". Let's apply to all tracked prayers.
    
    if (currentPrayer != null && !completedPrayers.contains(currentPrayer)) {
       // We are in an active prayer window and haven't prayed yet.
       headerText = "NOW";
       mainName = currentPrayer.name.toUpperCase();
       mainTime = DateFormat('h:mm a').format(prayerTimes[currentPrayer]!.startTime);
       
       // Secondary: Show Next Prayer
       final nextName = nextPrayer.name;
       final nextTime = DateFormat('h:mm').format(prayerTimes[nextPrayer]!.startTime);
       secondaryText = "Next: $nextName $nextTime";
    }

    // 1. Save Data (Shared)
    await HomeWidget.saveWidgetData<String>('widget_header', headerText);
    await HomeWidget.saveWidgetData<String>('widget_main_name', mainName);
    await HomeWidget.saveWidgetData<String>('widget_main_time', mainTime);
    await HomeWidget.saveWidgetData<String>('widget_secondary', secondaryText);
    
    // Save Period for Period Background & List Widget Highlight
    // Determine active period for highlighting in list widget
    // Logic: Highlight if current == period.
    // If current is null, might be after isha or before fajr?
    // Let's use `currentPrayer?.name` lowercased.
    String activePrayerName = currentPrayer?.name ?? 'isha';
    // Special case: if next is Fajr and current is null (late night), maybe highlight Fajr (next) or Isha (last)? 
    // Let's stick to current. If null, maybe highlight nothing or Isha?
    // Actually `currentPrayer` includes Isha until Fajr starts if we logic correctly.
    // If our logic returns null for current, it means we are in "None" window?
    // Standard library returns "none" or "isha".
    
    await HomeWidget.saveWidgetData<String>('prayer_period', activePrayerName.toLowerCase());

    // Save All Prayer Times for List Widget
    final DateFormat timeFormat = DateFormat('h:mm a');
    
    // Helper to safe get time
    String formatTime(Prayer p) => timeFormat.format(prayerTimes[p]!.startTime);
    
    await HomeWidget.saveWidgetData<String>('time_fajr', formatTime(Prayer.fajr));
    
    // Sunrise: Use Fajr end time which corresponds to Sunrise
    final sunriseTime = prayerTimes[Prayer.fajr]?.endTime;
    if (sunriseTime != null) {
       await HomeWidget.saveWidgetData<String>('time_sunrise', timeFormat.format(sunriseTime));
    }
    
    await HomeWidget.saveWidgetData<String>('time_dhuhr', formatTime(Prayer.dhuhr));
    await HomeWidget.saveWidgetData<String>('time_asr', formatTime(Prayer.asr));
    await HomeWidget.saveWidgetData<String>('time_maghrib', formatTime(Prayer.maghrib));
    await HomeWidget.saveWidgetData<String>('time_isha', formatTime(Prayer.isha));
    

    // 2. Save Weather Data (Shared)
    if (weatherData != null) {
      final temp = '${weatherData.temperature.round()}°';
      await HomeWidget.saveWidgetData<String>('weather_temp', temp);
    } else {
       await HomeWidget.saveWidgetData<String>('weather_temp', '--');
    }

    // 3. Trigger Widget Updates
    // Small Widget
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      iOSName: 'WirdWidget',
      qualifiedAndroidName: _androidPackageName,
    );
    
    // Large List Widget
    await HomeWidget.updateWidget(
      name: 'WirdListWidgetProvider',
      iOSName: 'WirdListWidget', // Placeholder
      qualifiedAndroidName: 'com.SayanKabir.wird2.WirdListWidgetProvider',
    );
  }
}
