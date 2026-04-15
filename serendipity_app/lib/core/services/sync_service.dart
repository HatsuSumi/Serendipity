import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/achievement_unlock.dart';
import '../../models/check_in_record.dart';
import '../../models/encounter_record.dart';
import '../../models/membership.dart';
import '../../models/remote_check_in_status.dart';
import '../../models/story_line.dart';
import '../../models/sync_history.dart';
import '../../models/user.dart';
import '../../models/user_settings.dart';
import '../config/app_config.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/custom_server_remote_data_repository.dart';
import '../repositories/i_remote_data_repository.dart';
import '../repositories/test_remote_data_repository.dart';
import '../providers/achievement_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_helper.dart';
import 'achievement_sync_service.dart';
import 'check_in_sync_service.dart';
import 'i_storage_service.dart';
import 'membership_sync_service.dart';
import 'record_sync_service.dart';
import 'story_line_sync_service.dart';
import 'sync_metadata_service.dart';
import 'sync_result.dart';
import 'user_settings_sync_service.dart';

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
  final UserSettingsSyncService _userSettingsSyncService;
  final MembershipSyncService _membershipSyncService;
  final AchievementSyncService _achievementSyncService;
  final CheckInSyncService _checkInSyncService;
  final RecordSyncService _recordSyncService;
  final StoryLineSyncService _storyLineSyncService;
  final SyncMetadataService _syncMetadataService;
  
  // 同步时间存储键（由 IStorageService.getLastSyncTime/setLastSyncTime 管理）
  
  SyncService({
    required IRemoteDataRepository remoteRepository,
    required IStorageService storageService,
    required AchievementRepository achievementRepository,
  })  : _userSettingsSyncService = UserSettingsSyncService(
          remoteRepository: remoteRepository,
          storageService: storageService,
        ),
        _membershipSyncService = MembershipSyncService(
          remoteRepository: remoteRepository,
          storageService: storageService,
        ),
        _achievementSyncService = AchievementSyncService(
          remoteRepository: remoteRepository,
          achievementRepository: achievementRepository,
        ),
        _checkInSyncService = CheckInSyncService(
          remoteRepository: remoteRepository,
          storageService: storageService,
        ),
        _recordSyncService = RecordSyncService(
          remoteRepository: remoteRepository,
          storageService: storageService,
        ),
        _storyLineSyncService = StoryLineSyncService(
          remoteRepository: remoteRepository,
          storageService: storageService,
        ),
        _syncMetadataService = SyncMetadataService(
          storageService: storageService,
        );
  
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
    await _recordSyncService.uploadRecord(user, record);
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
    await _recordSyncService.updateRecord(user, record);
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
    await _storyLineSyncService.uploadStoryLine(user, storyLine);
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
    await _storyLineSyncService.updateStoryLine(user, storyLine);
  }
  
  /// 创建今天的签到记录（服务端权威）
  /// 
  /// 调用者：
  /// - CheckInProvider.checkIn()
  /// 
  /// Fail Fast：
  /// - user.id 为空：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<CheckInRecord> createTodayCheckIn(User user) async {
    return await _checkInSyncService.createTodayCheckIn(user);
  }

  /// 获取登录用户指定月份的签到状态（服务端权威）
  Future<RemoteCheckInStatus> getCheckInStatus(
    User user,
    int year,
    int month,
  ) async {
    return await _checkInSyncService.getCheckInStatus(user, year, month);
  }

  /// 刷新当前用户的签到缓存（服务端优先，本地兜底）
  ///
  /// 调用者：
  /// - CheckInProvider.build()
  /// - CheckInProvider.refresh()
  ///
  /// 设计说明：
  /// - 登录用户优先从服务端读取签到记录
  /// - 本地仅作为缓存与离线副本
  /// - 全量覆盖当前用户的签到缓存，确保多设备一致性
  Future<void> refreshCheckIns(User user) async {
    await _checkInSyncService.refreshCheckIns(user);
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
    await _recordSyncService.deleteRecord(user, recordId);
  }
  
  /// 上传用户设置到云端
  /// 
  /// 调用者：
  /// - UserSettingsNotifier：设置变更时即时上传
  /// - SyncService._handleRemoteSettingsNotFound()（全量同步）
  /// 
  /// 返回：服务端返回的最新设置（含服务端生成的 updatedAt）
  /// 
  /// Fail Fast：
  /// - settings.userId 为空：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<UserSettings> uploadSettings(UserSettings settings) async {
    return await _userSettingsSyncService.uploadSettings(settings);
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
    await _achievementSyncService.uploadAchievementUnlock(unlock);
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
    await _storyLineSyncService.deleteStoryLine(user, storyLineId);
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
    await _checkInSyncService.deleteCheckIn(user, checkInId);
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
    return await _syncMetadataService.getLastSyncTime(userId);
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
  /// 2. 下载云端变化：
  ///    - skipFullSyncCleanup == true：执行一次云端全量拉取，但不做“云端缺失即删除本地”的对齐
  ///      适用于注册后的初始化场景，避免误删当前设备刚产生的本地数据
  ///    - lastSyncTime == null：执行全量同步，用云端全集对齐本地，并清理云端已不存在的数据
  ///    - lastSyncTime != null：执行增量同步，下载 updatedAt > lastSyncTime 的变更，包含墓碑删除
  /// 3. 合并数据（墓碑优先，其次最后更新时间优先）
  /// 4. 同步成就解锁状态（静默）
  /// 5. 保存同步历史记录
  /// 
  /// 参数：
  /// - user：当前用户
  /// - lastSyncTime：上次同步时间（null 表示进入全量同步分支）
  /// - skipFullSyncCleanup：是否跳过本地对齐删除（注册场景传 true，其他场景不传）
  /// - source：同步来源（默认手动同步）
  /// - onProgress：同步进度回调（可选，用于 UI 展示进度）
  /// 
  /// 返回：同步结果统计
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<SyncResult> syncAllData(
    User user, {
    DateTime? lastSyncTime,
    bool skipFullSyncCleanup = false,
    SyncSource source = SyncSource.manual,
    void Function(String)? onProgress,
  }) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    // 记录同步开始时间
    final syncStartTime = DateTime.now();
    
    try {
      // 1. 上传本地有变化的数据
      onProgress?.call('正在上传本地数据...');
      final uploadStats = await _uploadLocalData(user, lastSyncTime: lastSyncTime);
      
      // 2. 下载云端变化
      // skipFullSyncCleanup == true（注册初始化场景）：拉取云端全集，但不按“云端缺失”删除本地
      // 其他场景：lastSyncTime == null 走全量对齐；否则走带墓碑的增量同步
      onProgress?.call('正在下载云端数据...');
      final downloadStats = skipFullSyncCleanup
          ? await _downloadRemoteData(user, lastSyncTime: null, isFullSync: false)
          : await _downloadRemoteData(user, lastSyncTime: lastSyncTime);
      
      // 3. 同步用户设置
      onProgress?.call('正在同步用户设置...');
      await _syncUserSettings(user);

      // 4. 同步会员信息（服务端真源）
      onProgress?.call('正在同步会员信息...');
      await _syncMembership(user);
      
      // 5. 同步成就解锁状态（静默，不触发通知）
      onProgress?.call('正在同步成就...');
      final syncedAchievements = await _syncAchievementUnlocks(user);
      
      // 6. 构建同步结果统计
      final result = SyncResult(
        uploadedRecords: uploadStats.records,
        uploadedStoryLines: uploadStats.storyLines,
        uploadedCheckIns: uploadStats.checkIns,
        downloadedRecords: downloadStats.records,
        downloadedStoryLines: downloadStats.storyLines,
        downloadedCheckIns: downloadStats.checkIns,
        mergedRecords: downloadStats.mergedRecords,
        mergedStoryLines: downloadStats.mergedStoryLines,
        mergedCheckIns: downloadStats.mergedCheckIns,
        syncedAchievements: syncedAchievements,
      );
      
      // 7. 保存同步历史记录（成功）
      final syncEndTime = DateTime.now();
      await _syncMetadataService.saveSuccessHistory(
        result: result,
        userId: user.id,
        syncStartTime: syncStartTime,
        syncEndTime: syncEndTime,
        source: source,
      );
      
      // 8. 持久化上次同步时间（供下次增量同步使用）
      await _syncMetadataService.saveLastSyncTime(user.id, syncStartTime);
      
      // 9. 返回同步结果统计
      onProgress?.call('同步完成');
      return result;
    } catch (e) {
      // 保存同步历史记录（失败）
      final syncEndTime = DateTime.now();
      await _syncMetadataService.saveFailureHistory(
        errorMessage: AuthErrorHelper.extractErrorMessage(e),
        userId: user.id,
        syncStartTime: syncStartTime,
        syncEndTime: syncEndTime,
        source: source,
      );
      
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
  /// 
  /// 错误处理：网络错误直接抛出，让用户看到错误提示
  Future<UploadSyncStats> _uploadLocalData(User user, {DateTime? lastSyncTime}) async {
    final uploadedRecords = await _recordSyncService.uploadChangedRecords(
      user,
      lastSyncTime: lastSyncTime,
    );
    final uploadedStoryLines = await _storyLineSyncService.uploadChangedStoryLines(
      user,
      lastSyncTime: lastSyncTime,
    );
    const uploadedCheckIns = 0;

    // 上传签到记录不再参与同步：登录用户签到以服务端主写为准
    
    return UploadSyncStats(
      records: uploadedRecords,
      storyLines: uploadedStoryLines,
      checkIns: uploadedCheckIns,
    );
  }
  
  /// 下载云端数据到本地（全量对齐或增量消费）
  /// 
  /// 调用者：syncAllData()
  /// 
  /// 参数：
  /// - user：当前用户
  /// - lastSyncTime：上次同步时间
  ///   - null → 全量同步：下载所有数据并与本地对齐
  ///   - 非 null → 增量同步：下载 updatedAt > lastSyncTime 的变更，包含墓碑删除
  /// - isFullSync：是否强制执行本地对齐删除
  ///   - true：把云端结果视为当前全集，清理本地残留
  ///   - false：仅消费拉下来的数据，不因云端缺失删除本地
  /// 
  /// 返回：下载和合并统计信息
  /// 
  /// 错误处理：网络错误直接抛出，让用户看到错误提示
  Future<DownloadSyncStats> _downloadRemoteData(User user, {DateTime? lastSyncTime, bool isFullSync = false}) async {
    final performFullSync = isFullSync || lastSyncTime == null;

    // 下载并合并记录
    final recordDownloadResult = await _recordSyncService.downloadAndMergeRecords(
      user,
      lastSyncTime: lastSyncTime,
      isFullSync: performFullSync,
    );

    final storyLineDownloadResult = await _storyLineSyncService.downloadAndMergeStoryLines(
      user,
      lastSyncTime: lastSyncTime,
      isFullSync: performFullSync,
    );

    final checkInDownloadResult = await _checkInSyncService.downloadAndMergeCheckIns(
      user,
      lastSyncTime: lastSyncTime,
      isFullSync: performFullSync,
    );

    return DownloadSyncStats(
      records: recordDownloadResult.downloadedRecords,
      storyLines: storyLineDownloadResult.downloadedStoryLines,
      checkIns: checkInDownloadResult.downloadedCheckIns,
      mergedRecords: recordDownloadResult.mergedRecords,
      mergedStoryLines: storyLineDownloadResult.mergedStoryLines,
      mergedCheckIns: checkInDownloadResult.mergedCheckIns,
    );
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
  /// 返回：本次实际新解锁的成就数量
  /// 
  /// 注意：成就同步失败不影响其他数据同步，但应记录错误便于调试
  Future<int> _syncAchievementUnlocks(User user) async {
    return await _achievementSyncService.syncAchievementUnlocks(user);
  }
  
  /// 同步会员信息
  ///
  /// 会员数据以服务端为真源：
  /// - 云端存在 → 覆盖本地
  /// - 云端不存在 → 删除本地残留
  ///
  /// 返回：服务端最新会员信息；云端不存在时返回 null
  Future<Membership?> refreshMembership(User user) async {
    return await _membershipSyncService.refreshMembership(user);
  }

  /// 同步会员信息
  Future<void> _syncMembership(User user) async {
    await _membershipSyncService.syncMembership(user);
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
    await _userSettingsSyncService.syncUserSettings(user);
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

