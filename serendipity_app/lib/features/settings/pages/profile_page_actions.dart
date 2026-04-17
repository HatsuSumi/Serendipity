import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../core/providers/sync_status_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/utils/async_action_helper.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/message_helper.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../models/user.dart';
import '../../avatar/avatar_picker_page.dart';
import '../dialogs/edit_display_name_dialog.dart';
import '../dialogs/manual_sync_dialog.dart';

class ProfilePageActions {
  const ProfilePageActions._();

  static Future<void> handleAvatarTap(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final userActions = ref.read(userActionsProvider.notifier);
    final selectedAsset = await NavigationHelper.pushWithTransition<File>(
      context,
      ref,
      const AvatarPickerPage(),
    );
    if (selectedAsset == null) return;
    if (!context.mounted) return;

    final colorScheme = Theme.of(context).colorScheme;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: selectedAsset.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪头像',
          toolbarColor: colorScheme.surface,
          toolbarWidgetColor: colorScheme.onSurface,
          statusBarLight: colorScheme.brightness == Brightness.light,
          activeControlsWidgetColor: colorScheme.primary,
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(
          title: '裁剪头像',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (croppedFile == null) return;
    if (!context.mounted) return;

    await AsyncActionHelper.execute(
      context,
      action: () => userActions.uploadAvatar(File(croppedFile.path)),
      successMessage: '头像已更新',
      errorMessagePrefix: '头像上传失败',
    );
  }

  static Future<void> handleEditDisplayName(
    BuildContext context,
    WidgetRef ref,
    User user,
  ) async {
    final userActions = ref.read(userActionsProvider.notifier);
    var newName = user.displayName ?? '';
    final confirmed = await DialogHelper.show<bool>(
      context: context,
      builder: (ctx) => EditDisplayNameDialog(
        initialName: newName,
        onChanged: (value) => newName = value,
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    await AsyncActionHelper.execute(
      context,
      action: () => userActions.updateDisplayName(newName),
      successMessage: '昵称已更新',
      errorMessagePrefix: '昵称更新失败',
    );
  }

  static Widget? buildSyncSubtitle(
    BuildContext context,
    SyncStatusInfo syncStatus,
  ) {
    if (syncStatus.status == SyncStatus.syncing) {
      return const Text('同步中...');
    }
    if (syncStatus.status == SyncStatus.success) {
      return Text(
        '同步成功',
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      );
    }
    if (syncStatus.status == SyncStatus.error) {
      return Text(
        '同步失败：${syncStatus.errorMessage}',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (syncStatus.lastManualSyncTime != null) {
      return Text(
        '上次同步：${DateTimeHelper.formatRelativeTime(syncStatus.lastManualSyncTime!)}',
      );
    }
    return const Text('同步本地数据到云端');
  }

  static void handleManualSync(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<User?> authState,
  ) {
    authState.when(
      data: (user) {
        if (user == null) {
          MessageHelper.showError(context, '请先登录后再同步数据');
        } else {
          ManualSyncDialog.show(context, ref);
        }
      },
      loading: () => MessageHelper.showError(context, '正在加载用户信息...'),
      error: (_, error) => MessageHelper.showError(context, '获取用户信息失败'),
    );
  }
}

