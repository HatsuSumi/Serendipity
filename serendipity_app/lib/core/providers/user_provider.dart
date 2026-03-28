import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/server_config.dart';
import '../config/app_config.dart';
import 'auth_provider.dart';

/// 用户资料操作 Provider
///
/// 职责：
/// - 更新用户昵称（PUT /users/me）
/// - 上传头像（POST /users/avatar）
///
/// 调用者：
/// - ProfilePage：用户信息卡片的编辑按钮
///
/// 设计说明：
/// - 操作成功后 invalidate authProvider，触发重建，stream 重新拉取最新用户
/// - 不直接操作 authProvider 的 state，避免 StreamNotifier 断言问题
class UserActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// 更新用户昵称
  ///
  /// 调用者：ProfilePage 昵称编辑弹窗确认按钮
  ///
  /// Fail Fast：
  /// - displayName 为空立即抛异常
  /// - 仅 customServer 模式支持，test 模式抛 UnsupportedError
  Future<void> updateDisplayName(String displayName) async {
    if (displayName.trim().isEmpty) {
      throw ArgumentError('昵称不能为空');
    }
    if (AppConfig.serverType != ServerType.customServer) {
      throw UnsupportedError('当前模式不支持此操作');
    }

    final httpClient = ref.read(httpClientServiceProvider);
    final repository = ref.read(authRepositoryProvider);
    await httpClient.put(
      ServerConfig.usersMe,
      body: {'displayName': displayName.trim()},
    );
    // 清除缓存后 invalidate，让 authProvider 重建并重新拉取最新用户
    repository.invalidateUserCache();
    ref.invalidate(authProvider);
  }

  /// 上传头像
  ///
  /// 调用者：ProfilePage 头像点击 → ImagePicker → 确认上传
  ///
  /// Fail Fast：
  /// - file 不存在立即抛异常
  /// - 仅 customServer 模式支持，test 模式抛 UnsupportedError
  Future<void> uploadAvatar(File file) async {
    if (!file.existsSync()) {
      throw ArgumentError('图片文件不存在');
    }
    if (AppConfig.serverType != ServerType.customServer) {
      throw UnsupportedError('当前模式不支持此操作');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw ArgumentError('不支持的图片格式：$ext'),
    };

    final httpClient = ref.read(httpClientServiceProvider);
    final repository = ref.read(authRepositoryProvider);
    await httpClient.postMultipart(
      ServerConfig.usersAvatar,
      fieldName: 'avatar',
      file: file,
      mimeType: mimeType,
    );
    // 清除缓存后 invalidate，让 authProvider 重建并重新拉取最新用户
    repository.invalidateUserCache();
    ref.invalidate(authProvider);
  }
}

final userActionsProvider =
    AsyncNotifierProvider<UserActionsNotifier, void>(UserActionsNotifier.new);
