import '../../models/achievement_unlock.dart';
import '../../models/user.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/i_remote_data_repository.dart';

class AchievementSyncService {
  final IRemoteDataRepository _remoteRepository;
  final AchievementRepository _achievementRepository;

  AchievementSyncService({
    required IRemoteDataRepository remoteRepository,
    required AchievementRepository achievementRepository,
  }) : _remoteRepository = remoteRepository,
       _achievementRepository = achievementRepository;

  Future<void> uploadAchievementUnlock(AchievementUnlock unlock) async {
    if (unlock.userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (unlock.achievementId.isEmpty) {
      throw ArgumentError('成就 ID 不能为空');
    }

    await _remoteRepository.uploadAchievementUnlock(unlock);
  }

  Future<int> syncAchievementUnlocks(User user) async {
    try {
      final remoteUnlocks = await _remoteRepository.downloadAchievementUnlocks(user.id);
      final newlyUnlocked = await _achievementRepository.syncAchievementUnlocks(remoteUnlocks);
      return newlyUnlocked;
    } catch (e) {
      return 0;
    }
  }
}

