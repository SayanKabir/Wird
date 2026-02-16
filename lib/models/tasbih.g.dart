// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasbih.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TasbihAdapter extends TypeAdapter<Tasbih> {
  @override
  final int typeId = 25;

  @override
  Tasbih read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tasbih(
      id: fields[0] as String,
      name: fields[1] as String,
      currentCount: fields[2] as int,
      targetCount: fields[3] as int,
      totalCount: fields[4] as int,
      lastUpdated: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Tasbih obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.currentCount)
      ..writeByte(3)
      ..write(obj.targetCount)
      ..writeByte(4)
      ..write(obj.totalCount)
      ..writeByte(5)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasbihAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
