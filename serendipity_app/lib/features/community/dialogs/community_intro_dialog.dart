import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/providers/user_settings_provider.dart';

/// 社区介绍对话框
/// 
/// 职责：
/// - 向首次进入社区的用户介绍树洞功能
/// - 说明树洞不能互动的原因（防骗 + 错过的本质）
/// - 强调"刀子美学"的设计理念
/// 
/// 调用者：
/// - CommunityPage（首次进入时自动显示）
class CommunityIntroDialog extends ConsumerWidget {
  const CommunityIntroDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('欢迎来到树洞'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('这里是一个匿名的树洞，\n记录着大家错过的瞬间。'),
            const SizedBox(height: 16),
            const Text('你可以在树洞中看到\n是否有别人记录了你。'),
            const SizedBox(height: 16),
            const Text('但树洞没有评论、点赞、\n也无法联系发布者。'),
            const SizedBox(height: 16),
            Text(
              '为什么要这么"残酷"？',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('因为这才是"错过"的本质。'),
            const SizedBox(height: 16),
            const Text('你发布到树洞后，\n也许 TA 会看到，\n也许 TA 会想"这不是我吗？"，\n但你永远不会知道。'),
            const SizedBox(height: 16),
            const Text('这种"也许"的不确定性，\n才是最美的遗憾。'),
            const SizedBox(height: 16),
            const Text('有人说这个设计很"刀"，\n但这就是错过的本质——\n有些遗憾，\n注定无法弥补。'),
            const SizedBox(height: 16),
            const Text('有些错过，\n注定只能是错过。'),
            const SizedBox(height: 16),
            const Text('但至少，\n我们记住了。'),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () async {
            // 标记用户已看过介绍
            await ref.read(userSettingsProvider.notifier).markCommunityIntroSeen();
            
            // Fail Fast: 检查 mounted
            if (!context.mounted) return;
            
            Navigator.of(context).pop();
          },
          child: const Text('我知道了'),
        ),
      ],
    );
  }

  /// 显示对话框（静态方法）
  /// 
  /// 调用者：
  /// - CommunityPage._showIntroDialogIfNeeded()
  /// 
  /// 如果用户已看过介绍，直接返回不显示
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // 检查用户是否已看过介绍
    final hasSeenIntro = ref.read(userSettingsProvider).hasSeenCommunityIntro;
    
    if (hasSeenIntro) {
      // 用户已看过介绍，直接返回
      return;
    }
    
    // 显示介绍对话框
    await DialogHelper.show(
      context: context,
      barrierDismissible: false, // 不允许点击外部关闭
      builder: (context) => const CommunityIntroDialog(),
    );
  }
}

