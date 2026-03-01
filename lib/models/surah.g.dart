// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surah.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SurahAdapter extends TypeAdapter<Surah> {
  @override
  final int typeId = 30;

  @override
  Surah read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Surah(
      id: fields[0] as int,
      nameArabic: fields[1] as String,
      nameTranslation: fields[2] as String,
      nameTransliteration: fields[3] as String,
      versesCount: fields[4] as int,
      revelationPlace: fields[5] as String,
      revelationOrder: fields[6] as int,
      pages: (fields[7] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, Surah obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nameArabic)
      ..writeByte(2)
      ..write(obj.nameTranslation)
      ..writeByte(3)
      ..write(obj.nameTransliteration)
      ..writeByte(4)
      ..write(obj.versesCount)
      ..writeByte(5)
      ..write(obj.revelationPlace)
      ..writeByte(6)
      ..write(obj.revelationOrder)
      ..writeByte(7)
      ..write(obj.pages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurahAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
