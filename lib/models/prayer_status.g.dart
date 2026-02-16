// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrayerStatusAdapter extends TypeAdapter<PrayerStatus> {
  @override
  final int typeId = 1;

  @override
  PrayerStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PrayerStatus.pending;
      case 1:
        return PrayerStatus.onTime;
      case 2:
        return PrayerStatus.late;
      case 3:
        return PrayerStatus.missed;
      case 4:
        return PrayerStatus.upcoming;
      default:
        return PrayerStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, PrayerStatus obj) {
    switch (obj) {
      case PrayerStatus.pending:
        writer.writeByte(0);
        break;
      case PrayerStatus.onTime:
        writer.writeByte(1);
        break;
      case PrayerStatus.late:
        writer.writeByte(2);
        break;
      case PrayerStatus.missed:
        writer.writeByte(3);
        break;
      case PrayerStatus.upcoming:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
