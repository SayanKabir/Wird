// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quran_bookmark.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuranBookmarkAdapter extends TypeAdapter<QuranBookmark> {
  @override
  final int typeId = 32;

  @override
  QuranBookmark read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuranBookmark(
      id: fields[0] as String,
      surahId: fields[1] as int,
      verseNumber: fields[2] as int,
      surahName: fields[3] as String?,
      label: fields[4] as String?,
      note: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      isLastRead: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, QuranBookmark obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.surahId)
      ..writeByte(2)
      ..write(obj.verseNumber)
      ..writeByte(3)
      ..write(obj.surahName)
      ..writeByte(4)
      ..write(obj.label)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isLastRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuranBookmarkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
