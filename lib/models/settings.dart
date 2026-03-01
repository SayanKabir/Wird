import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:adhan/adhan.dart' as adhan;

part 'settings.g.dart';

/// User location data
@HiveType(typeId: 4)
class LocationData extends Equatable {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final String? city;

  @HiveField(3)
  final String? country;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
  });

  /// Convert to adhan Coordinates
  adhan.Coordinates toCoordinates() {
    return adhan.Coordinates(latitude, longitude);
  }

  /// Display string for location
  String get displayName {
    if (city != null && country != null) {
      return '$city, $country';
    } else if (city != null) {
      return city!;
    } else if (country != null) {
      return country!;
    } else {
      return '${latitude.toStringAsFixed(2)}°, ${longitude.toStringAsFixed(2)}°';
    }
  }

  /// Check if location is valid
  bool get isValid {
    return latitude >= -90 && latitude <= 90 &&
           longitude >= -180 && longitude <= 180 &&
           !(latitude == 0 && longitude == 0);
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, city, country];
}

/// Calculation method for prayer times
@HiveType(typeId: 5)
enum CalculationMethodType {
  @HiveField(0)
  muslimWorldLeague,

  @HiveField(1)
  isna,

  @HiveField(2)
  ummAlQura,

  @HiveField(3)
  egyptian,

  @HiveField(4)
  karachi,

  @HiveField(5)
  tehran,

  @HiveField(6)
  dubai,

  @HiveField(7)
  kuwait,

  @HiveField(8)
  qatar,

  @HiveField(9)
  singapore,

  @HiveField(10)
  other,
}

/// Weather Theme Preference
@HiveType(typeId: 10)
enum WeatherTheme {
  @HiveField(0)
  auto,

  @HiveField(1)
  clear,

  @HiveField(2)
  cloudy,

  @HiveField(3)
  rain,

  @HiveField(4)
  thunderstorm,

  @HiveField(5)
  snow,

  @HiveField(6)
  fog,
}

/// Extension methods for CalculationMethodType
extension CalculationMethodTypeExtension on CalculationMethodType {
  String get displayName {
    switch (this) {
      case CalculationMethodType.muslimWorldLeague:
        return 'Muslim World League';
      case CalculationMethodType.isna:
        return 'ISNA (North America)';
      case CalculationMethodType.ummAlQura:
        return 'Umm al-Qura (Saudi Arabia)';
      case CalculationMethodType.egyptian:
        return 'Egyptian General Authority';
      case CalculationMethodType.karachi:
        return 'University of Karachi';
      case CalculationMethodType.tehran:
        return 'Institute of Geophysics, Tehran';
      case CalculationMethodType.dubai:
        return 'Dubai';
      case CalculationMethodType.kuwait:
        return 'Kuwait';
      case CalculationMethodType.qatar:
        return 'Qatar';
      case CalculationMethodType.singapore:
        return 'Singapore';
      case CalculationMethodType.other:
        return 'Other';
    }
  }

  String get shortName {
    switch (this) {
      case CalculationMethodType.muslimWorldLeague:
        return 'MWL';
      case CalculationMethodType.isna:
        return 'ISNA';
      case CalculationMethodType.ummAlQura:
        return 'Umm al-Qura';
      case CalculationMethodType.egyptian:
        return 'Egyptian';
      case CalculationMethodType.karachi:
        return 'Karachi';
      case CalculationMethodType.tehran:
        return 'Tehran';
      case CalculationMethodType.dubai:
        return 'Dubai';
      case CalculationMethodType.kuwait:
        return 'Kuwait';
      case CalculationMethodType.qatar:
        return 'Qatar';
      case CalculationMethodType.singapore:
        return 'Singapore';
      case CalculationMethodType.other:
        return 'Other';
    }
  }

  /// Convert to adhan CalculationMethod
  adhan.CalculationMethod toAdhanMethod() {
    switch (this) {
      case CalculationMethodType.muslimWorldLeague:
        return adhan.CalculationMethod.muslim_world_league;
      case CalculationMethodType.isna:
        return adhan.CalculationMethod.north_america;
      case CalculationMethodType.ummAlQura:
        return adhan.CalculationMethod.umm_al_qura;
      case CalculationMethodType.egyptian:
        return adhan.CalculationMethod.egyptian;
      case CalculationMethodType.karachi:
        return adhan.CalculationMethod.karachi;
      case CalculationMethodType.tehran:
        return adhan.CalculationMethod.tehran;
      case CalculationMethodType.dubai:
        return adhan.CalculationMethod.dubai;
      case CalculationMethodType.kuwait:
        return adhan.CalculationMethod.kuwait;
      case CalculationMethodType.qatar:
        return adhan.CalculationMethod.qatar;
      case CalculationMethodType.singapore:
        return adhan.CalculationMethod.singapore;
      case CalculationMethodType.other:
        return adhan.CalculationMethod.other;
    }
  }

  /// Get regions where this method is commonly used
  String get regions {
    switch (this) {
      case CalculationMethodType.muslimWorldLeague:
        return 'Europe, Americas';
      case CalculationMethodType.isna:
        return 'North America';
      case CalculationMethodType.ummAlQura:
        return 'Saudi Arabia';
      case CalculationMethodType.egyptian:
        return 'Africa';
      case CalculationMethodType.karachi:
        return 'Pakistan, India';
      case CalculationMethodType.tehran:
        return 'Iran';
      case CalculationMethodType.dubai:
        return 'UAE';
      case CalculationMethodType.kuwait:
        return 'Kuwait';
      case CalculationMethodType.qatar:
        return 'Qatar';
      case CalculationMethodType.singapore:
        return 'Southeast Asia';
      case CalculationMethodType.other:
        return 'Custom';
    }
  }
}

/// Madhab for Asr calculation
@HiveType(typeId: 6)
enum MadhabType {
  /// Standard (Shafi'i, Maliki, Hanbali) - shadow = 1x object
  @HiveField(0)
  shafi,

  /// Hanafi - shadow = 2x object
  @HiveField(1)
  hanafi,
}

extension MadhabTypeExtension on MadhabType {
  String get displayName {
    switch (this) {
      case MadhabType.shafi:
        return 'Standard (Shafi\'i, Maliki, Hanbali)';
      case MadhabType.hanafi:
        return 'Hanafi';
    }
  }

  adhan.Madhab toAdhanMadhab() {
    switch (this) {
      case MadhabType.shafi:
        return adhan.Madhab.shafi;
      case MadhabType.hanafi:
        return adhan.Madhab.hanafi;
    }
  }
}

/// Notification settings for a single prayer
@HiveType(typeId: 7)
class PrayerNotificationSettings extends Equatable {
  /// Whether start-time notification is enabled
  @HiveField(0)
  final bool startNotification;

  /// Whether end-time warning notification is enabled
  @HiveField(1)
  final bool endWarning;

  /// Minutes before end time to show warning
  @HiveField(2)
  final int endWarningMinutes;

  const PrayerNotificationSettings({
    this.startNotification = true,
    this.endWarning = true,
    this.endWarningMinutes = 15,
  });

  PrayerNotificationSettings copyWith({
    bool? startNotification,
    bool? endWarning,
    int? endWarningMinutes,
  }) {
    return PrayerNotificationSettings(
      startNotification: startNotification ?? this.startNotification,
      endWarning: endWarning ?? this.endWarning,
      endWarningMinutes: endWarningMinutes ?? this.endWarningMinutes,
    );
  }

  @override
  List<Object?> get props => [startNotification, endWarning, endWarningMinutes];
}

/// App settings
@HiveType(typeId: 8)
class AppSettings extends Equatable {
  /// User location
  @HiveField(0)
  final LocationData? location;

  /// Prayer calculation method
  @HiveField(1)
  final CalculationMethodType calculationMethod;

  /// Madhab for Asr time
  @HiveField(2)
  final MadhabType madhab;

  /// Whether Tahajjud is enabled
  @HiveField(3)
  final bool includeTahajjud;

  /// Whether Ishraq is enabled
  @HiveField(4)
  final bool includeIshraq;

  /// Whether Duha is enabled
  @HiveField(5)
  final bool includeDuha;

  /// Whether notifications are enabled globally
  @HiveField(6)
  final bool notificationsEnabled;

  /// End-time warning in minutes
  @HiveField(7)
  final int endTimeWarningMinutes;

  /// Whether dynamic background is enabled
  @HiveField(8)
  final bool dynamicBackground;

  /// Whether to reduce motion for accessibility
  @HiveField(9)
  final bool reduceMotion;

  /// Text size multiplier
  @HiveField(10)
  final double textSizeMultiplier;

  /// Whether onboarding has been completed
  @HiveField(11)
  final bool onboardingCompleted;

  /// Per-prayer notification settings
  @HiveField(12)
  final Map<String, PrayerNotificationSettings> notificationSettings;

  /// Whether to show the weather widget on dashboard
  @HiveField(13, defaultValue: true)
  final bool showWeatherWidget;

  /// Preferred weather theme (auto = live, others = static)
  @HiveField(14, defaultValue: WeatherTheme.auto)
  final WeatherTheme weatherTheme;

  /// Whether weekly sunnah notifications are enabled
  @HiveField(15, defaultValue: true)
  final bool sunnahNotificationsEnabled;

  /// Whether special Islamic event notifications are enabled
  @HiveField(16, defaultValue: true)
  final bool islamicEventsEnabled;

  /// Whether to show Translation in Quran Reading
  @HiveField(17, defaultValue: true)
  final bool quranShowTranslation;

  /// Whether to show Transliteration in Quran Reading
  @HiveField(18, defaultValue: false)
  final bool quranShowTransliteration;

  /// Quran Arabic font size
  @HiveField(19, defaultValue: 28.0)
  final double quranArabicFontSize;

  /// Quran Translation font size
  @HiveField(20, defaultValue: 14.0)
  final double quranTranslationFontSize;

  /// Selected translation name
  @HiveField(21, defaultValue: 'Saheeh Intl')
  final String quranSelectedTranslation;

  const AppSettings({
    this.location,
    this.calculationMethod = CalculationMethodType.muslimWorldLeague,
    this.madhab = MadhabType.shafi,
    this.includeTahajjud = true,
    this.includeIshraq = false,
    this.includeDuha = false,
    this.notificationsEnabled = true,
    this.endTimeWarningMinutes = 15,
    this.dynamicBackground = true,
    this.reduceMotion = false,
    this.textSizeMultiplier = 1.0,
    this.onboardingCompleted = false,
    this.notificationSettings = const {},
    this.showWeatherWidget = true,
    this.weatherTheme = WeatherTheme.auto,
    this.sunnahNotificationsEnabled = true,
    this.islamicEventsEnabled = true,
    this.quranShowTranslation = true,
    this.quranShowTransliteration = false,
    this.quranArabicFontSize = 28.0,
    this.quranTranslationFontSize = 14.0,
    this.quranSelectedTranslation = 'Saheeh Intl',
  });

  /// Default settings
  factory AppSettings.defaults() => const AppSettings();

  /// Check if settings are valid and ready for use
  bool get isValid => location != null && location!.isValid;

  AppSettings copyWith({
    LocationData? location,
    CalculationMethodType? calculationMethod,
    MadhabType? madhab,
    bool? includeTahajjud,
    bool? includeIshraq,
    bool? includeDuha,
    bool? notificationsEnabled,
    int? endTimeWarningMinutes,
    bool? dynamicBackground,
    bool? reduceMotion,
    double? textSizeMultiplier,
    bool? onboardingCompleted,
    Map<String, PrayerNotificationSettings>? notificationSettings,
    bool? showWeatherWidget,
    WeatherTheme? weatherTheme,
    bool? sunnahNotificationsEnabled,
    bool? islamicEventsEnabled,
    bool? quranShowTranslation,
    bool? quranShowTransliteration,
    double? quranArabicFontSize,
    double? quranTranslationFontSize,
    String? quranSelectedTranslation,
  }) {
    return AppSettings(
      location: location ?? this.location,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      includeTahajjud: includeTahajjud ?? this.includeTahajjud,
      includeIshraq: includeIshraq ?? this.includeIshraq,
      includeDuha: includeDuha ?? this.includeDuha,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      endTimeWarningMinutes: endTimeWarningMinutes ?? this.endTimeWarningMinutes,
      dynamicBackground: dynamicBackground ?? this.dynamicBackground,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      textSizeMultiplier: textSizeMultiplier ?? this.textSizeMultiplier,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      showWeatherWidget: showWeatherWidget ?? this.showWeatherWidget,
      weatherTheme: weatherTheme ?? this.weatherTheme,
      sunnahNotificationsEnabled: sunnahNotificationsEnabled ?? this.sunnahNotificationsEnabled,
      islamicEventsEnabled: islamicEventsEnabled ?? this.islamicEventsEnabled,
      quranShowTranslation: quranShowTranslation ?? this.quranShowTranslation,
      quranShowTransliteration: quranShowTransliteration ?? this.quranShowTransliteration,
      quranArabicFontSize: quranArabicFontSize ?? this.quranArabicFontSize,
      quranTranslationFontSize: quranTranslationFontSize ?? this.quranTranslationFontSize,
      quranSelectedTranslation: quranSelectedTranslation ?? this.quranSelectedTranslation,
    );
  }

  @override
  List<Object?> get props => [
    location,
    calculationMethod,
    madhab,
    includeTahajjud,
    includeIshraq,
    includeDuha,
    notificationsEnabled,
    endTimeWarningMinutes,
    dynamicBackground,
    reduceMotion,
    textSizeMultiplier,
    notificationSettings,
    showWeatherWidget,
    weatherTheme,
    sunnahNotificationsEnabled,
    islamicEventsEnabled,
    quranShowTranslation,
    quranShowTransliteration,
    quranArabicFontSize,
    quranTranslationFontSize,
    quranSelectedTranslation,
  ];
}

/// Streak data
@HiveType(typeId: 9)
class StreakData extends Equatable {
  /// Current streak of perfect days
  @HiveField(0)
  final int currentStreak;

  /// Longest streak ever achieved
  @HiveField(1)
  final int longestStreak;

  /// Date of last perfect day
  @HiveField(2)
  final DateTime? lastPerfectDay;

  /// Per-prayer streaks
  /// Per-prayer streaks
  @HiveField(3)
  final Map<String, int>? prayerStreaks;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPerfectDay,
    this.prayerStreaks,
  });

  /// Default empty streak data
  factory StreakData.empty() => const StreakData(prayerStreaks: {});

  /// Get streak for a specific prayer
  int getPrayerStreak(String prayerName) => (prayerStreaks ?? {})[prayerName] ?? 0;

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPerfectDay,
    Map<String, int>? prayerStreaks,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPerfectDay: lastPerfectDay ?? this.lastPerfectDay,
      prayerStreaks: prayerStreaks ?? (this.prayerStreaks != null ? Map.from(this.prayerStreaks!) : null),
    );
  }

  @override
  List<Object?> get props => [currentStreak, longestStreak, lastPerfectDay, prayerStreaks];
}
