// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncHistoryAdapter extends TypeAdapter<SyncHistory> {
  @override
  final int typeId = 33;

  @override
  SyncHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncHistory(
      id: fields[0] as String,
      syncTime: fields[1] as DateTime,
      isManual: fields[2] as bool,
      success: fields[3] as bool,
      durationMs: fields[4] as int,
      errorMessage: fields[5] as String?,
      uploadedRecords: fields[6] as int,
      uploadedStoryLines: fields[7] as int,
      uploadedCheckIns: fields[8] as int,
      downloadedRecords: fields[9] as int,
      downloadedStoryLines: fields[10] as int,
      downloadedCheckIns: fields[11] as int,
      mergedRecords: fields[12] as int,
      mergedStoryLines: fields[13] as int,
      mergedCheckIns: fields[14] as int,
      syncedAchievements: fields[15] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SyncHistory obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.syncTime)
      ..writeByte(2)
      ..write(obj.isManual)
      ..writeByte(3)
      ..write(obj.success)
      ..writeByte(4)
      ..write(obj.durationMs)
      ..writeByte(5)
      ..write(obj.errorMessage)
      ..writeByte(6)
      ..write(obj.uploadedRecords)
      ..writeByte(7)
      ..write(obj.uploadedStoryLines)
      ..writeByte(8)
      ..write(obj.uploadedCheckIns)
      ..writeByte(9)
      ..write(obj.downloadedRecords)
      ..writeByte(10)
      ..write(obj.downloadedStoryLines)
      ..writeByte(11)
      ..write(obj.downloadedCheckIns)
      ..writeByte(12)
      ..write(obj.mergedRecords)
      ..writeByte(13)
      ..write(obj.mergedStoryLines)
      ..writeByte(14)
      ..write(obj.mergedCheckIns)
      ..writeByte(15)
      ..write(obj.syncedAchievements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
