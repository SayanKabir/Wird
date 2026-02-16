// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrayerEntryAdapter extends TypeAdapter<PrayerEntry> {
  @override
  final int typeId = 2;

  @override
  PrayerEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrayerEntry(
      status: fields[0] as PrayerStatus,
      timestamp: fields[1] as DateTime?,
      isJamaah: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PrayerEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.status)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.isJamaah);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrayerLogAdapter extends TypeAdapter<PrayerLog> {
  @override
  final int typeId = 3;

  @override
  PrayerLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrayerLog(
      date: fields[0] as DateTime,
      entries: (fields[1] as Map).cast<Prayer, PrayerEntry>(),
      isPerfectDay: fields[2] as bool,
      completionPercentage: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PrayerLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.entries)
      ..writeByte(2)
      ..write(obj.isPerfectDay)
      ..writeByte(3)
      ..write(obj.completionPercentage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
