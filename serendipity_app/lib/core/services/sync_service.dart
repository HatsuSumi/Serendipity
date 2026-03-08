import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/check_in_record.dart';
import '../../models/user.dart';
import '../config/app_config.dart';
import '../repositories/i_remote_data_repository.dart';
import '../repositories/test_remote_data_repository.dart';
import '../repositories/custom_server_remote_data_repository.dart';
import '../providers/auth_provider.dart';
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
           mergedCheckIns > 0;
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
  
  SyncService({
    required IRemoteDataRepository remoteRepository,
    required IStorageService storageService,
  })  : _remoteRepository = remoteRepository,
        _storageService = storageService;
  
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
  
  /// 全量同步：上传本地数据到云端，下载云端数据到本地
  /// 
  /// 调用者：
  /// - AuthProvider：用户登录成功后自动调用
  /// - SettingsPage：手动同步按钮
  /// 
  /// 同步策略：
  /// 1. 上传本地所有记录和故事线到云端
  /// 2. 下载云端所有数据到本地
  /// 3. 合并数据（最后更新时间优先）
  /// 
  /// 返回：同步结果统计
  /// 
  /// Fail Fast：
  /// - user 为 null：抛出 ArgumentError
  /// - 网络错误：向上抛出异常
  Future<SyncResult> syncAllData(User user) async {
    // Fail Fast：参数验证
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    // 1. 上传本地数据到云端
    final uploadStats = await _uploadLocalData(user);
    
    // 2. 下载云端数据到本地
    final downloadStats = await _downloadRemoteData(user);
    
    // 3. 返回同步结果统计
    return SyncResult(
      uploadedRecords: uploadStats['records'] ?? 0,
      uploadedStoryLines: uploadStats['storyLines'] ?? 0,
      uploadedCheckIns: uploadStats['checkIns'] ?? 0,
      downloadedRecords: downloadStats['records'] ?? 0,
      downloadedStoryLines: downloadStats['storyLines'] ?? 0,
      downloadedCheckIns: downloadStats['checkIns'] ?? 0,
      mergedRecords: downloadStats['mergedRecords'] ?? 0,
      mergedStoryLines: downloadStats['mergedStoryLines'] ?? 0,
      mergedCheckIns: downloadStats['mergedCheckIns'] ?? 0,
    );
  }
  
  /// 上传本地数据到云端
  /// 
  /// 调用者：syncAllData()
  /// 
  /// 返回：上传统计信息
  Future<Map<String, int>> _uploadLocalData(User user) async {
    // 获取本地所有记录
    final localRecords = _storageService.getRecordsSortedByTime();
    
    // 批量上传记录
    if (localRecords.isNotEmpty) {
      await _remoteRepository.uploadRecords(user.id, localRecords);
    }
    
    // 获取本地所有故事线
    final localStoryLines = _storageService.getAllStoryLines();
    
    // 批量上传故事线
    if (localStoryLines.isNotEmpty) {
      await _remoteRepository.uploadStoryLines(user.id, localStoryLines);
    }
    
    // 获取本地所有签到记录
    final localCheckIns = _storageService.getAllCheckIns();
    
    // 批量上传签到记录
    if (localCheckIns.isNotEmpty) {
      await _remoteRepository.uploadCheckIns(user.id, localCheckIns);
    }
    
    return {
      'records': localRecords.length,
      'storyLines': localStoryLines.length,
      'checkIns': localCheckIns.length,
    };
  }
  
  /// 下载云端数据到本地
  /// 
  /// 调用者：syncAllData()
  /// 
  /// 返回：下载和合并统计信息
  Future<Map<String, int>> _downloadRemoteData(User user) async {
    int mergedRecords = 0;
    int mergedStoryLines = 0;
    int mergedCheckIns = 0;
    
    // 下载云端记录
    final remoteRecords = await _remoteRepository.downloadRecords(user.id);
    
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
    
    // 下载云端故事线
    final remoteStoryLines = await _remoteRepository.downloadStoryLines(user.id);
    
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
    
    // 下载云端签到记录
    final remoteCheckIns = await _remoteRepository.downloadCheckIns(user.id);
    
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
}

/// 数据同步服务 Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    remoteRepository: ref.read(remoteDataRepositoryProvider),
    storageService: ref.read(storageServiceProvider),
  );
});

