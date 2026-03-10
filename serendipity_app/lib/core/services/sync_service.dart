import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/check_in_record.dart';
import '../../models/achievement_unlock.dart';
import '../../models/user.dart';
import '../../models/user_settings.dart';
import '../../models/sync_history.dart';
import '../config/app_config.dart';
import '../repositories/i_remote_data_repository.dart';
import '../repositories/test_remote_data_repository.dart';
import '../repositories/custom_server_remote_data_repository.dart';
import '../repositories/achievement_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/achievement_provider.dart';
import '../utils/auth_error_helper.dart';
import 'i_storage_service.dart';

/// 同步结果统计
/// 
/// 记录同步过程中的数据统计信息
class SyncResult {
  /// 上传的记录数量
  final int uploadedRecords;
  
  /// 上传的故事线数量
  final int uploadedStoryLines;
  
  /// 上传的签到记录数量
  final int uploadedCheckIns;
  
  /// 下载的记录数量
  final int downloadedRecords;
  
  /// 下载的故事线数量
  final int downloadedStoryLines;
  
  /// 下载的签到记录数量
  final int downloadedCheckIns;
  
  /// 合并冲突的记录数量
  final int mergedRecords;
  
  /// 合并冲突的故事线数量
  final int mergedStoryLines;
  
  /// 合并冲突的签到记录数量
  final int mergedCheckIns;
  
  /// 同步的成就解锁数量
  final int syncedAchievements;
  
  const SyncResult({
    required this.uploadedRecords,
    required this.uploadedStoryLines,
    required this.uploadedCheckIns,
    required this.downloadedRecords,
    required this.downloadedStoryLines,
    required this.downloadedCheckIns,
    required this.mergedRecords,
    required this.mergedStoryLines,
    required this.mergedCheckIns,
    required this.syncedAchievements,
  });
  
  /// 是否有数据变化
  bool get hasChanges {
    return uploadedRecords > 0 ||
           uploadedStoryLines > 0 ||
           uploadedCheckIns > 0 ||
           downloadedRecords > 0 ||
           downloadedStoryLines > 0 ||
           downloadedCheckIns > 0 ||
           mergedRecords > 0 ||
           mergedStoryLines > 0 ||
           mergedCheckIns > 0 ||
           syncedAchievements > 0;
  }
}

/// 远程数据仓储 Provider
/// 
/// 依赖抽象接口 IRemoteDataRepository，不依赖具体实现。
/// 遵循依赖倒置原则（DIP）：切换后端只需修改 AppConfig.serverType。
/// 
/// 后端选择：
/// - ServerType.test：使用 TestRemoteDataRepository（测试模式）
/// - ServerType.customServer：使用 CustomServerRemoteDataRepository（自建服务器）
final remoteDataRepositoryProvider = Provider<IRemoteDataRepository>((ref) {
  switch (AppConfig.serverType) {
    case ServerType.test:
      return TestRemoteDataRepository();
    
    case ServerType.customServer:
      final httpClient = ref.watch(httpClientServiceProvider);
      return CustomServerRemoteDataRepository(httpClient: httpClient);
  }
});

/// 数据同步服务
/// 
/// 负责本地数据与云端数据的同步，遵循单一职责原则（SRP）和依赖倒置原则（DIP）。
/// 
/// 调用者：
/// - RecordsProvider：创建/更新/删除记录后调用同步方法
/// - StoryLinesProvider：创建/更新/删除故事线后调用同步方法
/// - AuthProvider：用户登录后调用全量同步
/// - SettingsPage：手动同步按钮（未来）
class SyncService {
  final IRemoteDataRepository _remoteRepository;
  final IStorageService _storageService;
  final AchievementRepository _achievementRepository;
  
  SyncService({
    required IRemoteDataRepository remoteRepository,
    required IStorageService storageService,
    required AchievementRepository achievementRepository,
  })  : _remoteRepository = remoteRepository,
        _storageService = storageService,
        _achievementRepository = achievementRepository;
  
  /// 上传单条记录到云端（创建）
  /// 
  /// 调用者：
  /// - RecordsProvider.saveRecord()（新建记录）
  /// - syncAllData()（全量同步）
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - record 为 null：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<void> uploadRecord(User user, EncounterRecord record) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    await _remoteRepository.uploadRecord(user.id, record);
  }
  
  /// 更新云端记录（增量更新）
  /// 
  /// 调用者：
  /// - RecordsProvider.updateRecord()（更新记录）
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - record 为 null：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<void> updateRecord(User user, EncounterRecord record) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    await _remoteRepository.updateRecord(user.id, record);
  }
  
  /// 上传单条故事线到云端（创建）
  /// 
  /// 调用者：
  /// - StoryLinesProvider.createStoryLine()（新建故事线）
  /// - syncAllData()（全量同步）
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - storyLine 为 null：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<void> uploadStoryLine(User user, StoryLine storyLine) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    await _remoteRepository.uploadStoryLine(user.id, storyLine);
  }
  
  /// 更新云端故事线（增量更新）
  /// 
  /// 调用者：
  /// - StoryLinesProvider.updateStoryLine()（更新故事线）
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - storyLine 为 null：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<void> updateStoryLine(User user, StoryLine storyLine) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    await _remoteRepository.updateStoryLine(user.id, storyLine);
  }
  
  /// 上传单条签到记录到云端
  /// 
  /// 调用者：
  /// - CheckInProvider.checkIn()
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - checkIn 为 null：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<void> uploadCheckIn(User user, CheckInRecord checkIn) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    await _remoteRepository.uploadCheckIn(user.id, checkIn);
  }
  
  /// 删除云端记录
  /// 
  /// 调用者：RecordsProvider.deleteRecord()
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - recordId 为空：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<void> deleteRecord(User user, String recordId) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (recordId.isEmpty) {
      throw ArgumentError('记录 ID 不能为空');
    }
    
    await _remoteRepository.deleteRecord(user.id, recordId);
  }
  
  /// 上传成就解锁记录到云端
  /// 
  /// 调用者：
  /// - RecordsProvider：成就解锁后上传
  /// - CheckInProvider：成就解锁后上传
  /// - StoryLinesProvider：成就解锁后上传
  /// 
  /// Fail Fast：
  /// - unlock 为 null：抛出 ArgumentError
  /// - unlock.userId 为空：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<void> uploadAchievementUnlock(AchievementUnlock unlock) async {
    // Fail Fast：参数验证
    if (unlock.userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (unlock.achievementId.isEmpty) {
      throw ArgumentError('成就 ID 不能为空');
    }
    
    await _remoteRepository.uploadAchievementUnlock(unlock);
  }
  
  /// 删除云端故事线
  /// 
  /// 调用者：StoryLinesProvider.deleteStoryLine()
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - storyLineId 为空：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<void> deleteStoryLine(User user, String storyLineId) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (storyLineId.isEmpty) {
      throw ArgumentError('故事线 ID 不能为空');
    }
    
    await _remoteRepository.deleteStoryLine(user.id, storyLineId);
  }
  
  /// 删除云端签到记录
  /// 
  /// 调用者：CheckInProvider.resetAllCheckIns()（开发者功能）
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - checkInId 为空：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<void> deleteCheckIn(User user, String checkInId) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (checkInId.isEmpty) {
      throw ArgumentError('签到记录 ID 不能为空');
    }
    
    await _remoteRepository.deleteCheckIn(user.id, checkInId);
  }
  
  /// 获取指定用户的上次同步时间
  /// 
  /// 调用者：
  /// - NetworkMonitorService：App启动时读取上次同步时间
  /// 
  /// 参数：
  /// - userId：用户 ID
  /// 
  /// 返回：
  /// - 上次同步时间（如果有）
  /// - null（该用户首次同步）
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  Future<DateTime?> getLastSyncTime(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    // 优先从持久化存储中读取（跨进程重启可用）
    final persisted = _storageService.getLastSyncTime(userId);
    if (persisted != null) return persisted;
    
    // 兜底：从同步历史记录中推断
    final userHistories = _storageService.getSyncHistoriesByUser(userId);
    if (userHistories.isEmpty) return null;
    
    final successHistories = userHistories.where((h) => h.success).toList();
    if (successHistories.isEmpty) return null;
    
    return successHistories.first.syncTime;
  }
  
  /// 保存上次同步时间
  /// 
  /// 调用者：syncAllData() 成功后
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  Future<void> _saveLastSyncTime(String userId, DateTime syncStartTime) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    await _storageService.setLastSyncTime(userId, syncStartTime);
  }
  
  /// 数据同步：上传本地变化 + 下载云端变化
  /// 
  /// 调用者：
  /// - AuthProvider：用户注册/登录成功后自动调用
  /// - NetworkMonitorService：网络恢复/App启动时自动调用
  /// - ManualSyncDialog：手动同步按钮
  /// 
  /// 同步策略：
  /// 1. 上传本地有变化的数据（updatedAt > lastSyncTime）
  /// 2. 下载云端有变化的数据（updatedAt > lastSyncTime）
  ///    - 注册（lastSyncTime == null）：跳过下载，新用户云端确实没数据
  ///    - 登录/启动/手动（lastSyncTime != null）：增量下载，支持多设备同步
  /// 3. 合并数据（最后更新时间优先）
  /// 4. 同步成就解锁状态（静默）
  /// 5. 保存同步历史记录
  /// 
  /// 参数：
  /// - user：当前用户
  /// - lastSyncTime：上次同步时间（null 表示注册场景，跳过下载）
  /// - source：同步来源（默认手动同步）
  /// 
  /// 返回：同步结果统计
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<SyncResult> syncAllData(
    User user, {
    DateTime? lastSyncTime,
    SyncSource source = SyncSource.manual,
  }) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    // 记录同步开始时间
    final syncStartTime = DateTime.now();
    
    try {
      // 1. 上传本地有变化的数据
      final uploadStats = await _uploadLocalData(user, lastSyncTime: lastSyncTime);
      
      // 2. 下载云端有变化的数据
      // 注册场景（lastSyncTime == null）：跳过下载，新用户云端确实没数据
      // 登录/启动/手动场景（lastSyncTime != null）：增量下载，支持多设备同步
      final downloadStats = lastSyncTime == null
          ? {'records': 0, 'storyLines': 0, 'checkIns': 0, 'mergedRecords': 0, 'mergedStoryLines': 0, 'mergedCheckIns': 0}
          : await _downloadRemoteData(user, lastSyncTime: lastSyncTime);
      
      // 3. 同步用户设置
      await _syncUserSettings(user);
      
      // 4. 同步成就解锁状态（静默，不触发通知）
      final syncedAchievements = await _syncAchievementUnlocks(user);
      
      // 5. 构建同步结果统计
      final result = SyncResult(
        uploadedRecords: uploadStats['records'] ?? 0,
        uploadedStoryLines: uploadStats['storyLines'] ?? 0,
        uploadedCheckIns: uploadStats['checkIns'] ?? 0,
        downloadedRecords: downloadStats['records'] ?? 0,
        downloadedStoryLines: downloadStats['storyLines'] ?? 0,
        downloadedCheckIns: downloadStats['checkIns'] ?? 0,
        mergedRecords: downloadStats['mergedRecords'] ?? 0,
        mergedStoryLines: downloadStats['mergedStoryLines'] ?? 0,
        mergedCheckIns: downloadStats['mergedCheckIns'] ?? 0,
        syncedAchievements: syncedAchievements,
      );
      
      // 6. 保存同步历史记录（成功）
      final syncEndTime = DateTime.now();
      final history = SyncHistory.fromSuccess(
        result: result,
        userId: user.id,
        syncStartTime: syncStartTime,
        syncEndTime: syncEndTime,
        source: source,
      );
      await _storageService.saveSyncHistory(history);
      
      // 7. 持久化上次同步时间（供下次增量同步使用）
      await _saveLastSyncTime(user.id, syncStartTime);
      
      // 8. 返回同步结果统计
      return result;
    } catch (e) {
      // 保存同步历史记录（失败）
      final syncEndTime = DateTime.now();
      final history = SyncHistory.fromError(
        errorMessage: AuthErrorHelper.extractErrorMessage(e),
        userId: user.id,
        syncStartTime: syncStartTime,
        syncEndTime: syncEndTime,
        source: source,
      );
      await _storageService.saveSyncHistory(history);
      
      // 重新抛出异常
      rethrow;
    }
  }
  
  /// 上传本地有变化的数据到云端（增量上传）
  /// 
  /// 调用者：syncAllData()
  /// 
  /// 参数：
  /// - user: 当前用户
  /// - lastSyncTime：上次同步时间，如果为 null 则全量上传
  /// 
  /// 返回：上传统计信息
  /// 
  /// 注意：只上传属于当前用户的数据（ownerId == user.id）
  Future<Map<String, int>> _uploadLocalData(User user, {DateTime? lastSyncTime}) async {
    int uploadedRecords = 0;
    int uploadedStoryLines = 0;
    int uploadedCheckIns = 0;
    
    // 上传记录（只上传当前用户的）
    try {
      final userRecords = _storageService.getRecordsByUser(user.id);
      final changedRecords = lastSyncTime == null
          ? userRecords
          : userRecords.where((r) => r.updatedAt.isAfter(lastSyncTime)).toList();
      
      if (changedRecords.isNotEmpty) {
        await _remoteRepository.uploadRecords(user.id, changedRecords);
        uploadedRecords = changedRecords.length;
      }
    } catch (e) {
      // 上传失败不影响其他数据同步
    }
    
    // 上传故事线（只上传当前用户的）
    try {
      final userStoryLines = _storageService.getStoryLinesByUser(user.id);
      final changedStoryLines = lastSyncTime == null
          ? userStoryLines
          : userStoryLines.where((s) => s.updatedAt.isAfter(lastSyncTime)).toList();
      
      if (changedStoryLines.isNotEmpty) {
        await _remoteRepository.uploadStoryLines(user.id, changedStoryLines);
        uploadedStoryLines = changedStoryLines.length;
      }
    } catch (e) {
      // 上传失败不影响其他数据同步
    }
    
    // 上传签到记录（只上传当前用户的）
    try {
      final userCheckIns = _storageService.getCheckInsByUser(user.id);
      final changedCheckIns = lastSyncTime == null
          ? userCheckIns
          : userCheckIns.where((c) => c.updatedAt.isAfter(lastSyncTime)).toList();
      
      if (changedCheckIns.isNotEmpty) {
        await _remoteRepository.uploadCheckIns(user.id, changedCheckIns);
        uploadedCheckIns = changedCheckIns.length;
      }
    } catch (e) {
      // 上传失败不影响其他数据同步
    }
    
    return {
      'records': uploadedRecords,
      'storyLines': uploadedStoryLines,
      'checkIns': uploadedCheckIns,
    };
  }
  
  /// 下载云端有变化的数据到本地（增量下载）
  /// 
  /// 调用者：syncAllData()
  /// 
  /// 参数：
  /// - lastSyncTime：上次同步时间，如果为 null 则全量下载
  /// 
  /// 返回：下载和合并统计信息
  Future<Map<String, int>> _downloadRemoteData(User user, {DateTime? lastSyncTime}) async {
    int mergedRecords = 0;
    int mergedStoryLines = 0;
    int mergedCheckIns = 0;
    
    // 下载云端记录（增量或全量）
    final remoteRecords = lastSyncTime == null
        ? await _remoteRepository.downloadRecords(user.id)
        : await _remoteRepository.downloadRecordsSince(user.id, lastSyncTime);
    
    // 合并到本地（最后更新时间优先）
    for (final remoteRecord in remoteRecords) {
      final localRecord = _storageService.getRecord(remoteRecord.id);
      
      // 如果本地不存在，或云端数据更新
      if (localRecord == null || 
          remoteRecord.updatedAt.isAfter(localRecord.updatedAt)) {
        await _storageService.saveRecord(remoteRecord);
        
        // 如果本地存在且云端数据更新，说明发生了冲突合并
        if (localRecord != null) {
          mergedRecords++;
        }
      }
    }
    
    // 下载云端故事线（增量或全量）
    final remoteStoryLines = lastSyncTime == null
        ? await _remoteRepository.downloadStoryLines(user.id)
        : await _remoteRepository.downloadStoryLinesSince(user.id, lastSyncTime);
    
    // 合并到本地（最后更新时间优先）
    for (final remoteStoryLine in remoteStoryLines) {
      final localStoryLine = _storageService.getStoryLine(remoteStoryLine.id);
      
      // 如果本地不存在，或云端数据更新
      if (localStoryLine == null || 
          remoteStoryLine.updatedAt.isAfter(localStoryLine.updatedAt)) {
        await _storageService.saveStoryLine(remoteStoryLine);
        
        // 如果本地存在且云端数据更新，说明发生了冲突合并
        if (localStoryLine != null) {
          mergedStoryLines++;
        }
      }
    }
    
    // 下载云端签到记录（增量或全量）
    final remoteCheckIns = lastSyncTime == null
        ? await _remoteRepository.downloadCheckIns(user.id)
        : await _remoteRepository.downloadCheckInsSince(user.id, lastSyncTime);
    
    // 合并到本地（最后更新时间优先）
    for (final remoteCheckIn in remoteCheckIns) {
      final localCheckIn = _storageService.getCheckIn(remoteCheckIn.id);
      
      // 如果本地不存在，或云端数据更新
      if (localCheckIn == null || 
          remoteCheckIn.updatedAt.isAfter(localCheckIn.updatedAt)) {
        await _storageService.saveCheckIn(remoteCheckIn);
        
        // 如果本地存在且云端数据更新，说明发生了冲突合并
        if (localCheckIn != null) {
          mergedCheckIns++;
        }
      }
    }
    
    return {
      'records': remoteRecords.length,
      'storyLines': remoteStoryLines.length,
      'checkIns': remoteCheckIns.length,
      'mergedRecords': mergedRecords,
      'mergedStoryLines': mergedStoryLines,
      'mergedCheckIns': mergedCheckIns,
    };
  }
  
  /// 同步成就解锁状态（静默）
  /// 
  /// 调用者：syncAllData()
  /// 
  /// 同步策略：
  /// 1. 下载云端所有成就解锁记录
  /// 2. 静默标记本地成就为已解锁（不触发通知）
  /// 3. 本地检测器继续运行，检测新成就（触发通知）
  /// 
  /// 返回：同步的成就数量
  Future<int> _syncAchievementUnlocks(User user) async {
    try {
      // 下载云端成就解锁记录
      final remoteUnlocks = await _remoteRepository.downloadAchievementUnlocks(user.id);
      
      // 静默标记本地成就为已解锁
      await _achievementRepository.syncAchievementUnlocks(remoteUnlocks);
      
      return remoteUnlocks.length;
    } catch (e) {
      // 成就同步失败不影响其他数据同步
      // 生产环境应记录错误日志
      return 0;
    }
  }
  
  /// 同步用户设置
  /// 
  /// 调用者：syncAllData()
  /// 
  /// 同步策略（全量同步 + 智能冲突解决）：
  /// 1. 下载云端设置
  /// 2. 获取本地设置
  /// 3. 根据存在性和 updatedAt 时间戳决定使用哪个版本：
  ///    - 云端不存在 → 上传本地设置（或创建默认设置）
  ///    - 本地不存在 → 使用云端设置
  ///    - 两边都存在 → 比较 updatedAt，使用最新的版本
  /// 
  /// 优点：
  /// - 保留离线修改（本地更新时上传）
  /// - 逻辑简单（无需字段级别追踪）
  /// - 性能优秀（全量同步，数据量小）
  /// - 冲突解决合理（最后更新时间优先）
  /// 
  /// 注意：
  /// - 本地存储不区分用户（单用户设计）
  /// - 设置同步失败不影响其他数据同步
  Future<void> _syncUserSettings(User user) async {
    try {
      // 1. 下载云端设置
      final remoteSettings = await _remoteRepository.downloadSettings(user.id);
      
      // 2. 获取本地设置
      final localSettings = _storageService.getUserSettings();
      
      // 3. 根据存在性和时间戳决定同步方向
      await _resolveSettingsConflict(
        user: user,
        localSettings: localSettings,
        remoteSettings: remoteSettings,
      );
    } catch (e) {
      // 设置同步失败不影响其他数据同步
      // 生产环境应记录错误日志
    }
  }
  
  /// 解决用户设置冲突
  /// 
  /// 调用者：_syncUserSettings()
  /// 
  /// 冲突解决策略：
  /// - 场景1：云端不存在 → 上传本地设置（或创建默认设置）
  /// - 场景2：本地不存在 → 使用云端设置
  /// - 场景3：两边都存在 → 比较 updatedAt，使用最新的版本
  /// 
  /// 遵循原则：
  /// - 单一职责：只负责冲突解决逻辑
  /// - Fail Fast：参数验证
  /// - 最后更新时间优先（Last Write Wins）
  Future<void> _resolveSettingsConflict({
    required User user,
    required UserSettings? localSettings,
    required UserSettings? remoteSettings,
  }) async {
    // 场景1：云端不存在
    if (remoteSettings == null) {
      await _handleRemoteSettingsNotFound(user, localSettings);
      return;
    }
    
    // 场景2：本地不存在
    if (localSettings == null) {
      await _handleLocalSettingsNotFound(remoteSettings);
      return;
    }
    
    // 场景3：两边都存在，比较 updatedAt
    await _handleSettingsConflict(localSettings, remoteSettings);
  }
  
  /// 处理云端设置不存在的情况
  /// 
  /// 调用者：_resolveSettingsConflict()
  /// 
  /// 策略：
  /// - 如果本地有设置 → 上传本地设置
  /// - 如果本地没有设置 → 创建默认设置并上传
  Future<void> _handleRemoteSettingsNotFound(
    User user,
    UserSettings? localSettings,
  ) async {
    final settings = localSettings ?? UserSettings.createDefault(userId: user.id);
    await _remoteRepository.uploadSettings(settings);
    await _storageService.saveUserSettings(settings);
  }
  
  /// 处理本地设置不存在的情况
  /// 
  /// 调用者：_resolveSettingsConflict()
  /// 
  /// 策略：使用云端设置
  Future<void> _handleLocalSettingsNotFound(UserSettings remoteSettings) async {
    await _storageService.saveUserSettings(remoteSettings);
  }
  
  /// 处理本地和云端设置都存在的冲突
  /// 
  /// 调用者：_resolveSettingsConflict()
  /// 
  /// 策略：比较 updatedAt，使用最新的版本（Last Write Wins）
  /// - 本地更新 → 上传本地设置
  /// - 云端更新 → 使用云端设置
  /// - 时间相同 → 使用云端设置（保守策略）
  Future<void> _handleSettingsConflict(
    UserSettings localSettings,
    UserSettings remoteSettings,
  ) async {
    // 比较更新时间（Last Write Wins）
    if (localSettings.updatedAt.isAfter(remoteSettings.updatedAt)) {
      // 本地更新，上传本地设置
      await _remoteRepository.uploadSettings(localSettings);
    } else {
      // 云端更新或时间相同，使用云端设置
      await _storageService.saveUserSettings(remoteSettings);
    }
  }
}

/// 数据同步服务 Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    remoteRepository: ref.read(remoteDataRepositoryProvider),
    storageService: ref.read(storageServiceProvider),
    achievementRepository: ref.read(achievementRepositoryProvider),
  );
});

