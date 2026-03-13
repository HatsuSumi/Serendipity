import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/sync_history.dart';
import 'auth_provider.dart';
import 'records_provider.dart';

/// 同步历史记录 Provider
/// 
/// 职责：
/// - 从存储层读取当前用户的同步历史记录（按时间倒序）
/// - 监听 syncCompletedProvider 信号，同步完成后自动刷新
/// 
/// 遵循原则：
/// - 单一职责（SRP）：只负责提供同步历史数据
/// - 依赖倒置（DIP）：依赖 IStorageService 抽象
/// - 分层约束：UI 层通过此 Provider 读取数据，不直接接触 StorageService
/// 
/// 调用者：
/// - SyncHistoryDialog：显示历史同步记录列表
final syncHistoriesProvider = Provider<List<SyncHistory>>((ref) {
  // 监听同步完成信号，每次同步完成后自动重建
  ref.watch(syncCompletedProvider);

  final storage = ref.read(storageServiceProvider);
  return storage.getAllSyncHistories();
});

