import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/page_transition_provider.dart';
import '../../../core/providers/dialog_animation_provider.dart';
import '../../../core/providers/membership_provider.dart';
import '../../../core/providers/user_settings_provider.dart';
import '../../../core/utils/message_helper.dart';
import '../../../core/utils/auth_error_helper.dart';
import '../../../models/enums.dart';


/// 外观设置子页面
///
/// 包含：主题选择、页面跳转动画、对话框动画
///
/// 调用者：ProfilePage
class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTransition = ref.watch(pageTransitionProvider);
    final currentDialogAnimation = ref.watch(dialogAnimationProvider);
    final membershipAsync = ref.watch(membershipProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('外观设置')),
      body: ListView(
        children: [
          // ── 主题 ──────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '主题',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...ThemeOption.values.map((type) {
            return Consumer(
              builder: (context, ref, child) {
                final settings = ref.watch(userSettingsProvider);
                final isSelected = settings.theme == type;
                final canUseTheme = membershipAsync.when(
                  data: (info) => info.canUseTheme(type),
                  loading: () => !type.isPremium,
                  error: (_, e) => !type.isPremium,
                );
                return ListTile(
                  leading: Icon(
                    type.isPremium
                        ? Icons.workspace_premium_outlined
                        : Icons.palette_outlined,
                    color: canUseTheme
                        ? null
                        : Theme.of(context).colorScheme.outline,
                  ),
                  title: Text(type.label),
                  subtitle: type.isPremium
                      ? Text(canUseTheme ? '会员主题' : '会员专属主题')
                      : const Text('基础主题'),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : !canUseTheme
                          ? const Icon(Icons.lock_outline)
                          : null,
                  selected: isSelected,
                  onTap: () async {
                    if (!canUseTheme) {
                      MessageHelper.showWarning(
                          context, '${type.label} 为会员专属主题');
                      return;
                    }
                    try {
                      await ref
                          .read(userSettingsProvider.notifier)
                          .updateTheme(type);
                      if (context.mounted) {
                        MessageHelper.showSuccess(
                            context, '已切换到：${type.label}');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        MessageHelper.showError(
                          context,
                          '切换主题失败：${AuthErrorHelper.extractErrorMessage(e)}',
                        );
                      }
                    }
                  },
                );
              },
            );
          }),

          const Divider(),

          // ── 页面跳转动画 ──────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '页面跳转动画',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...PageTransitionType.values.map((type) {
            final isSelected = currentTransition == type;
            return ListTile(
              leading: Text(type.icon, style: const TextStyle(fontSize: 24)),
              title: Text(type.label),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              selected: isSelected,
              onTap: () async {
                await ref
                    .read(userSettingsProvider.notifier)
                    .updatePageTransition(type);
                if (context.mounted) {
                  MessageHelper.showSuccess(context, '已切换到：${type.label}');
                }
              },
            );
          }),
          const Divider(),

          // ── 对话框动画 ────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '对话框动画',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...DialogAnimationType.values.map((type) {
            final isSelected = currentDialogAnimation == type;
            return ListTile(
              leading: Text(type.icon, style: const TextStyle(fontSize: 24)),
              title: Text(type.label),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              selected: isSelected,
              onTap: () async {
                await ref
                    .read(userSettingsProvider.notifier)
                    .updateDialogAnimation(type);
                if (context.mounted) {
                  MessageHelper.showSuccess(context, '已切换到：${type.label}');
                }
              },
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
