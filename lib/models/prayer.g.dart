// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrayerAdapter extends TypeAdapter<Prayer> {
  @override
  final int typeId = 0;

  @override
  Prayer read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Prayer.tahajjud;
      case 1:
        return Prayer.fajr;
      case 2:
        return Prayer.ishraq;
      case 3:
        return Prayer.duha;
      case 4:
        return Prayer.dhuhr;
      case 5:
        return Prayer.asr;
      case 6:
        return Prayer.maghrib;
      case 7:
        return Prayer.isha;
      default:
        return Prayer.tahajjud;
    }
  }

  @override
  void write(BinaryWriter writer, Prayer obj) {
    switch (obj) {
      case Prayer.tahajjud:
        writer.writeByte(0);
        break;
      case Prayer.fajr:
        writer.writeByte(1);
        break;
      case Prayer.ishraq:
        writer.writeByte(2);
        break;
      case Prayer.duha:
        writer.writeByte(3);
        break;
      case Prayer.dhuhr:
        writer.writeByte(4);
        break;
      case Prayer.asr:
        writer.writeByte(5);
        break;
      case Prayer.maghrib:
        writer.writeByte(6);
        break;
      case Prayer.isha:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
