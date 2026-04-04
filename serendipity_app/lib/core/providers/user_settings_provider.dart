import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_settings.dart';
import '../../models/user.dart';
import '../../models/enums.dart';
import '../services/i_storage_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';
import 'membership_provider.dart';
import 'message_provider.dart';
import 'records_provider.dart' show syncCompletedProvider;

/// NotificationService Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in ProviderScope',
  );
});

/// 用户设置状态管理
///
/// 负责用户设置的读取、更新和持久化
///
/// 调用者：
/// - UI 层：读取和修改用户设置
/// - AuthProvider：用户登录/登出时刷新设置
///
/// 设计原则：
/// - 单一职责：只负责用户设置的状态管理
/// - 依赖注入：通过构造函数注入依赖
/// - Fail Fast：操作失败立即抛出异常
/// - 保证非空：state 始终为非空，简化 UI 层逻辑
///
/// 云端同步：
/// - 登录时：SyncService 自动从云端下载设置到本地
/// - 修改时：自动上传到云端（如果用户已登录）
/// - 登出时：保留本地设置（下次登录会被覆盖）
class UserSettingsNotifier extends StateNotifier<UserSettings> {
  final IStorageService _storageService;
  final NotificationService _notificationService;
  final Ref _ref;
  int _hydrationDepth = 0;
  UserSettings? _lastUploadedSettings;
  bool _hasHydratedOnce = false;

  UserSettingsNotifier(
    this._storageService,
    this._notificationService,
    this._ref,
  ) : super(_createDefaultSettings()) {
    _hydrateSettings();
    _listenToAuthChanges();
    _listenToSyncCompleted();
    _listenToMembershipChanges();
  }

  /// 创建默认设置（访客模式）
  /// 调度纪念日提醒本地通知
  /// 单一职责：只负责创建默认配置
  static UserSettings _createDefaultSettings() {
    final now = DateTime.now();
    return UserSettings(
      id: 'default',
      userId: 'guest',
      theme: ThemeOption.system,
      pageTransition: PageTransitionType.random,
      dialogAnimation: DialogAnimationType.random,
      achievementNotification: true,
      anniversaryReminder: true,
      checkInReminderEnabled: true,
      checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
      checkInVibrationEnabled: true,
      checkInConfettiEnabled: true,
      hidePublishWarning: false,
      hasSeenPublishWarning: false,
      hasSeenCommunityIntro: false,
      hasSeenFavoritesIntro: false,
      themeUpdatedAt: now,
      notificationsUpdatedAt: now,
      checkInUpdatedAt: now,
      communityUpdatedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 监听会员状态变化，会员失效时自动降级会员专属主题
  ///
  /// 调用者：构造函数
  ///
  /// 设计原则：
  /// - 单一职责：UserSettingsNotifier 负责保证 theme 与会员状态的一致性
  /// - 用户体验优先：会员过期/重置后自动降级，不让用户停留在无权限主题
  void _listenToMembershipChanges() {
    _ref.listen<AsyncValue<MembershipInfo>>(membershipProvider, (previous, next) {
      final prevIsPremium = previous?.valueOrNull?.isPremium ?? false;
      final nextIsPremium = next.valueOrNull?.isPremium ?? false;

      // 只在 premium → 非 premium 时触发降级
      if (prevIsPremium && !nextIsPremium) {
        _downgradeThemeIfNeeded();
      }
    });
  }

  /// 如果当前主题是会员专属主题，降级到跟随系统
  ///
  /// 调用者：_listenToMembershipChanges()
  Future<void> _downgradeThemeIfNeeded() async {
    if (!state.theme.isPremium) return;

    final now = DateTime.now();
    final updated = state.copyWith(
      theme: ThemeOption.system,
      themeUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 通知用户主题已自动降级
    _ref.read(messageProvider.notifier).showInfo('会员过期，主题自动恢复到跟随系统');

    await _uploadToCloud(updated);
  }

  /// 监听同步完成信号，同步完成后重新加载本地设置
  ///
  /// 调用者：构造函数
  void _listenToSyncCompleted() {
    _ref.listen<int>(syncCompletedProvider, (previous, next) {
      if (previous != null && next > previous) {
        unawaited(_hydrateSettings());
      }
    });
  }

  /// 监听用户登录/登出状态变化
  ///
  /// 用户登录后：重新加载设置（已由 SyncService 从云端同步）
  /// 用户登出后：保留本地设置（继续使用，但不再同步到云端）
  void _listenToAuthChanges() {
    _ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      next.whenData((user) {
        unawaited(_handleAuthChanged(user));
      });
    });
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (_isLoggedInUser(user)) {
      await _notificationService.cancelCheckInReminder();
      return;
    }

    if (_hasHydratedOnce) {
      return;
    }

    await _hydrateSettings();
  }

  /// 加载用户设置
  ///
  /// 单一职责：只负责从存储恢复状态，不触发云端回写
  Future<void> _hydrateSettings() async {
    await _runHydration(() async {
      final settings = _storageService.getUserSettings();
      if (settings == null) {
        return;
      }

      final user = await _readResolvedAuthUser();
      final isLoggedIn = _isLoggedInUser(user);
      await _applyHydratedSettings(settings, isLoggedIn: isLoggedIn);
    });
  }

  Future<void> _runHydration(Future<void> Function() action) async {
    _hydrationDepth++;
    try {
      await action();
    } finally {
      _hydrationDepth--;
    }
  }

  bool get _isHydrating => _hydrationDepth > 0;

  Future<User?> _readResolvedAuthUser() async {
    final authState = _ref.read(authProvider);
    if (authState.hasValue) {
      return authState.value;
    }

    return await _ref.read(authProvider.future);
  }

  Future<void> _applyHydratedSettings(UserSettings settings, {required bool isLoggedIn}) async {
    _hasHydratedOnce = true;
    state = settings;
    _lastUploadedSettings = settings;

    if (settings.checkInReminderEnabled && !isLoggedIn) {
      await _scheduleCheckInReminder(settings.checkInReminderTime);
    } else {
      await _notificationService.cancelCheckInReminder();
    }

    if (settings.anniversaryReminder) {
      await _scheduleAnniversaryReminders();
    } else {
      await _notificationService.cancelAnniversaryReminders();
    }
  }

  ///
  /// 从当前用户的全量记录中筛选邂逅记录，交给 NotificationService 调度。
  /// 权限检查由 updateAnniversaryReminder 负责，此处不重复校验。
  ///
  /// 调用者：
  /// - _loadSettings()：App 启动/同步完成后重新调度
  /// - updateAnniversaryReminder()：用户开启纪念日提醒时调度
  Future<void> _scheduleAnniversaryReminders() async {
    try {
      final granted = await _notificationService.requestPermission();
      if (!granted) return;

      final records = _storageService.getAllRecords();
      await _notificationService.scheduleAnniversaryReminders(records);
    } catch (e) {
      // 调度失败静默处理，不影响用户体验
    }
  }

  /// 上传设置到云端（如果用户已登录）
  ///
  /// 调用者：所有设置更新方法
  ///
  /// 注意：上传失败时回滚本地状态，避免数据不一致
  ///
  /// 架构说明：通过 SyncService 上传，遵循 Provider → SyncService → Repository 分层约束
  Future<void> _uploadToCloud(UserSettings settings) async {
    if (_isHydrating || _lastUploadedSettings == settings) {
      return;
    }

    try {
      // 检查用户是否登录
      final authState = _ref.read(authProvider);
      final user = authState.value;

      if (user == null || user.id.isEmpty || user.id == 'guest') {
        // 用户未登录，跳过云端上传
        return;
      }

      // 通过 SyncService 上传，遵循 Provider → SyncService → Repository 分层约束
      final syncService = _ref.read(syncServiceProvider);
      final serverSettings = await syncService.uploadSettings(settings);

      // 用服务端的 updatedAt 更新本地，确保下次同步时时间戳对齐
      await _storageService.saveUserSettings(serverSettings);
      state = serverSettings;
      _lastUploadedSettings = serverSettings;
    } catch (e) {
      // 上传失败，回滚本地状态到上一个已知的好状态
      // 重新从存储加载，确保本地和存储一致
      final savedSettings = _storageService.getUserSettings();
      if (savedSettings != null) {
        state = savedSettings;
        _lastUploadedSettings = savedSettings;
      }
      // 静默失败，不影响用户体验
      // 用户可以稍后手动同步或重新修改设置
    }
  }

  /// 更新主题
  Future<void> updateTheme(ThemeOption theme) async {
    final membershipInfo = _ref.read(membershipProvider).valueOrNull;
    if (membershipInfo == null) {
      throw StateError('Membership info is not ready');
    }
    if (!membershipInfo.canUseTheme(theme)) {
      throw StateError('Premium membership required for theme ${theme.label}');
    }

    final now = DateTime.now();
    final updated = state.copyWith(
      theme: theme,
      themeUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 更新纪念日提醒开关
  ///
  /// 调用者：
  /// - ProfilePage（纪念日提醒开关）
  ///
  /// 注意：调用前必须由 UI 层完成会员权限校验，
  /// 非会员不应能触发此方法。
  Future<void> updateAnniversaryReminder(bool enabled) async {
    final now = DateTime.now();
    final updated = state.copyWith(
      anniversaryReminder: enabled,
      notificationsUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    if (enabled) {
      await _scheduleAnniversaryReminders();
    } else {
      await _notificationService.cancelAnniversaryReminders();
    }

    await _uploadToCloud(updated);
  }

  /// 更新页面切换动画
  Future<void> updatePageTransition(PageTransitionType type) async {
    final now = DateTime.now();
    final updated = state.copyWith(
      pageTransition: type,
      themeUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 更新对话框动画
  Future<void> updateDialogAnimation(DialogAnimationType type) async {
    final now = DateTime.now();
    final updated = state.copyWith(
      dialogAnimation: type,
      themeUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 更新签到提醒开关
  ///
  /// [enabled] 是否启用签到提醒
  ///
  /// 如果启用，会调度通知；如果禁用，会取消通知
  Future<void> updateCheckInReminderEnabled(bool enabled) async {
    final now = DateTime.now();
    final updated = state.copyWith(
      checkInReminderEnabled: enabled,
      notificationsUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 根据开关状态调度或取消通知
    if (enabled) {
      await _scheduleCheckInReminder(updated.checkInReminderTime);
    } else {
      await _notificationService.cancelCheckInReminder();
    }

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 更新签到提醒时间
  ///
  /// [time] 提醒时间，不能为 null
  ///
  /// 如果签到提醒已启用，会重新调度通知
  Future<void> updateCheckInReminderTime(TimeOfDay time) async {
    // Fail Fast：参数校验
    ArgumentError.checkNotNull(time, 'time');

    final now = DateTime.now();
    final updated = state.copyWith(
      checkInReminderTime: time,
      notificationsUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 如果签到提醒已启用，重新调度通知
    if (updated.checkInReminderEnabled) {
      await _scheduleCheckInReminder(time);
    }

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 更新签到震动开关
  Future<void> updateCheckInVibrationEnabled(bool enabled) async {
    final now = DateTime.now();
    final updated = state.copyWith(
      checkInVibrationEnabled: enabled,
      checkInUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 更新签到粒子特效开关
  Future<void> updateCheckInConfettiEnabled(bool enabled) async {
    final now = DateTime.now();
    final updated = state.copyWith(
      checkInConfettiEnabled: enabled,
      checkInUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 更新发布警告隐藏开关
  ///
  /// [hide] 是否隐藏发布警告对话框
  ///
  /// 调用者：
  /// - PublishWarningDialog（用户勾选"不再提示"时）
  Future<void> updateHidePublishWarning(bool hide) async {
    final now = DateTime.now();
    final updated = state.copyWith(
      hidePublishWarning: hide,
      communityUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 重置发布警告对话框（原子操作）
  ///
  /// 同时重置 hidePublishWarning 和 hasSeenPublishWarning，只上传一次
  ///
  /// 调用者：
  /// - SettingsPage（重置对话框提醒时）
  Future<void> resetPublishWarning() async {
    final now = DateTime.now();
    final updated = state.copyWith(
      hidePublishWarning: false,
      hasSeenPublishWarning: false,
      communityUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 标记用户已看过发布警告
  ///
  /// [seen] 是否已看过（默认 true）
  ///
  /// 调用者：
  /// - PublishWarningDialog（倒计时结束时）
  /// - SettingsPage（重置对话框提醒时）
  Future<void> markPublishWarningSeen([bool seen = true]) async {
    final now = DateTime.now();
    final updated = state.copyWith(
      hasSeenPublishWarning: seen,
      communityUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 标记用户已看过社区介绍
  ///
  /// [seen] 是否已看过（默认 true）
  ///
  /// 调用者：
  /// - CommunityIntroDialog（用户点击"我知道了"时）
  Future<void> markCommunityIntroSeen([bool seen = true]) async {
    final now = DateTime.now();
    final updated = state.copyWith(
      hasSeenCommunityIntro: seen,
      communityUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 标记用户已看过收藏页介绍
  ///
  /// [seen] 是否已看过（默认 true）
  ///
  /// 调用者：
  /// - FavoritesIntroDialog（用户点击"我知道了"时）
  Future<void> markFavoritesIntroSeen([bool seen = true]) async {
    final now = DateTime.now();
    final updated = state.copyWith(
      hasSeenFavoritesIntro: seen,
      communityUpdatedAt: now,
      updatedAt: now,
    );

    await _storageService.saveUserSettings(updated);
    state = updated;

    // 上传到云端
    await _uploadToCloud(updated);
  }

  Future<void> refreshGuestCheckInReminder() async {
    if (state.checkInReminderEnabled) {
      await _scheduleCheckInReminder(state.checkInReminderTime);
    } else {
      await _notificationService.cancelCheckInReminder();
    }
  }

  /// 调度签到提醒通知
  ///
  /// [time] 提醒时间
  Future<void> _scheduleCheckInReminder(TimeOfDay time) async {
    try {
      final user = await _readResolvedAuthUser();
      if (_isLoggedInUser(user)) {
        await _notificationService.cancelCheckInReminder();
        return;
      }

      final granted = await _notificationService.requestPermission();
      if (!granted) {
        return;
      }

      await _notificationService.scheduleCheckInReminder(time);
    } catch (e) {
      // 调度失败，静默失败（不影响用户体验）
      // 生产环境应记录错误日志
    }
  }

  bool _isLoggedInUser(User? user) {
    return user != null && user.id.isNotEmpty && user.id != 'guest';
  }
}

/// 用户设置 Provider
final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
      final storageService = ref.read(storageServiceProvider);
      final notificationService = ref.read(notificationServiceProvider);
      return UserSettingsNotifier(storageService, notificationService, ref);
    });
