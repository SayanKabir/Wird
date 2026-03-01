// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quran_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuranProgressAdapter extends TypeAdapter<QuranProgress> {
  @override
  final int typeId = 33;

  @override
  QuranProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuranProgress(
      totalVersesRead: fields[0] as int,
      currentStreak: fields[1] as int,
      longestStreak: fields[2] as int,
      daysRead: fields[3] as int,
      versesReadByDay: (fields[4] as Map?)?.cast<String, int>(),
      lastReadDateKey: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QuranProgress obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.totalVersesRead)
      ..writeByte(1)
      ..write(obj.currentStreak)
      ..writeByte(2)
      ..write(obj.longestStreak)
      ..writeByte(3)
      ..write(obj.daysRead)
      ..writeByte(4)
      ..write(obj.versesReadByDay)
      ..writeByte(5)
      ..write(obj.lastReadDateKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuranProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
