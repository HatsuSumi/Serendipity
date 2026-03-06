import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_settings.dart';
import '../../models/enums.dart';
import '../services/i_storage_service.dart';
import '../services/notification_service.dart';
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
/// 
/// 设计原则：
/// - 单一职责：只负责用户设置的状态管理
/// - 依赖注入：通过构造函数注入依赖
/// - Fail Fast：操作失败立即抛出异常
/// - 保证非空：state 始终为非空，简化 UI 层逻辑
class UserSettingsNotifier extends StateNotifier<UserSettings> {
  final IStorageService _storageService;
  final NotificationService _notificationService;

  UserSettingsNotifier(
    this._storageService,
    this._notificationService,
  ) : super(_createDefaultSettings()) {
    _loadSettings();
  }

  /// 创建默认设置
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 加载用户设置
  /// 
  /// 单一职责：只负责从存储加载，不负责创建默认值
  Future<void> _loadSettings() async {
    final settings = _storageService.getUserSettings();
    
    if (settings != null) {
      state = settings;
      
      // 如果启用了签到提醒，调度通知
      if (settings.checkInReminderEnabled) {
        await _scheduleCheckInReminder(settings.checkInReminderTime);
      }
    } else {
      // 首次使用，保存默认设置
      await _storageService.saveUserSettings(state);
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
  }

  /// 更新页面切换动画
  Future<void> updatePageTransition(PageTransitionType type) async {
    final updated = state.copyWith(
      pageTransition: type,
      updatedAt: DateTime.now(),
    );

    await _storageService.saveUserSettings(updated);
    state = updated;
  }

  /// 更新对话框动画
  Future<void> updateDialogAnimation(DialogAnimationType type) async {
    final updated = state.copyWith(
      dialogAnimation: type,
      updatedAt: DateTime.now(),
    );

    await _storageService.saveUserSettings(updated);
    state = updated;
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
  }

  /// 更新签到震动开关
  Future<void> updateCheckInVibrationEnabled(bool enabled) async {
    final updated = state.copyWith(
      checkInVibrationEnabled: enabled,
      updatedAt: DateTime.now(),
    );

    await _storageService.saveUserSettings(updated);
    state = updated;
  }

  /// 更新签到粒子特效开关
  Future<void> updateCheckInConfettiEnabled(bool enabled) async {
    final updated = state.copyWith(
      checkInConfettiEnabled: enabled,
      updatedAt: DateTime.now(),
    );

    await _storageService.saveUserSettings(updated);
    state = updated;
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
  return UserSettingsNotifier(storageService, notificationService);
});

