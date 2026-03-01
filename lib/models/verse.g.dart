// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VerseAdapter extends TypeAdapter<Verse> {
  @override
  final int typeId = 31;

  @override
  Verse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Verse(
      surahId: fields[0] as int,
      verseNumber: fields[1] as int,
      verseKey: fields[2] as String,
      textUthmani: fields[3] as String,
      page: fields[4] as int,
      juz: fields[5] as int,
      translationText: fields[6] as String?,
      translationName: fields[7] as String?,
      transliterationText: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Verse obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.surahId)
      ..writeByte(1)
      ..write(obj.verseNumber)
      ..writeByte(2)
      ..write(obj.verseKey)
      ..writeByte(3)
      ..write(obj.textUthmani)
      ..writeByte(4)
      ..write(obj.page)
      ..writeByte(5)
      ..write(obj.juz)
      ..writeByte(6)
      ..write(obj.translationText)
      ..writeByte(7)
      ..write(obj.translationName)
      ..writeByte(8)
      ..write(obj.transliterationText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
