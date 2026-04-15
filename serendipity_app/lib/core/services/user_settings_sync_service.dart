import '../../models/user.dart';
import '../../models/user_settings.dart';
import '../repositories/i_remote_data_repository.dart';
import 'i_storage_service.dart';

class UserSettingsSyncService {
  final IRemoteDataRepository _remoteRepository;
  final IStorageService _storageService;

  UserSettingsSyncService({
    required IRemoteDataRepository remoteRepository,
    required IStorageService storageService,
  }) : _remoteRepository = remoteRepository,
       _storageService = storageService;

  /// 上传用户设置到云端
  ///
  /// 返回：服务端返回的最新设置（含服务端生成的 updatedAt）
  Future<UserSettings> uploadSettings(UserSettings settings) async {
    if (settings.userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    return await _remoteRepository.uploadSettings(settings.userId, settings);
  }

  /// 同步用户设置
  Future<void> syncUserSettings(User user) async {
    try {
      final remoteSettings = await _remoteRepository.downloadSettings(user.id);
      final localSettings = _storageService.getUserSettings();

      await _resolveSettingsConflict(
        user: user,
        localSettings: localSettings,
        remoteSettings: remoteSettings,
      );
    } catch (e) {
      // 设置同步失败不影响其他数据同步
    }
  }

  Future<void> _resolveSettingsConflict({
    required User user,
    required UserSettings? localSettings,
    required UserSettings? remoteSettings,
  }) async {
    if (remoteSettings == null) {
      await _handleRemoteSettingsNotFound(user, localSettings);
      return;
    }

    if (localSettings == null) {
      await _handleLocalSettingsNotFound(remoteSettings);
      return;
    }

    await _handleSettingsConflict(localSettings, remoteSettings);
  }

  Future<void> _handleRemoteSettingsNotFound(
    User user,
    UserSettings? localSettings,
  ) async {
    final settings = localSettings ?? UserSettings.createDefault(userId: user.id);
    final serverSettings = await _remoteRepository.uploadSettings(user.id, settings);
    await _storageService.saveUserSettings(serverSettings);
  }

  Future<void> _handleLocalSettingsNotFound(UserSettings remoteSettings) async {
    await _storageService.saveUserSettings(remoteSettings);
  }

  Future<void> _handleSettingsConflict(
    UserSettings localSettings,
    UserSettings remoteSettings,
  ) async {
    if (_areSettingsEquivalent(localSettings, remoteSettings)) {
      await _storageService.saveUserSettings(remoteSettings);
      return;
    }

    T selectByTimestamp<T>(
      T localValue,
      T remoteValue,
      DateTime localTime,
      DateTime remoteTime,
    ) {
      return localTime.isAfter(remoteTime) ? localValue : remoteValue;
    }

    final merged = UserSettings(
      id: localSettings.id,
      userId: localSettings.userId,
      theme: selectByTimestamp(
        localSettings.theme,
        remoteSettings.theme,
        localSettings.themeUpdatedAt,
        remoteSettings.themeUpdatedAt,
      ),
      pageTransition: selectByTimestamp(
        localSettings.pageTransition,
        remoteSettings.pageTransition,
        localSettings.themeUpdatedAt,
        remoteSettings.themeUpdatedAt,
      ),
      dialogAnimation: selectByTimestamp(
        localSettings.dialogAnimation,
        remoteSettings.dialogAnimation,
        localSettings.themeUpdatedAt,
        remoteSettings.themeUpdatedAt,
      ),
      themeUpdatedAt: localSettings.themeUpdatedAt.isAfter(remoteSettings.themeUpdatedAt)
          ? localSettings.themeUpdatedAt
          : remoteSettings.themeUpdatedAt,
      achievementNotification: selectByTimestamp(
        localSettings.achievementNotification,
        remoteSettings.achievementNotification,
        localSettings.notificationsUpdatedAt,
        remoteSettings.notificationsUpdatedAt,
      ),
      anniversaryReminder: selectByTimestamp(
        localSettings.anniversaryReminder,
        remoteSettings.anniversaryReminder,
        localSettings.notificationsUpdatedAt,
        remoteSettings.notificationsUpdatedAt,
      ),
      checkInReminderEnabled: selectByTimestamp(
        localSettings.checkInReminderEnabled,
        remoteSettings.checkInReminderEnabled,
        localSettings.notificationsUpdatedAt,
        remoteSettings.notificationsUpdatedAt,
      ),
      checkInReminderTime: selectByTimestamp(
        localSettings.checkInReminderTime,
        remoteSettings.checkInReminderTime,
        localSettings.notificationsUpdatedAt,
        remoteSettings.notificationsUpdatedAt,
      ),
      notificationsUpdatedAt: localSettings.notificationsUpdatedAt.isAfter(remoteSettings.notificationsUpdatedAt)
          ? localSettings.notificationsUpdatedAt
          : remoteSettings.notificationsUpdatedAt,
      checkInVibrationEnabled: selectByTimestamp(
        localSettings.checkInVibrationEnabled,
        remoteSettings.checkInVibrationEnabled,
        localSettings.checkInUpdatedAt,
        remoteSettings.checkInUpdatedAt,
      ),
      checkInConfettiEnabled: selectByTimestamp(
        localSettings.checkInConfettiEnabled,
        remoteSettings.checkInConfettiEnabled,
        localSettings.checkInUpdatedAt,
        remoteSettings.checkInUpdatedAt,
      ),
      checkInUpdatedAt: localSettings.checkInUpdatedAt.isAfter(remoteSettings.checkInUpdatedAt)
          ? localSettings.checkInUpdatedAt
          : remoteSettings.checkInUpdatedAt,
      hidePublishWarning: selectByTimestamp(
        localSettings.hidePublishWarning,
        remoteSettings.hidePublishWarning,
        localSettings.communityUpdatedAt,
        remoteSettings.communityUpdatedAt,
      ),
      hasSeenPublishWarning: selectByTimestamp(
        localSettings.hasSeenPublishWarning,
        remoteSettings.hasSeenPublishWarning,
        localSettings.communityUpdatedAt,
        remoteSettings.communityUpdatedAt,
      ),
      hasSeenCommunityIntro: selectByTimestamp(
        localSettings.hasSeenCommunityIntro,
        remoteSettings.hasSeenCommunityIntro,
        localSettings.communityUpdatedAt,
        remoteSettings.communityUpdatedAt,
      ),
      hasSeenFavoritesIntro: selectByTimestamp(
        localSettings.hasSeenFavoritesIntro,
        remoteSettings.hasSeenFavoritesIntro,
        localSettings.communityUpdatedAt,
        remoteSettings.communityUpdatedAt,
      ),
      communityUpdatedAt: localSettings.communityUpdatedAt.isAfter(remoteSettings.communityUpdatedAt)
          ? localSettings.communityUpdatedAt
          : remoteSettings.communityUpdatedAt,
      createdAt: localSettings.createdAt,
      updatedAt: DateTime.now(),
    );

    final serverSettings = await _remoteRepository.uploadSettings(merged.userId, merged);
    await _storageService.saveUserSettings(serverSettings);
  }

  bool _areSettingsEquivalent(UserSettings localSettings, UserSettings remoteSettings) {
    return localSettings.userId == remoteSettings.userId &&
        localSettings.theme == remoteSettings.theme &&
        localSettings.pageTransition == remoteSettings.pageTransition &&
        localSettings.dialogAnimation == remoteSettings.dialogAnimation &&
        localSettings.achievementNotification == remoteSettings.achievementNotification &&
        localSettings.anniversaryReminder == remoteSettings.anniversaryReminder &&
        localSettings.checkInReminderEnabled == remoteSettings.checkInReminderEnabled &&
        localSettings.checkInReminderTime == remoteSettings.checkInReminderTime &&
        localSettings.checkInVibrationEnabled == remoteSettings.checkInVibrationEnabled &&
        localSettings.checkInConfettiEnabled == remoteSettings.checkInConfettiEnabled &&
        localSettings.hidePublishWarning == remoteSettings.hidePublishWarning &&
        localSettings.hasSeenPublishWarning == remoteSettings.hasSeenPublishWarning &&
        localSettings.hasSeenCommunityIntro == remoteSettings.hasSeenCommunityIntro &&
        localSettings.hasSeenFavoritesIntro == remoteSettings.hasSeenFavoritesIntro &&
        localSettings.themeUpdatedAt == remoteSettings.themeUpdatedAt &&
        localSettings.notificationsUpdatedAt == remoteSettings.notificationsUpdatedAt &&
        localSettings.checkInUpdatedAt == remoteSettings.checkInUpdatedAt &&
        localSettings.communityUpdatedAt == remoteSettings.communityUpdatedAt;
  }
}

