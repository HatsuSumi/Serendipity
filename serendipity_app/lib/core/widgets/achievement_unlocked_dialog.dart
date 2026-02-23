import 'dart:math';
import 'package:confetti/confetti.dart';
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
/// - 添加粒子效果增强庆祝氛围
/// 
/// 调用者：
/// - MainNavigationPage：监听 newlyUnlockedAchievementsProvider
/// 
/// 使用方式：
/// ```dart
/// AchievementUnlockedDialog.show(context, ['first_missed', 'record_10']);
/// ```
class AchievementUnlockedDialog extends ConsumerStatefulWidget {
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
  ConsumerState<AchievementUnlockedDialog> createState() =>
      _AchievementUnlockedDialogState();
}

class _AchievementUnlockedDialogState
    extends ConsumerState<AchievementUnlockedDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // 延迟启动粒子效果，等待对话框动画完成
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // 对话框主体
        achievementsAsync.when(
          data: (achievements) {
            // 获取所有解锁的成就
            final unlockedAchievements = widget.achievementIds
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
        ),
        // 粒子效果
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // 向下喷射
            emissionFrequency: 0.05, // 发射频率
            numberOfParticles: 20, // 粒子数量
            maxBlastForce: 20, // 最大爆炸力
            minBlastForce: 10, // 最小爆炸力
            gravity: 0.3, // 重力
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDialog(BuildContext context, List<Achievement> achievements) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.celebration,
            size: 24,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '成就解锁！',
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
    final isLastItem = widget.achievementIds.last == achievement.id;

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

