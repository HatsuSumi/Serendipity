import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/providers/dialog_animation_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/providers/check_in_provider.dart';
import '../../core/providers/first_launch_provider.dart';
import '../../core/providers/user_settings_provider.dart';
import '../../core/providers/sync_status_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/phone_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/widgets/countdown_button.dart';
import '../../models/enums.dart';
import '../auth/widgets/auth_text_field.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../auth/welcome_page.dart';
import '../test/location_test_page.dart';
import '../achievement/achievements_page.dart';
import '../check_in/check_in_page.dart';
import '../community/my_posts_page.dart';
import 'dialogs/manual_sync_dialog.dart';
import 'dialogs/sync_info_dialog.dart';
import 'dialogs/sync_history_dialog.dart';

/// 设置页面（我的页面）
/// 
/// 显示用户信息、功能入口、设置选项等。
/// 
/// 遵循原则：
/// - 单一职责（SRP）：只负责展示设置界面和处理用户交互
/// - 分层约束：UI层不包含业务逻辑，通过Provider调用
/// - 用户体验优先：未登录时显示登录/注册入口，不阻碍功能使用
/// 
/// 调用者：
/// - MainNavigationPage：底部导航栏的"我的"标签
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTransition = ref.watch(pageTransitionProvider);
    final currentDialogAnimation = ref.watch(dialogAnimationProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          authState.when(
            data: (user) {
              if (user != null) {
                // 已登录状态
                return _buildLoggedInUserCard(context, user);
              } else {
                // 未登录状态
                return _buildLoggedOutUserCard(context, ref);
              }
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          
          const Divider(),
          
          // 功能入口
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '功能',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 每日签到入口
          ListTile(
            leading: const Text('✨', style: TextStyle(fontSize: 24)),
            title: const Text('每日签到'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CheckInPage(),
                ),
              );
            },
          ),
          
          // 成就入口
          ListTile(
            leading: const Text('🏆', style: TextStyle(fontSize: 24)),
            title: const Text('我的成就'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AchievementsPage(),
                ),
              );
            },
          ),
          
          // 我的发布入口
          ListTile(
            leading: const Text('🌍', style: TextStyle(fontSize: 24)),
            title: const Text('我的发布'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              NavigationHelper.pushWithTransition(
                context,
                ref,
                const MyPostsPage(),
              );
            },
          ),
          
          // 数据同步区域
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              final syncStatus = ref.watch(syncStatusProvider);
              
              return Column(
                children: [
                  // 手动同步
                  ListTile(
                    leading: const Text('🔄', style: TextStyle(fontSize: 24)),
                    title: Row(
                      children: [
                        const Text('手动同步'),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => SyncInfoDialog.show(context),
                          child: Icon(
                            Icons.help_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: _buildSyncSubtitle(context, syncStatus),
                    trailing: syncStatus.status == SyncStatus.syncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: syncStatus.status == SyncStatus.syncing
                        ? null
                        : () => _handleManualSync(context, ref, authState),
                  ),
                  
                  // 同步历史
                  ListTile(
                    leading: const Text('📋', style: TextStyle(fontSize: 24)),
                    title: const Text('同步历史'),
                    subtitle: const Text('查看历史同步记录'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => SyncHistoryDialog.show(context),
                  ),
                ],
              );
            },
          ),
          
          const Divider(),
          
          // 签到设置
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '签到设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 签到提醒开关
          Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(userSettingsProvider);
              
              return SwitchListTile(
                title: const Text('签到提醒'),
                subtitle: const Text('每天提醒你签到'),
                value: settings.checkInReminderEnabled,
                onChanged: (value) async {
                  await ref.read(userSettingsProvider.notifier).updateCheckInReminderEnabled(value);
                  if (context.mounted) {
                    MessageHelper.showSuccess(
                      context,
                      value ? '签到提醒已开启' : '签到提醒已关闭',
                    );
                  }
                },
              );
            },
          ),
          
          // 签到提醒时间
          Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(userSettingsProvider);
              
              return ListTile(
                title: const Text('提醒时间'),
                subtitle: Text(
                  '${settings.checkInReminderTime.hour.toString().padLeft(2, '0')}:${settings.checkInReminderTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                enabled: settings.checkInReminderEnabled,
                onTap: settings.checkInReminderEnabled
                    ? () => _showTimePickerDialog(context, ref, settings.checkInReminderTime)
                    : null,
              );
            },
          ),
          
          // 签到震动开关
          Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(userSettingsProvider);
              
              return SwitchListTile(
                title: const Text('签到震动'),
                subtitle: const Text('签到时震动反馈'),
                value: settings.checkInVibrationEnabled,
                onChanged: (value) async {
                  await ref.read(userSettingsProvider.notifier).updateCheckInVibrationEnabled(value);
                },
              );
            },
          ),
          
          // 签到粒子特效开关
          Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(userSettingsProvider);
              
              return SwitchListTile(
                title: const Text('签到粒子特效'),
                subtitle: const Text('签到时显示彩色粒子'),
                value: settings.checkInConfettiEnabled,
                onChanged: (value) async {
                  await ref.read(userSettingsProvider.notifier).updateCheckInConfettiEnabled(value);
                },
              );
            },
          ),
          
          const Divider(),
          
          // 页面跳转动画设置
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '页面跳转动画',
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
              onTap: () async {
                await ref.read(userSettingsProvider.notifier).updatePageTransition(type);
                if (context.mounted) {
                  MessageHelper.showSuccess(context, '已切换到：${type.label}');
                }
              },
            );
          }),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '💡 提示：点击记录卡片、编辑按钮等跳转到新页面时生效\n（底部导航栏切换不触发动画）',
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
              onTap: () async {
                await ref.read(userSettingsProvider.notifier).updateDialogAnimation(type);
                if (context.mounted) {
                  MessageHelper.showSuccess(context, '已切换到：${type.label}');
                }
              },
            );
          }),
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
          
          const Divider(),
          
          // 账号管理
          authState.when(
            data: (user) {
              if (user != null) {
                // 已登录，显示账号管理选项
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '账号管理',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 修改密码（邮箱和手机号登录用户都支持）
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('修改密码'),
                      onTap: () => _showUpdatePasswordDialog(context, ref),
                    ),
                    // 更换邮箱（仅已有邮箱的用户）
                    if (user.email != null)
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('更换邮箱'),
                        subtitle: Text(user.email!),
                        onTap: () => _showUpdateEmailDialog(context, ref),
                      ),
                    // 更换手机号（仅已有手机号的用户）
                    if (user.phoneNumber != null)
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('更换手机号'),
                        subtitle: Text(user.phoneNumber!),
                        onTap: () => _showUpdatePhoneDialog(context, ref),
                      ),
                    // 恢复密钥管理（仅邮箱登录用户）
                    if (user.email != null)
                      ListTile(
                        leading: const Icon(Icons.vpn_key_outlined),
                        title: const Text('恢复密钥'),
                        subtitle: const Text('用于找回密码'),
                        onTap: () => _showRecoveryKeyDialog(context, ref),
                      ),
                    // 退出登录
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        '退出登录',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                  ],
                );
              } else {
                // 未登录，不显示账号管理
                return const SizedBox.shrink();
              }
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          
          const Divider(),
          
          // 开发测试
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '开发测试',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('GPS 定位测试'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              NavigationHelper.pushWithTransition(
                context,
                ref,
                const LocationTestPage(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_off_outlined, color: Colors.blue),
            title: const Text('重置发布警告对话框'),
            subtitle: const Text('重新显示"发布到社区"警告对话框'),
            onTap: () => _showResetPublishWarningDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text('重置社区介绍对话框'),
            subtitle: const Text('重新显示"欢迎来到树洞"介绍对话框'),
            onTap: () => _showResetCommunityIntroDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('重置所有成就'),
            subtitle: const Text('清空所有已解锁的成就和进度'),
            onTap: () => _showResetAchievementsDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('重置所有签到记录'),
            subtitle: const Text('清空所有签到数据'),
            onTap: () => _showResetCheckInsDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.orange),
            title: const Text('清空同步历史记录'),
            subtitle: const Text('清空所有同步历史数据'),
            onTap: () => _showClearSyncHistoryDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.blue),
            title: const Text('重置首次启动标记'),
            subtitle: const Text('下次启动将显示欢迎页面'),
            onTap: () => _showResetFirstLaunchDialog(context, ref),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  /// 显示时间选择器对话框
  /// 
  /// 调用者：签到提醒时间 ListTile
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责显示时间选择器
  /// - Fail Fast：参数校验
  void _showTimePickerDialog(BuildContext context, WidgetRef ref, TimeOfDay currentTime) {
    showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    ).then((selectedTime) async {
      if (selectedTime != null && selectedTime != currentTime) {
        await ref.read(userSettingsProvider.notifier).updateCheckInReminderTime(selectedTime);
        if (context.mounted) {
          MessageHelper.showSuccess(
            context,
            '提醒时间已更新为 ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
          );
        }
      }
    });
  }
  
  /// 构建已登录用户卡片
  /// 
  /// 调用者：build()
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责展示已登录用户信息
  /// - 性能优化：使用 const 构造
  Widget _buildLoggedInUserCard(BuildContext context, user) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user.displayName?.substring(0, 1).toUpperCase() ?? 
                user.email?.substring(0, 1).toUpperCase() ?? 
                user.phoneNumber?.substring(user.phoneNumber!.length - 4) ?? 
                '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? user.email ?? user.phoneNumber ?? '用户',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.authProvider == AuthProvider.email 
                        ? '邮箱登录' 
                        : '手机号登录',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建未登录用户卡片
  /// 
  /// 调用者：build()
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责展示未登录状态和登录/注册入口
  /// - 用户体验优先：清晰展示登录的好处，鼓励用户登录
  /// - 分层约束：UI层只负责展示和导航，不包含业务逻辑
  Widget _buildLoggedOutUserCard(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 头像
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person_outline,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // 未登录提示
            const Text(
              '未登录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // 登录好处说明
            Text(
              '登录后可同步数据到云端',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // 登录/注册按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _navigateToLogin(context, ref),
                  child: const Text('登录'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => _navigateToRegister(context, ref),
                  child: const Text('注册'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 导航到登录页
  /// 
  /// 调用者：_buildLoggedOutUserCard()
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责导航
  /// - 使用 NavigationHelper 保持导航一致性
  void _navigateToLogin(BuildContext context, WidgetRef ref) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      const LoginPage(),
    );
  }
  
  /// 导航到注册页
  /// 
  /// 调用者：_buildLoggedOutUserCard()
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责导航
  /// - 使用 NavigationHelper 保持导航一致性
  void _navigateToRegister(BuildContext context, WidgetRef ref) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      const RegisterPage(),
    );
  }
  
  /// 显示退出登录确认对话框
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              // 关闭对话框
              Navigator.of(context).pop();
              
              try {
                // 执行登出
                await ref.read(authProvider.notifier).signOut();
                
                // 注意：不需要手动跳转，main.dart 的 authProvider 监听器会自动处理
              } catch (e) {
                // 显示错误信息
                if (context.mounted) {
                  MessageHelper.showError(context, '退出登录失败：$e');
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
  
  /// 显示修改密码对话框
  void _showUpdatePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool currentPasswordVisible = false;
    bool newPasswordVisible = false;
    bool confirmPasswordVisible = false;
    
    DialogHelper.show(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('修改密码'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: !currentPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '当前密码',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        currentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          currentPasswordVisible = !currentPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: !newPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '新密码',
                    border: const OutlineInputBorder(),
                    helperText: '至少6位',
                    suffixIcon: IconButton(
                      icon: Icon(
                        newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          newPasswordVisible = !newPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !confirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '确认新密码',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          confirmPasswordVisible = !confirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final currentPassword = currentPasswordController.text.trim();
                  final newPassword = newPasswordController.text.trim();
                  final confirmPassword = confirmPasswordController.text.trim();
                  
                  // Fail Fast：验证输入
                  if (currentPassword.isEmpty) {
                    MessageHelper.showError(context, '请输入当前密码');
                    return;
                  }
                  if (newPassword.isEmpty) {
                    MessageHelper.showError(context, '请输入新密码');
                    return;
                  }
                  if (newPassword.length < 6) {
                    MessageHelper.showError(context, '新密码至少需要6位');
                    return;
                  }
                  if (newPassword != confirmPassword) {
                    MessageHelper.showError(context, '两次输入的新密码不一致');
                    return;
                  }
                  if (currentPassword == newPassword) {
                    MessageHelper.showError(context, '新密码不能与当前密码相同');
                    return;
                  }
                  
                  // 先执行操作，成功后再关闭对话框
                  final success = await AsyncActionHelper.execute(
                    context,
                    action: () => ref.read(authProvider.notifier).updatePassword(
                      currentPassword,
                      newPassword,
                    ),
                    successMessage: '密码修改成功',
                    errorMessagePrefix: '修改密码失败',
                  );
                  
                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// 显示更换邮箱对话框
  void _showUpdateEmailDialog(BuildContext context, WidgetRef ref) {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    bool passwordVisible = false;
    
    DialogHelper.show(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('更换邮箱'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '新邮箱',
                    hintText: '请输入新邮箱',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: '当前密码',
                    hintText: '请输入当前密码',
                    border: const OutlineInputBorder(),
                    helperText: '需要验证身份',
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          passwordVisible = !passwordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final newEmail = newEmailController.text.trim();
                  final password = passwordController.text.trim();
                  
                  // Fail Fast：验证输入
                  if (newEmail.isEmpty) {
                    MessageHelper.showError(context, '请输入新邮箱');
                    return;
                  }
                  if (password.isEmpty) {
                    MessageHelper.showError(context, '请输入当前密码');
                    return;
                  }
                  
                  // 先执行操作，成功后再关闭对话框
                  final success = await AsyncActionHelper.execute(
                    context,
                    action: () => ref.read(authProvider.notifier).updateEmail(
                      newEmail,
                      password,
                    ),
                    successMessage: '邮箱更换成功',
                    errorMessagePrefix: '更换邮箱失败',
                  );
                  
                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// 显示恢复密钥对话框
  /// 
  /// 调用者：恢复密钥 ListTile
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责显示和管理恢复密钥
  /// - Fail Fast：参数验证
  /// - 用户体验优先：提供查看和重新生成功能
  void _showRecoveryKeyDialog(BuildContext context, WidgetRef ref) async {
    String? recoveryKey;
    bool isLoading = true;
    bool isInitialLoad = true;
    
    // 先获取当前恢复密钥
    try {
      recoveryKey = await ref.read(authProvider.notifier).getRecoveryKey();
      isLoading = false;
      isInitialLoad = false;
    } catch (e) {
      isLoading = false;
      isInitialLoad = false;
      if (context.mounted) {
        MessageHelper.showError(context, '获取恢复密钥失败：${AuthErrorHelper.extractErrorMessage(e)}');
      }
    }
    
    if (!context.mounted) return;
    
    DialogHelper.show(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('恢复密钥'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '恢复密钥用于在忘记密码时重置密码。',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  '⚠️ 请妥善保管，丢失后无法找回！',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoading && isInitialLoad) ...[
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ] else if (recoveryKey != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SelectableText(
                      recoveryKey!,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: recoveryKey!));
                          if (context.mounted) {
                            MessageHelper.showSuccess(context, '已复制到剪贴板');
                          }
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('复制'),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    '尚未设置恢复密钥。',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '点击"生成恢复密钥"按钮生成新的恢复密钥。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
              if (isLoading && !isInitialLoad)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });
                    
                    try {
                      final key = await ref.read(authProvider.notifier).generateRecoveryKey();
                      setState(() {
                        recoveryKey = key;
                        isLoading = false;
                      });
                      if (context.mounted) {
                        MessageHelper.showSuccess(context, '恢复密钥已生成');
                      }
                    } catch (e) {
                      setState(() {
                        isLoading = false;
                      });
                      if (context.mounted) {
                        MessageHelper.showError(context, '生成失败：${AuthErrorHelper.extractErrorMessage(e)}');
                      }
                    }
                  },
                  child: Text(recoveryKey == null ? '生成恢复密钥' : '重新生成'),
                ),
            ],
          );
        },
      ),
    );
  }
  
  /// 显示更换手机号对话框
  void _showUpdatePhoneDialog(BuildContext context, WidgetRef ref) {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String countryCode = '+86';
    bool passwordVisible = false;
    
    DialogHelper.show(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('更换手机号'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthTextField(
                  type: AuthTextFieldType.phone,
                  controller: phoneController,
                  label: '新手机号',
                  hint: '请输入新手机号',
                  countryCode: countryCode,
                  onCountryCodeChanged: (code) {
                    setState(() {
                      countryCode = code;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: '当前密码',
                    hintText: '请输入当前密码',
                    border: const OutlineInputBorder(),
                    helperText: '需要验证身份',
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          passwordVisible = !passwordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final phone = phoneController.text.trim();
                  final password = passwordController.text.trim();
                  
                  // Fail Fast：验证输入
                  if (phone.isEmpty) {
                    MessageHelper.showError(context, '请输入新手机号');
                    return;
                  }
                  if (password.isEmpty) {
                    MessageHelper.showError(context, '请输入当前密码');
                    return;
                  }
                  
                  final fullPhone = PhoneHelper.formatWithCountryCode(countryCode, phone);
                  
                  // 先执行操作，成功后再关闭对话框
                  final success = await AsyncActionHelper.execute(
                    context,
                    action: () => ref.read(authProvider.notifier).updatePhoneNumber(
                      fullPhone,
                      password,
                    ),
                    successMessage: '手机号更换成功',
                    errorMessagePrefix: '更换手机号失败',
                  );
                  
                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 显示重置成就确认对话框
  void _showResetAchievementsDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重置所有成就'),
        content: const Text('确定要重置所有成就吗？\n\n这将清空所有已解锁的成就和进度，此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              
              final success = await AsyncActionHelper.execute(
                context,
                action: () async {
                  await ref.read(achievementRepositoryProvider).resetAllAchievements();
                },
                successMessage: '所有成就已重置',
                errorMessagePrefix: '重置失败',
              );
              
              if (success) {
                // 刷新成就列表
                ref.invalidate(achievementsProvider);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  /// 显示重置签到记录确认对话框
  void _showResetCheckInsDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置所有签到记录'),
        content: const Text('确定要重置所有签到记录吗？\n\n这将清空所有签到数据，此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await AsyncActionHelper.execute(
                context,
                action: () => ref.read(checkInProvider.notifier).resetAllCheckIns(),
                successMessage: '所有签到记录已重置',
                errorMessagePrefix: '重置失败',
              );
              
              if (success) {
                // 刷新签到状态
                ref.invalidate(checkInProvider);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  /// 显示清空同步历史记录确认对话框
  void _showClearSyncHistoryDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空同步历史记录'),
        content: const Text('确定要清空所有同步历史记录吗？\n\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              await AsyncActionHelper.execute(
                context,
                action: () async {
                  await ref.read(storageServiceProvider).clearAllSyncHistories();
                },
                successMessage: '同步历史记录已清空',
                errorMessagePrefix: '清空失败',
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('确定清空'),
          ),
        ],
      ),
    );
  }

  /// 显示重置首次启动标记确认对话框
  void _showResetFirstLaunchDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置首次启动标记'),
        content: const Text('确定要重置首次启动标记吗？\n\n将立即跳转到欢迎页面。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await AsyncActionHelper.execute(
                context,
                action: () => ref.read(firstLaunchProvider.notifier).reset(),
                successMessage: '首次启动标记已重置',
                errorMessagePrefix: '重置失败',
              );
              
              if (success && context.mounted) {
                // 跳转到欢迎页面
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomePage()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  /// 显示重置发布警告对话框确认对话框
  void _showResetPublishWarningDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置发布警告对话框'),
        content: const Text('确定要重置"发布到社区"警告对话框的"不再提示"设置吗？\n\n重置后，下次发布时将重新显示警告对话框和倒计时。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              await AsyncActionHelper.execute(
                context,
                action: () async {
                  await ref.read(userSettingsProvider.notifier).resetPublishWarning();
                },
                successMessage: '发布警告对话框已重置',
                errorMessagePrefix: '重置失败',
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }

  /// 显示重置社区介绍对话框确认对话框
  void _showResetCommunityIntroDialog(BuildContext context, WidgetRef ref) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置社区介绍对话框'),
        content: const Text('确定要重置社区介绍对话框吗？\n\n重置后，下次进入树洞页面时将重新显示"欢迎来到树洞"介绍对话框。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              await AsyncActionHelper.execute(
                context,
                action: () async {
                  await ref.read(userSettingsProvider.notifier).markCommunityIntroSeen(false);
                },
                successMessage: '社区介绍对话框已重置',
                errorMessagePrefix: '重置失败',
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );
  }
  
  /// 构建同步状态副标题
  /// 
  /// 调用者：手动同步 ListTile
  /// 
  /// 遵循原则：
  /// - 单一职责（SRP）：只负责构建副标题文本
  /// - DRY：复用 DateTimeHelper.formatRelativeTime
  Widget? _buildSyncSubtitle(BuildContext context, SyncStatusInfo syncStatus) {
    if (syncStatus.status == SyncStatus.syncing) {
      return const Text('同步中...');
    }
    
    if (syncStatus.status == SyncStatus.success) {
      return Text(
        '同步成功',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    
    if (syncStatus.status == SyncStatus.error) {
      return Text(
        '同步失败：${syncStatus.errorMessage}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    // 空闲状态，显示上次同步时间
    if (syncStatus.lastManualSyncTime != null) {
      return Text(
        '上次同步：${DateTimeHelper.formatRelativeTime(syncStatus.lastManualSyncTime!)}',
      );
    }
    
    return const Text('同步本地数据到云端');
  }
  
  /// 处理手动同步
  /// 
  /// 调用者：手动同步 ListTile
  /// 
  /// 遵循原则：
  /// - 单一职责（SRP）：只负责处理手动同步逻辑
  /// - Fail Fast：未登录立即提示
  void _handleManualSync(BuildContext context, WidgetRef ref, AsyncValue authState) {
    authState.when(
      data: (user) {
        if (user == null) {
          // 未登录，提示用户登录
          MessageHelper.showError(context, '请先登录后再同步数据');
        } else {
          // 已登录，显示同步对话框
          ManualSyncDialog.show(context, ref);
        }
      },
      loading: () {
        MessageHelper.showError(context, '正在加载用户信息...');
      },
      error: (error, stackTrace) {
        MessageHelper.showError(context, '获取用户信息失败');
      },
    );
  }
}

