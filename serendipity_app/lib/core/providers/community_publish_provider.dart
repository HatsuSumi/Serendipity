import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../repositories/community_repository.dart';
import '../services/achievement_detector.dart';
import '../utils/auth_error_helper.dart';
import 'auth_provider.dart';
import 'achievement_provider.dart';
import 'community_provider.dart';

// 导入发布状态枚举
export '../../features/community/dialogs/publish_confirm_dialog.dart' show PublishStatus, RecordPublishInfo;

/// 社区发布仓储 Provider
final communityPublishRepositoryProvider = Provider<CommunityRepository>((ref) {
  return ref.read(communityRepositoryProvider);
});

/// 社区发布状态管理
/// 
/// 职责：
/// - 发布记录到社区（单条/批量）
/// - 检查发布状态
/// 
/// 调用者：
/// - PublishToCommunityDialog（发布对话框）
/// - RecordDetailPage（记录详情页）
/// - TimelinePage（时间轴页面）
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责发布相关操作
/// - 依赖倒置（DIP）：依赖 Repository 抽象
/// - Fail Fast：参数验证在 Repository 层
class CommunityPublishNotifier extends AsyncNotifier<void> {
  late CommunityRepository _repository;

  @override
  Future<void> build() async {
    _repository = ref.read(communityPublishRepositoryProvider);
    // 发布 Provider 不需要初始状态
  }

  /// 获取成就检测服务
  AchievementDetector get _achievementDetector => ref.read(achievementDetectorProvider);

  /// 发布记录到社区
  /// 
  /// Fail Fast:
  /// - 如果用户未登录，抛出 Exception
  /// - 如果记录为 null，Repository 层会抛出 ArgumentError
  /// 
  /// 参数：
  /// - record: 要发布的记录
  /// - forceReplace: 是否强制替换（用户已确认）
  /// - skipRefresh: 是否跳过刷新（批量发布时使用）
  /// 
  /// 返回：
  /// - replaced: 是否替换了旧帖子
  /// 
  /// 调用者：
  /// - RecordDetailPage（记录详情页菜单）
  /// - CreateRecordPage（创建记录时勾选"发布到树洞"）
  /// - TimelinePage（时间轴页面菜单）
  Future<bool> publishPost(
    EncounterRecord record, {
    bool forceReplace = false,
    bool skipRefresh = false,
  }) async {
    // Fail Fast: 用户必须登录
    final authState = ref.read(authProvider);
    final currentUser = authState.value;

    if (currentUser == null) {
      throw Exception('必须登录后才可发布');
    }

    try {
      // 发布到社区
      final replaced = await _repository.publishPost(
        record,
        currentUser.id,
        forceReplace: forceReplace,
      );

      // 检测社区成就（只在非批量发布时检测）
      if (!skipRefresh) {
        try {
          final unlockedAchievements =
              await _achievementDetector.checkCommunityAchievements(currentUser.id);
          if (unlockedAchievements.isNotEmpty) {
            // 通知UI层显示成就解锁通知
            ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
            // 刷新成就列表
            ref.invalidate(achievementsProvider);
          }
        } catch (e) {
          // 成就检测失败不影响发布
        }

        // 刷新社区帖子列表（通知列表 Provider）
        ref.invalidate(communityProvider);
        ref.invalidate(myPostsProvider);
      }

      return replaced;
    } catch (e) {
      // 使用 AuthErrorHelper 清理异常前缀
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 批量发布记录到社区
  /// 
  /// Fail Fast:
  /// - 如果用户未登录，抛出 Exception
  /// - 如果 records 为空，抛出 ArgumentError
  /// 
  /// 返回：
  /// - successCount: 成功发布的数量
  /// - replacedCount: 替换旧帖的数量
  /// 
  /// 调用者：PublishToCommunityDialog._handleConfirm()
  Future<({int successCount, int replacedCount})> publishPosts(
    List<({EncounterRecord record, bool forceReplace})> records,
  ) async {
    // Fail Fast: 参数验证
    if (records.isEmpty) {
      throw ArgumentError('records cannot be empty');
    }

    // Fail Fast: 用户必须登录
    final authState = ref.read(authProvider);
    final currentUser = authState.value;

    if (currentUser == null) {
      throw Exception('必须登录后才可发布');
    }

    int successCount = 0;
    int replacedCount = 0;

    // 批量发布，跳过每次刷新
    for (final item in records) {
      try {
        final replaced = await publishPost(
          item.record,
          forceReplace: item.forceReplace,
          skipRefresh: true,
        );

        successCount++;
        if (replaced) {
          replacedCount++;
        }
      } catch (e) {
        // 单条记录发布失败，继续发布其他记录
      }
    }

    // 批量发布完成后，统一检测成就
    try {
      final unlockedAchievements =
          await _achievementDetector.checkCommunityAchievements(currentUser.id);
      if (unlockedAchievements.isNotEmpty) {
        ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
        ref.invalidate(achievementsProvider);
      }
    } catch (e) {
      // 成就检测失败不影响发布
    }

    // 统一刷新社区帖子列表一次
    ref.invalidate(communityProvider);
    ref.invalidate(myPostsProvider);

    return (successCount: successCount, replacedCount: replacedCount);
  }

  /// 批量检查发布状态
  /// 
  /// Fail Fast:
  /// - 如果 records 为空，抛出 ArgumentError
  /// 
  /// 返回：
  /// - `Map<recordId, PublishStatus>`：每条记录的发布状态
  /// 
  /// 调用者：PublishToCommunityDialog._handleConfirm()
  Future<Map<String, String>> checkPublishStatus(List<EncounterRecord> records) async {
    // Fail Fast: 参数验证
    if (records.isEmpty) {
      throw Exception('记录列表不能为空');
    }

    try {
      return await _repository.checkPublishStatus(records);
    } catch (e) {
      // 使用 AuthErrorHelper 清理异常前缀
      throw Exception(AuthErrorHelper.extractErrorMessage(e));
    }
  }

  /// 准备批量发布（完整流程的第一步）
  /// 
  /// 封装了发布流程的准备阶段：
  /// 1. 检查发布状态
  /// 2. 按状态分组记录
  /// 3. 返回记录发布信息列表
  /// 
  /// UI层只需：
  /// 1. 调用此方法获取记录信息
  /// 2. 显示确认对话框
  /// 3. 调用 executePublish 执行发布
  /// 
  /// 参数：
  /// - records: 要发布的记录列表
  /// 
  /// 返回：
  /// - 记录发布信息列表（包含每条记录的发布状态）
  /// 
  /// 调用者：PublishToCommunityDialog._handleConfirm()
  Future<List<RecordPublishInfo>> preparePublish(
    List<EncounterRecord> records,
  ) async {
    // Fail Fast: 参数验证
    if (records.isEmpty) {
      throw ArgumentError('records cannot be empty');
    }

    // 步骤1：检查发布状态
    final statusMap = await checkPublishStatus(records);

    // 步骤2：按状态分组，转换为 RecordPublishInfo
    return records.map((record) {
      final status = statusMap[record.id] ?? 'can_publish';
      return RecordPublishInfo(
        record: record,
        status: _parsePublishStatus(status),
      );
    }).toList();
  }

  /// 执行批量发布（完整流程的第二步）
  /// 
  /// 封装了发布流程的执行阶段：
  /// 1. 过滤掉不能发布的记录
  /// 2. 批量发布记录
  /// 3. 检测成就
  /// 4. 刷新列表
  /// 
  /// 参数：
  /// - recordInfos: 记录发布信息列表（来自 preparePublish）
  /// 
  /// 返回：
  /// - successCount: 成功发布的数量
  /// - replacedCount: 替换旧帖的数量
  /// 
  /// 调用者：PublishToCommunityDialog._handleConfirm()
  Future<({int successCount, int replacedCount})> executePublish(
    List<RecordPublishInfo> recordInfos,
  ) async {
    // Fail Fast: 参数验证
    if (recordInfos.isEmpty) {
      throw ArgumentError('recordInfos cannot be empty');
    }

    // 步骤1：过滤掉不能发布的记录
    final publishItems = recordInfos
        .where((info) => info.status != PublishStatus.cannotPublish)
        .map((info) => (
              record: info.record,
              forceReplace: info.status == PublishStatus.needConfirm,
            ))
        .toList();

    // 步骤2：批量发布
    return await publishPosts(publishItems);
  }

  /// 解析发布状态字符串
  /// 
  /// 参数：
  /// - status: 后端返回的状态字符串
  /// 
  /// 返回：
  /// - PublishStatus 枚举值
  PublishStatus _parsePublishStatus(String status) {
    switch (status) {
      case 'can_publish':
        return PublishStatus.canPublish;
      case 'need_confirm':
        return PublishStatus.needConfirm;
      case 'cannot_publish':
        return PublishStatus.cannotPublish;
      default:
        return PublishStatus.canPublish;
    }
  }
}

/// 社区发布 Provider
/// 
/// 职责：管理社区发布相关操作
/// 
/// 使用示例：
/// ```dart
/// // 发布单条记录
/// await ref.read(communityPublishProvider.notifier).publishPost(record);
/// 
/// // 批量发布
/// final result = await ref.read(communityPublishProvider.notifier).publishPosts(records);
/// 
/// // 检查发布状态
/// final statusMap = await ref.read(communityPublishProvider.notifier).checkPublishStatus(records);
/// ```
final communityPublishProvider = AsyncNotifierProvider<CommunityPublishNotifier, void>(() {
  return CommunityPublishNotifier();
});

