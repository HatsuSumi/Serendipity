import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/providers/user_settings_provider.dart';
import '../../../core/mixins/countdown_mixin.dart';

/// 收藏页介绍对话框
///
/// 职责：
/// - 向首次进入收藏页的用户说明「已删除收藏」的设计理念
/// - 强调「刀子美学」：删除不代表消失，这是有意为之
///
/// 调用者：
/// - FavoritesPage（首次进入时自动显示）
class FavoritesIntroDialog extends ConsumerStatefulWidget {
  const FavoritesIntroDialog({super.key});

  @override
  ConsumerState<FavoritesIntroDialog> createState() =>
      _FavoritesIntroDialogState();

  /// 显示对话框（静态工厂方法）
  ///
  /// 调用者：
  /// - FavoritesPage._checkAndShowIntroDialog()
  ///
  /// 如果用户已看过介绍，直接返回不显示
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final hasSeenIntro =
        ref.read(userSettingsProvider).hasSeenFavoritesIntro;

    if (hasSeenIntro) return;

    await DialogHelper.show(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FavoritesIntroDialog(),
    );
  }
}

class _FavoritesIntroDialogState
    extends ConsumerState<FavoritesIntroDialog> with CountdownMixin {
  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  @override
  void dispose() {
    disposeCountdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.bookmark_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('关于收藏'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('你收藏的记录或帖子，\n即使被对方删除，\n也不会从收藏列表中消失。'),
            const SizedBox(height: 16),
            Text(
              '为什么要这么「残忍」？',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('有些人想释怀，\n会删掉记录、删掉帖子，\n不再回忆过去。'),
            const SizedBox(height: 16),
            const Text('但 Serendipity 不会替你删。'),
            const SizedBox(height: 16),
            const Text('你收藏过的，\n哪怕对方已经选择遗忘，\n你这里依然留着。'),
            const SizedBox(height: 16),
            const Text('这个设计很「刀」——\n但有时候，\n留着比忘记更诚实。'),
            const SizedBox(height: 16),
            const Text('当然，\n你随时可以手动取消收藏。'),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: countdownFinished
              ? () async {
                  await ref
                      .read(userSettingsProvider.notifier)
                      .markFavoritesIntroSeen();

                  if (!context.mounted) return;

                  Navigator.of(context).pop();
                }
              : null,
          child: Text(
            countdownFinished ? '我知道了' : '我知道了 ($countdown)',
          ),
        ),
      ],
    );
  }
}

