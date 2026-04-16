part of '../storage_service.dart';

mixin _StorageServiceAchievements on _StorageServiceCore {
  @override
  Future<void> saveAchievement(Achievement achievement) async {
    assert(achievement.id.isNotEmpty, 'Achievement ID cannot be empty');
    await achievementsBoxOrThrow.put(achievement.id, achievement);
  }

  @override
  Achievement? getAchievement(String id) {
    assert(id.isNotEmpty, 'Achievement ID cannot be empty');
    return achievementsBoxOrThrow.get(id);
  }

  @override
  List<Achievement> getAllAchievements() {
    return achievementsBoxOrThrow.values.toList();
  }

  @override
  Future<void> updateAchievement(Achievement achievement) async {
    assert(achievement.id.isNotEmpty, 'Achievement ID cannot be empty');
    await achievementsBoxOrThrow.put(achievement.id, achievement);
  }
}
