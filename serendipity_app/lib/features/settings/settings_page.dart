import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/providers/dialog_animation_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../models/enums.dart';

/// 设置页面（演示版）
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTransition = ref.watch(pageTransitionProvider);
    final currentDialogAnimation = ref.watch(dialogAnimationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '页面切换动画',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...PageTransitionType.values.map((type) {
            final isSelected = currentTransition == type;
            return ListTile(
              leading: Text(
                type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(type.label),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              selected: isSelected,
              onTap: () {
                ref.read(pageTransitionProvider.notifier).state = type;
                MessageHelper.showSuccess(context, '已切换到：${type.label}');
              },
            );
          }).toList(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '💡 提示：返回时间轴页面，点击记录卡片查看效果',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '对话框动画',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...DialogAnimationType.values.map((type) {
            final isSelected = currentDialogAnimation == type;
            return ListTile(
              leading: Text(
                type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(type.label),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              selected: isSelected,
              onTap: () {
                ref.read(dialogAnimationProvider.notifier).state = type;
                MessageHelper.showSuccess(context, '已切换到：${type.label}');
              },
            );
          }).toList(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '💡 提示：打开任意对话框查看效果',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

