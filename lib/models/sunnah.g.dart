// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sunnah.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SunnahAdapter extends TypeAdapter<Sunnah> {
  @override
  final int typeId = 22;

  @override
  Sunnah read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sunnah(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      difficulty: fields[3] as SunnahDifficulty,
      frequency: fields[4] as SunnahFrequency,
      description: fields[5] as String,
      arabic: fields[6] as String?,
      transliteration: fields[7] as String?,
      translation: fields[8] as String?,
      virtue: fields[9] as String,
      reference: (fields[10] as Map).cast<String, String>(),
      tips: (fields[11] as List).cast<String>(),
      relatedSunnahs: (fields[12] as List).cast<String>(),
      tasbihId: fields[13] as String?,
      repetitions: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Sunnah obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.difficulty)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.arabic)
      ..writeByte(7)
      ..write(obj.transliteration)
      ..writeByte(8)
      ..write(obj.translation)
      ..writeByte(9)
      ..write(obj.virtue)
      ..writeByte(10)
      ..write(obj.reference)
      ..writeByte(11)
      ..write(obj.tips)
      ..writeByte(12)
      ..write(obj.relatedSunnahs)
      ..writeByte(13)
      ..write(obj.tasbihId)
      ..writeByte(14)
      ..write(obj.repetitions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SunnahAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SunnahDifficultyAdapter extends TypeAdapter<SunnahDifficulty> {
  @override
  final int typeId = 20;

  @override
  SunnahDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SunnahDifficulty.easy;
      case 1:
        return SunnahDifficulty.medium;
      case 2:
        return SunnahDifficulty.advanced;
      default:
        return SunnahDifficulty.easy;
    }
  }

  @override
  void write(BinaryWriter writer, SunnahDifficulty obj) {
    switch (obj) {
      case SunnahDifficulty.easy:
        writer.writeByte(0);
        break;
      case SunnahDifficulty.medium:
        writer.writeByte(1);
        break;
      case SunnahDifficulty.advanced:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SunnahDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SunnahFrequencyAdapter extends TypeAdapter<SunnahFrequency> {
  @override
  final int typeId = 21;

  @override
  SunnahFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SunnahFrequency.daily;
      case 1:
        return SunnahFrequency.weekly;
      case 2:
        return SunnahFrequency.monthly;
      case 3:
        return SunnahFrequency.occasional;
      default:
        return SunnahFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, SunnahFrequency obj) {
    switch (obj) {
      case SunnahFrequency.daily:
        writer.writeByte(0);
        break;
      case SunnahFrequency.weekly:
        writer.writeByte(1);
        break;
      case SunnahFrequency.monthly:
        writer.writeByte(2);
        break;
      case SunnahFrequency.occasional:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SunnahFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
