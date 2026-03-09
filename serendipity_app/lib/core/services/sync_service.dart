import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/check_in_record.dart';
import '../../models/achievement_unlock.dart';
import '../../models/user.dart';
import '../../models/sync_history.dart';
import '../config/app_config.dart';
import '../repositories/i_remote_data_repository.dart';
import '../repositories/test_remote_data_repository.dart';
import '../repositories/custom_server_remote_data_repository.dart';
import '../repositories/achievement_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/achievement_provider.dart';
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
  
  /// 增量同步：只同步有变化的数据
  /// 
  /// 调用者：
  /// - AuthProvider：用户登录成功后自动调用（首次全量同步）
  /// - NetworkMonitorService：网络恢复/App启动时自动调用
  /// - ManualSyncDialog：手动同步按钮（增量同步）
  /// 
  /// 同步策略：
  /// 1. 获取上次同步时间
  /// 2. 上传本地有变化的数据（updatedAt > lastSyncTime）
  /// 3. 下载云端有变化的数据（updatedAt > lastSyncTime）
  /// 4. 合并数据（最后更新时间优先）
  /// 5. 同步成就解锁状态（静默）
  /// 6. 保存同步历史记录
  /// 
  /// 参数：
  /// - user：当前用户
  /// - lastSyncTime：上次同步时间（null 表示全量同步）
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
      final downloadStats = await _downloadRemoteData(user, lastSyncTime: lastSyncTime);
      
      // 3. 同步成就解锁状态（静默，不触发通知）
      final syncedAchievements = await _syncAchievementUnlocks(user);
      
      // 4. 构建同步结果统计
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
      
      // 5. 保存同步历史记录（成功）
      final syncEndTime = DateTime.now();
      final history = SyncHistory.fromSuccess(
        result: result,
        syncStartTime: syncStartTime,
        syncEndTime: syncEndTime,
        source: source,
      );
      await _storageService.saveSyncHistory(history);
      
      // 6. 返回同步结果统计
      return result;
    } catch (e) {
      // 保存同步历史记录（失败）
      final syncEndTime = DateTime.now();
      final history = SyncHistory.fromError(
        errorMessage: e.toString(),
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
  /// - lastSyncTime：上次同步时间，如果为 null 则全量上传
  /// 
  /// 返回：上传统计信息
  Future<Map<String, int>> _uploadLocalData(User user, {DateTime? lastSyncTime}) async {
    // 获取本地所有记录
    final allRecords = _storageService.getRecordsSortedByTime();
    
    // 过滤出有变化的记录（增量上传）
    final changedRecords = lastSyncTime == null
        ? allRecords
        : allRecords.where((r) => r.updatedAt.isAfter(lastSyncTime)).toList();
    
    // 批量上传记录
    if (changedRecords.isNotEmpty) {
      await _remoteRepository.uploadRecords(user.id, changedRecords);
    }
    
    // 获取本地所有故事线
    final allStoryLines = _storageService.getAllStoryLines();
    
    // 过滤出有变化的故事线（增量上传）
    final changedStoryLines = lastSyncTime == null
        ? allStoryLines
        : allStoryLines.where((s) => s.updatedAt.isAfter(lastSyncTime)).toList();
    
    // 批量上传故事线
    if (changedStoryLines.isNotEmpty) {
      await _remoteRepository.uploadStoryLines(user.id, changedStoryLines);
    }
    
    // 获取本地所有签到记录
    final allCheckIns = _storageService.getAllCheckIns();
    
    // 过滤出有变化的签到记录（增量上传）
    final changedCheckIns = lastSyncTime == null
        ? allCheckIns
        : allCheckIns.where((c) => c.updatedAt.isAfter(lastSyncTime)).toList();
    
    // 批量上传签到记录
    if (changedCheckIns.isNotEmpty) {
      await _remoteRepository.uploadCheckIns(user.id, changedCheckIns);
    }
    
    return {
      'records': changedRecords.length,
      'storyLines': changedStoryLines.length,
      'checkIns': changedCheckIns.length,
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
        _storageService.saveRecord(remoteRecord);
        
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
        _storageService.saveStoryLine(remoteStoryLine);
        
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
        _storageService.saveCheckIn(remoteCheckIn);
        
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
}

/// 数据同步服务 Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    remoteRepository: ref.read(remoteDataRepositoryProvider),
    storageService: ref.read(storageServiceProvider),
    achievementRepository: ref.read(achievementRepositoryProvider),
  );
});

