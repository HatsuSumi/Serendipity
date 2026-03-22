// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encounter_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TagWithNoteAdapter extends TypeAdapter<TagWithNote> {
  @override
  final int typeId = 0;

  @override
  TagWithNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TagWithNote(
      tag: fields[0] as String,
      note: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TagWithNote obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.tag)
      ..writeByte(1)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagWithNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocationAdapter extends TypeAdapter<Location> {
  @override
  final int typeId = 1;

  @override
  Location read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Location(
      latitude: fields[0] as double?,
      longitude: fields[1] as double?,
      address: fields[2] as String?,
      placeName: fields[3] as String?,
      placeType: fields[4] as PlaceType?,
      province: fields[5] as String?,
      city: fields[6] as String?,
      area: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Location obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.placeName)
      ..writeByte(4)
      ..write(obj.placeType)
      ..writeByte(5)
      ..write(obj.province)
      ..writeByte(6)
      ..write(obj.city)
      ..writeByte(7)
      ..write(obj.area);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EncounterRecordAdapter extends TypeAdapter<EncounterRecord> {
  @override
  final int typeId = 2;

  @override
  EncounterRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EncounterRecord(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      location: fields[2] as Location,
      description: fields[3] as String?,
      tags: (fields[4] as List).cast<TagWithNote>(),
      emotion: fields[5] as EmotionIntensity?,
      status: fields[6] as EncounterStatus,
      storyLineId: fields[7] as String?,
      ifReencounter: fields[8] as String?,
      conversationStarter: fields[9] as String?,
      backgroundMusic: fields[10] as String?,
      weather: (fields[11] as List).cast<Weather>(),
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      isPinned: fields[14] as bool,
      ownerId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EncounterRecord obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.emotion)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.storyLineId)
      ..writeByte(8)
      ..write(obj.ifReencounter)
      ..writeByte(9)
      ..write(obj.conversationStarter)
      ..writeByte(10)
      ..write(obj.backgroundMusic)
      ..writeByte(11)
      ..write(obj.weather)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.isPinned)
      ..writeByte(15)
      ..write(obj.ownerId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncounterRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
