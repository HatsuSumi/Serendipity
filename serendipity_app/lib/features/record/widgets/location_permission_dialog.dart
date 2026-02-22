import 'package:flutter/material.dart';

/// 定位权限引导对话框
/// 
/// 当用户拒绝定位权限时显示，引导用户前往系统设置开启权限。
/// 
/// 调用者：
/// - CreateRecordPage：定位权限被拒绝时显示
/// 
/// 设计原则：
/// - 单一职责：只负责权限引导UI
/// - 无业务逻辑：不包含权限请求逻辑
/// - 灵活性：支持多种操作回调
class LocationPermissionDialog extends StatelessWidget {
  /// 点击"去设置"按钮的回调
  final VoidCallback? onOpenSettings;
  
  /// 点击"重新请求"按钮的回调（可选）
  final VoidCallback? onRequestAgain;
  
  /// 点击"稍后再说"按钮的回调（可选）
  final VoidCallback? onCancel;
  
  const LocationPermissionDialog({
    super.key,
    this.onOpenSettings,
    this.onRequestAgain,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.location_off,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '需要定位权限',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '为了自动记录错过的地点，Serendipity 需要获取您的位置信息。',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 我们如何使用您的位置：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '仅在创建记录时获取一次位置\n'
                    '不会后台持续定位\n'
                    '位置信息仅保存在您的设备上\n'
                    '您可以随时选择"忽略GPS定位"',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '请在系统设置中开启定位权限：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '设置 → Serendipity → 位置 → 使用应用期间',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // 稍后再说按钮
        if (onCancel != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel!();
            },
            child: const Text('稍后再说'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后再说'),
          ),
        
        // 重新请求按钮（可选）
        if (onRequestAgain != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRequestAgain!();
            },
            child: const Text('重新请求'),
          ),
        
        // 去设置按钮
        if (onOpenSettings != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onOpenSettings!();
            },
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('去设置'),
          ),
      ],
    );
  }
}

