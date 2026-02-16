// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'azkar.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AzkarAdapter extends TypeAdapter<Azkar> {
  @override
  final int typeId = 24;

  @override
  Azkar read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Azkar(
      id: fields[0] as String,
      category: fields[1] as AzkarCategory,
      order: fields[2] as int,
      arabic: fields[3] as String,
      transliteration: fields[4] as String,
      translation: fields[5] as String,
      repetitions: fields[6] as int,
      virtue: fields[7] as String,
      reference: (fields[8] as Map).cast<String, String>(),
      audioUrl: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Azkar obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.order)
      ..writeByte(3)
      ..write(obj.arabic)
      ..writeByte(4)
      ..write(obj.transliteration)
      ..writeByte(5)
      ..write(obj.translation)
      ..writeByte(6)
      ..write(obj.repetitions)
      ..writeByte(7)
      ..write(obj.virtue)
      ..writeByte(8)
      ..write(obj.reference)
      ..writeByte(9)
      ..write(obj.audioUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AzkarAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AzkarCategoryAdapter extends TypeAdapter<AzkarCategory> {
  @override
  final int typeId = 23;

  @override
  AzkarCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AzkarCategory.morning;
      case 1:
        return AzkarCategory.evening;
      case 2:
        return AzkarCategory.beforeSleep;
      case 3:
        return AzkarCategory.afterPrayer;
      case 4:
        return AzkarCategory.wakingUp;
      case 5:
        return AzkarCategory.mosque;
      case 6:
        return AzkarCategory.wudu;
      case 7:
        return AzkarCategory.food;
      case 8:
        return AzkarCategory.home;
      case 9:
        return AzkarCategory.travel;
      case 10:
        return AzkarCategory.hajjUmrah;
      case 11:
        return AzkarCategory.nature;
      default:
        return AzkarCategory.morning;
    }
  }

  @override
  void write(BinaryWriter writer, AzkarCategory obj) {
    switch (obj) {
      case AzkarCategory.morning:
        writer.writeByte(0);
        break;
      case AzkarCategory.evening:
        writer.writeByte(1);
        break;
      case AzkarCategory.beforeSleep:
        writer.writeByte(2);
        break;
      case AzkarCategory.afterPrayer:
        writer.writeByte(3);
        break;
      case AzkarCategory.wakingUp:
        writer.writeByte(4);
        break;
      case AzkarCategory.mosque:
        writer.writeByte(5);
        break;
      case AzkarCategory.wudu:
        writer.writeByte(6);
        break;
      case AzkarCategory.food:
        writer.writeByte(7);
        break;
      case AzkarCategory.home:
        writer.writeByte(8);
        break;
      case AzkarCategory.travel:
        writer.writeByte(9);
        break;
      case AzkarCategory.hajjUmrah:
        writer.writeByte(10);
        break;
      case AzkarCategory.nature:
        writer.writeByte(11);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AzkarCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
