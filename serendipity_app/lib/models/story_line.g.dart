// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_line.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoryLineAdapter extends TypeAdapter<StoryLine> {
  @override
  final int typeId = 3;

  @override
  StoryLine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoryLine(
      id: fields[0] as String,
      name: fields[1] as String,
      recordIds: (fields[2] as List).cast<String>(),
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      isPinned: fields[5] as bool,
      userId: fields[6] as String?,
      sourceDeviceId: fields[7] as String?,
      deletedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StoryLine obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.recordIds)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.isPinned)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.sourceDeviceId)
      ..writeByte(8)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryLineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
