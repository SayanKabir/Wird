// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationDataAdapter extends TypeAdapter<LocationData> {
  @override
  final int typeId = 4;

  @override
  LocationData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationData(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      city: fields[2] as String?,
      country: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.city)
      ..writeByte(3)
      ..write(obj.country);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrayerNotificationSettingsAdapter
    extends TypeAdapter<PrayerNotificationSettings> {
  @override
  final int typeId = 7;

  @override
  PrayerNotificationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrayerNotificationSettings(
      startNotification: fields[0] as bool,
      endWarning: fields[1] as bool,
      endWarningMinutes: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PrayerNotificationSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.startNotification)
      ..writeByte(1)
      ..write(obj.endWarning)
      ..writeByte(2)
      ..write(obj.endWarningMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerNotificationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 8;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      location: fields[0] as LocationData?,
      calculationMethod: fields[1] as CalculationMethodType,
      madhab: fields[2] as MadhabType,
      includeTahajjud: fields[3] as bool,
      includeIshraq: fields[4] as bool,
      includeDuha: fields[5] as bool,
      notificationsEnabled: fields[6] as bool,
      endTimeWarningMinutes: fields[7] as int,
      dynamicBackground: fields[8] as bool,
      reduceMotion: fields[9] as bool,
      textSizeMultiplier: fields[10] as double,
      onboardingCompleted: fields[11] as bool,
      notificationSettings:
          (fields[12] as Map).cast<String, PrayerNotificationSettings>(),
      showWeatherWidget: fields[13] == null ? true : fields[13] as bool,
      weatherTheme:
          fields[14] == null ? WeatherTheme.auto : fields[14] as WeatherTheme,
      sunnahNotificationsEnabled:
          fields[15] == null ? true : fields[15] as bool,
      islamicEventsEnabled: fields[16] == null ? true : fields[16] as bool,
      quranShowTranslation: fields[17] == null ? true : fields[17] as bool,
      quranShowTransliteration: fields[18] == null ? false : fields[18] as bool,
      quranArabicFontSize: fields[19] == null ? 28.0 : fields[19] as double,
      quranTranslationFontSize:
          fields[20] == null ? 14.0 : fields[20] as double,
      quranSelectedTranslation:
          fields[21] == null ? 'Saheeh Intl' : fields[21] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.location)
      ..writeByte(1)
      ..write(obj.calculationMethod)
      ..writeByte(2)
      ..write(obj.madhab)
      ..writeByte(3)
      ..write(obj.includeTahajjud)
      ..writeByte(4)
      ..write(obj.includeIshraq)
      ..writeByte(5)
      ..write(obj.includeDuha)
      ..writeByte(6)
      ..write(obj.notificationsEnabled)
      ..writeByte(7)
      ..write(obj.endTimeWarningMinutes)
      ..writeByte(8)
      ..write(obj.dynamicBackground)
      ..writeByte(9)
      ..write(obj.reduceMotion)
      ..writeByte(10)
      ..write(obj.textSizeMultiplier)
      ..writeByte(11)
      ..write(obj.onboardingCompleted)
      ..writeByte(12)
      ..write(obj.notificationSettings)
      ..writeByte(13)
      ..write(obj.showWeatherWidget)
      ..writeByte(14)
      ..write(obj.weatherTheme)
      ..writeByte(15)
      ..write(obj.sunnahNotificationsEnabled)
      ..writeByte(16)
      ..write(obj.islamicEventsEnabled)
      ..writeByte(17)
      ..write(obj.quranShowTranslation)
      ..writeByte(18)
      ..write(obj.quranShowTransliteration)
      ..writeByte(19)
      ..write(obj.quranArabicFontSize)
      ..writeByte(20)
      ..write(obj.quranTranslationFontSize)
      ..writeByte(21)
      ..write(obj.quranSelectedTranslation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StreakDataAdapter extends TypeAdapter<StreakData> {
  @override
  final int typeId = 9;

  @override
  StreakData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StreakData(
      currentStreak: fields[0] as int,
      longestStreak: fields[1] as int,
      lastPerfectDay: fields[2] as DateTime?,
      prayerStreaks: (fields[3] as Map?)?.cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, StreakData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.longestStreak)
      ..writeByte(2)
      ..write(obj.lastPerfectDay)
      ..writeByte(3)
      ..write(obj.prayerStreaks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalculationMethodTypeAdapter extends TypeAdapter<CalculationMethodType> {
  @override
  final int typeId = 5;

  @override
  CalculationMethodType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CalculationMethodType.muslimWorldLeague;
      case 1:
        return CalculationMethodType.isna;
      case 2:
        return CalculationMethodType.ummAlQura;
      case 3:
        return CalculationMethodType.egyptian;
      case 4:
        return CalculationMethodType.karachi;
      case 5:
        return CalculationMethodType.tehran;
      case 6:
        return CalculationMethodType.dubai;
      case 7:
        return CalculationMethodType.kuwait;
      case 8:
        return CalculationMethodType.qatar;
      case 9:
        return CalculationMethodType.singapore;
      case 10:
        return CalculationMethodType.other;
      default:
        return CalculationMethodType.muslimWorldLeague;
    }
  }

  @override
  void write(BinaryWriter writer, CalculationMethodType obj) {
    switch (obj) {
      case CalculationMethodType.muslimWorldLeague:
        writer.writeByte(0);
        break;
      case CalculationMethodType.isna:
        writer.writeByte(1);
        break;
      case CalculationMethodType.ummAlQura:
        writer.writeByte(2);
        break;
      case CalculationMethodType.egyptian:
        writer.writeByte(3);
        break;
      case CalculationMethodType.karachi:
        writer.writeByte(4);
        break;
      case CalculationMethodType.tehran:
        writer.writeByte(5);
        break;
      case CalculationMethodType.dubai:
        writer.writeByte(6);
        break;
      case CalculationMethodType.kuwait:
        writer.writeByte(7);
        break;
      case CalculationMethodType.qatar:
        writer.writeByte(8);
        break;
      case CalculationMethodType.singapore:
        writer.writeByte(9);
        break;
      case CalculationMethodType.other:
        writer.writeByte(10);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculationMethodTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeatherThemeAdapter extends TypeAdapter<WeatherTheme> {
  @override
  final int typeId = 10;

  @override
  WeatherTheme read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WeatherTheme.auto;
      case 1:
        return WeatherTheme.clear;
      case 2:
        return WeatherTheme.cloudy;
      case 3:
        return WeatherTheme.rain;
      case 4:
        return WeatherTheme.thunderstorm;
      case 5:
        return WeatherTheme.snow;
      case 6:
        return WeatherTheme.fog;
      default:
        return WeatherTheme.auto;
    }
  }

  @override
  void write(BinaryWriter writer, WeatherTheme obj) {
    switch (obj) {
      case WeatherTheme.auto:
        writer.writeByte(0);
        break;
      case WeatherTheme.clear:
        writer.writeByte(1);
        break;
      case WeatherTheme.cloudy:
        writer.writeByte(2);
        break;
      case WeatherTheme.rain:
        writer.writeByte(3);
        break;
      case WeatherTheme.thunderstorm:
        writer.writeByte(4);
        break;
      case WeatherTheme.snow:
        writer.writeByte(5);
        break;
      case WeatherTheme.fog:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherThemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MadhabTypeAdapter extends TypeAdapter<MadhabType> {
  @override
  final int typeId = 6;

  @override
  MadhabType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MadhabType.shafi;
      case 1:
        return MadhabType.hanafi;
      default:
        return MadhabType.shafi;
    }
  }

  @override
  void write(BinaryWriter writer, MadhabType obj) {
    switch (obj) {
      case MadhabType.shafi:
        writer.writeByte(0);
        break;
      case MadhabType.hanafi:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MadhabTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
