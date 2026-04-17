import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement_unlock.dart';
import '../../models/encounter_record.dart';
import '../services/sync_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'community_provider.dart';
import 'favorites_provider.dart';
import 'records_provider.dart';
import 'story_lines_provider.dart';

/// 记录写命令状态管理
///
/// 职责：
/// - 处理记录的增删改写命令
/// - 编排记录写入后的跨域副作用
/// - 不持有记录列表状态
class RecordsCommandNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  SyncService get _syncService => ref.read(syncServiceProvider);

  /// 保存记录（自动处理故事线关联）
  ///
  /// 集成云端同步：
  /// - 如果用户已登录，保存到本地后自动上传到云端
  /// - 如果用户未登录，只保存到本地（离线模式）
  /// - 云端同步失败不影响本地操作
  Future<void> saveRecord(EncounterRecord record) async {
    final repository = ref.read(recordRepositoryProvider);

    await repository.saveRecord(record);

    if (record.storyLineId != null) {
      final storyLineRepo = ref.read(storyLineRepositoryProvider);
      await storyLineRepo.linkRecord(record.id, record.storyLineId!);
      ref.invalidate(storyLinesProvider);
    }

    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.uploadRecord(currentUser, record);
      } catch (_) {}
    }

    await ref.read(recordsProvider.notifier).refreshSilently();
  }

  /// 检测记录的成就解锁（由调用者在页面关闭后手动触发）
  Future<void> checkAchievementsForRecord(EncounterRecord record) async {
    try {
      final currentUser = await ref.read(authProvider.notifier).currentUser;
      if (currentUser == null) {
        return;
      }

      final detector = ref.read(achievementDetectorProvider);
      final unlockedAchievements = await detector.checkRecordAchievements(record, currentUser.id);

      if (record.storyLineId != null) {
        final storyLineAchievements = await detector.checkStoryLineAchievements(currentUser.id);
        unlockedAchievements.addAll(storyLineAchievements);
      }

      if (unlockedAchievements.isNotEmpty) {
        ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
        ref.invalidate(achievementsProvider);
        await _uploadAchievementUnlocks(unlockedAchievements);
      }
    } catch (_) {}
  }

  /// 更新记录（自动处理故事线关联变化）
  Future<void> updateRecord(EncounterRecord record) async {
    final repository = ref.read(recordRepositoryProvider);

    final oldRecord = repository.getRecord(record.id);
    final oldStoryLineId = oldRecord?.storyLineId;
    final newStoryLineId = record.storyLineId;

    await repository.updateRecord(record);

    if (oldStoryLineId != newStoryLineId) {
      final storyLineRepo = ref.read(storyLineRepositoryProvider);

      if (oldStoryLineId != null) {
        await storyLineRepo.unlinkRecord(record.id, oldStoryLineId);
      }

      if (newStoryLineId != null) {
        await storyLineRepo.linkRecord(record.id, newStoryLineId);
      }

      ref.invalidate(storyLinesProvider);
    }

    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.updateRecord(currentUser, record);
      } catch (_) {}
    }

    await ref.read(recordsProvider.notifier).refreshSilently();
  }

  /// 删除记录（自动从故事线移除，并联动删除对应社区帖子）
  Future<void> deleteRecord(String id) async {
    final repository = ref.read(recordRepositoryProvider);

    final record = repository.getRecord(id);
    if (record != null && record.storyLineId != null) {
      final storyLineRepo = ref.read(storyLineRepositoryProvider);
      await storyLineRepo.unlinkRecord(id, record.storyLineId!);
      ref.invalidate(storyLinesProvider);
    }

    await repository.deleteRecord(id);

    Exception? syncException;
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.deleteRecord(currentUser, id);
      } catch (e) {
        syncException = e is Exception ? e : Exception(e.toString());
      }

      try {
        final communityRepo = ref.read(communityRepositoryProvider);
        await communityRepo.deletePostByRecordId(id);
        ref.invalidate(communityProvider);
        ref.invalidate(myPostsProvider);
      } catch (_) {}
    }

    await ref.read(recordsProvider.notifier).refreshSilently();
    ref.invalidate(favoritesProvider);

    if (syncException != null) {
      throw syncException;
    }
  }

  /// 切换置顶状态
  Future<void> togglePin(String id) async {
    final repository = ref.read(recordRepositoryProvider);
    final record = repository.getRecord(id);
    if (record == null) {
      throw StateError('Record $id does not exist');
    }

    if (record.isPinned) {
      await _unpinRecord(record);
    } else {
      await _pinRecord(record);
    }
  }

  Future<void> _pinRecord(EncounterRecord record) async {
    final repository = ref.read(recordRepositoryProvider);
    final updatedRecord = record.copyWith(
      isPinned: true,
      updatedAt: DateTime.now(),
    );

    await repository.updateRecord(updatedRecord);

    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.updateRecord(currentUser, updatedRecord);
      } catch (_) {}
    }

    await ref.read(recordsProvider.notifier).refreshSilently();
  }

  Future<void> _unpinRecord(EncounterRecord record) async {
    final repository = ref.read(recordRepositoryProvider);
    final updatedRecord = record.copyWith(
      isPinned: false,
      updatedAt: DateTime.now(),
    );

    await repository.updateRecord(updatedRecord);

    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser != null) {
      try {
        await _syncService.updateRecord(currentUser, updatedRecord);
      } catch (_) {}
    }

    await ref.read(recordsProvider.notifier).refreshSilently();
  }

  /// 上传成就解锁记录到云端
  Future<void> _uploadAchievementUnlocks(List<String> achievementIds) async {
    if (achievementIds.isEmpty) {
      return;
    }

    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser == null) {
      return;
    }

    final achievementRepo = ref.read(achievementRepositoryProvider);

    for (final achievementId in achievementIds) {
      if (achievementId.isEmpty) {
        continue;
      }

      try {
        final achievement = await achievementRepo.getAchievement(achievementId);
        if (achievement == null || !achievement.unlocked || achievement.unlockedAt == null) {
          continue;
        }

        final unlock = AchievementUnlock(
          userId: currentUser.id,
          achievementId: achievementId,
          unlockedAt: achievement.unlockedAt!,
        );

        await _syncService.uploadAchievementUnlock(unlock);
      } catch (_) {}
    }
  }
}

final recordsCommandProvider = AsyncNotifierProvider<RecordsCommandNotifier, void>(() {
  return RecordsCommandNotifier();
});

