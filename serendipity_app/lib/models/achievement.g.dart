// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 31;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      icon: fields[3] as String,
      category: fields[4] as AchievementCategory,
      unlocked: fields[5] as bool,
      unlockedAt: fields[6] as DateTime?,
      progress: fields[7] as int?,
      target: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.unlocked)
      ..writeByte(6)
      ..write(obj.unlockedAt)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.target);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementCategoryAdapter extends TypeAdapter<AchievementCategory> {
  @override
  final int typeId = 30;

  @override
  AchievementCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementCategory.beginner;
      case 1:
        return AchievementCategory.advanced;
      case 2:
        return AchievementCategory.rare;
      case 3:
        return AchievementCategory.storyLine;
      case 4:
        return AchievementCategory.social;
      case 5:
        return AchievementCategory.emotional;
      case 6:
        return AchievementCategory.special;
      default:
        return AchievementCategory.beginner;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementCategory obj) {
    switch (obj) {
      case AchievementCategory.beginner:
        writer.writeByte(0);
        break;
      case AchievementCategory.advanced:
        writer.writeByte(1);
        break;
      case AchievementCategory.rare:
        writer.writeByte(2);
        break;
      case AchievementCategory.storyLine:
        writer.writeByte(3);
        break;
      case AchievementCategory.social:
        writer.writeByte(4);
        break;
      case AchievementCategory.emotional:
        writer.writeByte(5);
        break;
      case AchievementCategory.special:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
