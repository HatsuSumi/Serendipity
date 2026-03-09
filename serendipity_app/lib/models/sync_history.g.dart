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
      source: fields[16] as SyncSource,
    );
  }

  @override
  void write(BinaryWriter writer, SyncHistory obj) {
    writer
      ..writeByte(17)
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
      ..write(obj.syncedAchievements)
      ..writeByte(16)
      ..write(obj.source);
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

class SyncSourceAdapter extends TypeAdapter<SyncSource> {
  @override
  final int typeId = 34;

  @override
  SyncSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncSource.manual;
      case 1:
        return SyncSource.appStartup;
      case 2:
        return SyncSource.login;
      case 3:
        return SyncSource.register;
      case 4:
        return SyncSource.networkReconnect;
      case 5:
        return SyncSource.polling;
      default:
        return SyncSource.manual;
    }
  }

  @override
  void write(BinaryWriter writer, SyncSource obj) {
    switch (obj) {
      case SyncSource.manual:
        writer.writeByte(0);
        break;
      case SyncSource.appStartup:
        writer.writeByte(1);
        break;
      case SyncSource.login:
        writer.writeByte(2);
        break;
      case SyncSource.register:
        writer.writeByte(3);
        break;
      case SyncSource.networkReconnect:
        writer.writeByte(4);
        break;
      case SyncSource.polling:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
