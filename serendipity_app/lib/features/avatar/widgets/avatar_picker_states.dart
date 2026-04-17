import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class EmptyAssetsView extends StatelessWidget {
  const EmptyAssetsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text(
              '当前相册没有可用图片',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class PermissionDeniedView extends StatelessWidget {
  final PermissionState permissionState;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onRetry;

  const PermissionDeniedView({
    super.key,
    required this.permissionState,
    required this.onOpenSettings,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final message = permissionState == PermissionState.limited
        ? '当前只授予了部分图片访问权限，请在系统设置里补充选择头像图片。'
        : '需要相册权限才能在应用内选择头像图片。';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              '无法访问相册',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: onOpenSettings,
                  child: const Text('打开系统设置'),
                ),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('重新授权'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

