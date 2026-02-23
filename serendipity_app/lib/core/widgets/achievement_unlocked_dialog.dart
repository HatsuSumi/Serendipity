import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement.dart';
import '../providers/achievement_provider.dart';
import '../utils/dialog_helper.dart';

/// 成就解锁对话框
/// 
/// 显示一个或多个已解锁的成就
/// 
/// 架构设计：
/// - 使用 DialogHelper 统一对话框动画
/// - 遵循单一职责原则：只负责展示成就
/// - 数据通过 achievementsProvider 获取
/// 
/// 调用者：
/// - MainNavigationPage：监听 newlyUnlockedAchievementsProvider
/// 
/// 使用方式：
/// ```dart
/// AchievementUnlockedDialog.show(context, ['first_missed', 'record_10']);
/// ```
class AchievementUnlockedDialog extends ConsumerWidget {
  final List<String> achievementIds;

  const AchievementUnlockedDialog({
    super.key,
    required this.achievementIds,
  });

  /// 显示成就解锁对话框
  /// 
  /// 参数：
  /// - [context]: BuildContext
  /// - [achievementIds]: 成就ID列表
  /// 
  /// 返回：
  /// - 'view': 用户点击"查看成就"
  /// - 'continue': 用户点击"继续"或关闭对话框
  static Future<String?> show(
    BuildContext context,
    List<String> achievementIds,
  ) {
    assert(achievementIds.isNotEmpty, 'Achievement IDs cannot be empty');
    
    return DialogHelper.show<String>(
      context: context,
      barrierDismissible: false, // 不允许点击外部关闭
      builder: (context) => AchievementUnlockedDialog(
        achievementIds: achievementIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return achievementsAsync.when(
      data: (achievements) {
        // 获取所有解锁的成就
        final unlockedAchievements = achievementIds
            .map((id) => achievements.firstWhere(
                  (a) => a.id == id,
                  orElse: () => Achievement(
                    id: id,
                    name: '未知成就',
                    description: '成就信息加载失败',
                    icon: '🎉',
                    category: AchievementCategory.beginner,
                  ),
                ))
            .toList();

        return _buildDialog(context, unlockedAchievements);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorDialog(context),
    );
  }

  Widget _buildDialog(BuildContext context, List<Achievement> achievements) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Text(
            '🎉 成就解锁！',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: achievements.map((achievement) {
            return _buildAchievementItem(context, achievement);
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('continue'),
          child: const Text('继续'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop('view'),
          child: const Text('查看成就'),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(BuildContext context, Achievement achievement) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLastItem = achievementIds.last == achievement.id;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // 成就图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 成就信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description.split('\n').first,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLastItem) const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildErrorDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('加载失败'),
      content: const Text('无法加载成就信息'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('continue'),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

