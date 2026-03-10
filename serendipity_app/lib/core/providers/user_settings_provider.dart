import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_settings.dart';
import '../../models/user.dart';
import '../../models/enums.dart';
import 'records_provider.dart';
import '../services/i_storage_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';
import 'check_in_provider.dart' show checkInRepositoryProvider;

/// NotificationService Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final checkInRepository = ref.read(checkInRepositoryProvider);
  return NotificationService(checkInRepository);
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

  UserSettingsNotifier(
    this._storageService,
    this._notificationService,
    this._ref,
  ) : super(_createDefaultSettings()) {
    _loadSettings();
    _listenToAuthChanges();
    _listenToSyncCompleted();
  }

  /// 创建默认设置（访客模式）
  /// 
  /// 单一职责：只负责创建默认配置
  static UserSettings _createDefaultSettings() {
    return UserSettings(
      id: 'default',
      userId: 'guest',
      theme: ThemeOption.system,
      pageTransition: PageTransitionType.random,
      dialogAnimation: DialogAnimationType.random,
      cloudSyncEnabled: false,
      biometricLockEnabled: false,
      passwordLockEnabled: false,
      hiddenRecordIds: [],
      achievementNotification: true,
      anniversaryReminder: true,
      checkInReminderEnabled: true,
      checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
      checkInVibrationEnabled: true,
      checkInConfettiEnabled: true,
      autoPublishToCommunity: false,
      hidePublishWarning: false,
      hasSeenPublishWarning: false,
      hasSeenCommunityIntro: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 监听同步完成信号，同步完成后重新加载本地设置
  /// 
  /// 调用者：构造函数
  void _listenToSyncCompleted() {
    _ref.listen<int>(
      syncCompletedProvider,
      (previous, next) {
        if (previous != null && next > previous) {
          _loadSettings();
        }
      },
    );
  }

  /// 监听用户登录/登出状态变化
  /// 
  /// 用户登录后：重新加载设置（已由 SyncService 从云端同步）
  /// 用户登出后：保留本地设置（继续使用，但不再同步到云端）
  void _listenToAuthChanges() {
    _ref.listen<AsyncValue<User?>>(
      authProvider,
      (previous, next) {
        next.whenData((user) {
          if (user != null) {
            // 用户登录，重新加载设置
            _loadSettings();
          }
          // 用户登出时不做任何操作，保留本地设置
        });
      },
    );
  }

  /// 加载用户设置
  /// 
  /// 单一职责：只负责从存储加载，不负责创建默认值
  /// 
  /// 注意：
  /// - 登录后由 SyncService 自动从云端同步到本地
  /// - 这里只需要从本地存储读取即可
  Future<void> _loadSettings() async {
    final settings = _storageService.getUserSettings();
    
    if (settings != null) {
      state = settings;
      
      // 如果启用了签到提醒，调度通知
      if (settings.checkInReminderEnabled) {
        await _scheduleCheckInReminder(settings.checkInReminderTime);
      }
    }
    // 如果本地没有设置，保持当前 state（默认设置或之前的设置）
  }

  /// 上传设置到云端（如果用户已登录）
  /// 
  /// 调用者：所有设置更新方法
  /// 
  /// 注意：上传失败不影响本地保存，静默失败
  Future<void> _uploadToCloud(UserSettings settings) async {
    try {
      // 检查用户是否登录
      final authState = _ref.read(authProvider);
      final user = authState.value;
      
      if (user == null || user.id.isEmpty || user.id == 'guest') {
        // 用户未登录，跳过云端上传
        return;
      }
      
      // 上传到云端，获取服务端返回的最新设置（含服务端生成的 updatedAt）
      final remoteRepository = _ref.read(remoteDataRepositoryProvider);
      final serverSettings = await remoteRepository.uploadSettings(settings);
      
      // 用服务端的 updatedAt 更新本地，确保下次同步时时间戳对齐
      await _storageService.saveUserSettings(serverSettings);
      state = serverSettings;
    } catch (e) {
      // 上传失败，静默失败（不影响用户体验）
    }
  }

  /// 更新主题
  Future<void> updateTheme(ThemeOption theme) async {
    final updated = state.copyWith(
      theme: theme,
      updatedAt: DateTime.now(),
    );

    await _storageService.saveUserSettings(updated);
    state = updated;
    
    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 更新页面切换动画
  Future<void> updatePageTransition(PageTransitionType type) async {
    final updated = state.copyWith(
      pageTransition: type,
      updatedAt: DateTime.now(),
    );

    await _storageService.saveUserSettings(updated);
    state = updated;
    
    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 更新对话框动画
  Future<void> updateDialogAnimation(DialogAnimationType type) async {
    final updated = state.copyWith(
      dialogAnimation: type,
      updatedAt: DateTime.now(),
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
    final updated = state.copyWith(
      checkInReminderEnabled: enabled,
      updatedAt: DateTime.now(),
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

    final updated = state.copyWith(
      checkInReminderTime: time,
      updatedAt: DateTime.now(),
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
    final updated = state.copyWith(
      checkInVibrationEnabled: enabled,
      updatedAt: DateTime.now(),
    );

    await _storageService.saveUserSettings(updated);
    state = updated;
    
    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 更新签到粒子特效开关
  Future<void> updateCheckInConfettiEnabled(bool enabled) async {
    final updated = state.copyWith(
      checkInConfettiEnabled: enabled,
      updatedAt: DateTime.now(),
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
    final updated = state.copyWith(
      hidePublishWarning: hide,
      updatedAt: DateTime.now(),
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
    final updated = state.copyWith(
      hidePublishWarning: false,
      hasSeenPublishWarning: false,
      updatedAt: DateTime.now(),
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
    final updated = state.copyWith(
      hasSeenPublishWarning: seen,
      updatedAt: DateTime.now(),
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
    final updated = state.copyWith(
      hasSeenCommunityIntro: seen,
      updatedAt: DateTime.now(),
    );

    await _storageService.saveUserSettings(updated);
    state = updated;
    
    // 上传到云端
    await _uploadToCloud(updated);
  }

  /// 调度签到提醒通知
  /// 
  /// [time] 提醒时间
  Future<void> _scheduleCheckInReminder(TimeOfDay time) async {
    try {
      // 请求通知权限
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        // 权限被拒绝，静默失败（不影响用户体验）
        return;
      }

      // 调度通知
      await _notificationService.scheduleCheckInReminder(time);
    } catch (e) {
      // 调度失败，静默失败（不影响用户体验）
      // 生产环境应记录错误日志
    }
  }
}

/// 用户设置 Provider
final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final notificationService = ref.read(notificationServiceProvider);
  return UserSettingsNotifier(storageService, notificationService, ref);
});

