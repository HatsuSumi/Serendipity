import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement.dart';
import '../../core/providers/achievement_provider.dart';

/// 成就解锁通知Widget
/// 
/// 从屏幕顶部滑入，显示成就解锁信息
/// 3秒后自动消失（或用户点击关闭）
/// 
/// 调用者：
/// - MainNavigationPage：监听newlyUnlockedAchievementsProvider，显示通知
class AchievementUnlockedNotification extends ConsumerWidget {
  final String achievementId;
  final VoidCallback onDismiss;

  const AchievementUnlockedNotification({
    super.key,
    required this.achievementId,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return achievementsAsync.when(
      data: (achievements) {
        final achievement = achievements.firstWhere(
          (a) => a.id == achievementId,
          orElse: () => Achievement(
            id: achievementId,
            name: '未知成就',
            description: '成就信息加载失败',
            icon: '🎉',
            category: AchievementCategory.beginner,
          ),
        );

        return _buildNotification(context, achievement);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNotification(BuildContext context, Achievement achievement) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onDismiss,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '🎉 成就解锁！',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        achievement.description.split('\n').first,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 关闭按钮
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 成就解锁通知管理器
/// 
/// 在屏幕顶部显示成就解锁通知的Overlay
/// 
/// 使用方式：
/// ```dart
/// AchievementNotificationManager.show(context, achievementId);
/// ```
class AchievementNotificationManager {
  static OverlayEntry? _currentEntry;

  /// 显示成就解锁通知
  static void show(BuildContext context, String achievementId) {
    // 如果已经有通知在显示，先移除
    dismiss();

    final overlay = Overlay.of(context);
    
    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 0,
        right: 0,
        child: _AnimatedNotification(
          achievementId: achievementId,
          onDismiss: dismiss,
        ),
      ),
    );

    overlay.insert(_currentEntry!);

    // 3秒后自动消失
    Future.delayed(const Duration(seconds: 3), () {
      dismiss();
    });
  }

  /// 关闭当前通知
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

/// 带动画的成就通知
class _AnimatedNotification extends StatefulWidget {
  final String achievementId;
  final VoidCallback onDismiss;

  const _AnimatedNotification({
    required this.achievementId,
    required this.onDismiss,
  });

  @override
  State<_AnimatedNotification> createState() => _AnimatedNotificationState();
}

class _AnimatedNotificationState extends State<_AnimatedNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AchievementUnlockedNotification(
          achievementId: widget.achievementId,
          onDismiss: _handleDismiss,
        ),
      ),
    );
  }
}

