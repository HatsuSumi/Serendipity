part of '../storage_service.dart';

mixin _StorageServiceSettings on _StorageServiceCore {
  static const String lastSyncTimeKeyPrefix = 'last_sync_time_';

  @override
  UserSettings? getUserSettings() {
    final json = settingsBoxOrThrow.get('user_settings');
    if (json == null) return null;
    return UserSettings.fromJson(Map<String, dynamic>.from(json as Map));
  }

  @override
  Future<void> saveUserSettings(UserSettings settings) async {
    await settingsBoxOrThrow.put('user_settings', settings.toJson());
  }

  @override
  DateTime? getLastSyncTime(String userId) {
    assert(userId.isNotEmpty, 'User ID cannot be empty');
    final key = '$lastSyncTimeKeyPrefix$userId';
    final timeStr = settingsBoxOrThrow.get(key) as String?;
    if (timeStr == null) return null;
    try {
      return DateTime.parse(timeStr);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setLastSyncTime(String userId, DateTime syncStartTime) async {
    assert(userId.isNotEmpty, 'User ID cannot be empty');
    final key = '$lastSyncTimeKeyPrefix$userId';
    await settingsBoxOrThrow.put(key, syncStartTime.toIso8601String());
  }

  @override
  Future<void> set<T>(String key, T value) async {
    await settingsBoxOrThrow.put(key, value);
  }

  @override
  T? get<T>(String key) {
    return settingsBoxOrThrow.get(key) as T?;
  }

  @override
  Future<void> saveString(String key, String value) async {
    await settingsBoxOrThrow.put(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    return settingsBoxOrThrow.get(key) as String?;
  }

  @override
  Future<void> remove(String key) async {
    await settingsBoxOrThrow.delete(key);
  }

  @override
  Future<void> clearAuthData() async {
    await settingsBoxOrThrow.delete('user_settings');
  }
}
