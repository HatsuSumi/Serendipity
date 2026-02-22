// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckInRecordAdapter extends TypeAdapter<CheckInRecord> {
  @override
  final int typeId = 32;

  @override
  CheckInRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckInRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      checkedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CheckInRecord obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.checkedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
