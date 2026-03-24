import '../../models/statistics.dart';
import '../repositories/check_in_repository.dart';
import '../services/i_storage_service.dart';
import '../services/statistics_service.dart';
import 'i_statistics_data_source.dart';

/// 本地统计数据源
///
/// 职责：
/// - 从本地 Hive 存储读取原始数据
/// - 委托 StatisticsService 完成所有聚合计算
/// - 支持未登录（userId = null）场景
///
/// 设计原则：
/// - 单一职责：只负责本地数据读取与聚合，不处理网络
/// - 不修改输入：所有计算基于输入快照
/// - Fail Fast：存储未初始化时由 StorageService 抛出
final class LocalStatisticsDataSource implements IStatisticsDataSource {
  final IStorageService _storage;
  final CheckInRepository _checkInRepository;

  const LocalStatisticsDataSource({
    required IStorageService storage,
    required CheckInRepository checkInRepository,
  })  : _storage = storage,
        _checkInRepository = checkInRepository;

  @override
  Future<StatisticsOverview> getOverview({required String? userId}) async {
    final records = _storage.getRecordsByUser(userId);
    final storyLines = _storage.getStoryLinesByUser(userId);
    final checkIns = _storage.getCheckInsByUser(userId);

    final basic = StatisticsService.calculateBasicStatistics(records);

    // --- 故事线关联统计 ---
    final linkedRecordCount = records
        .where((r) => r.storyLineId != null && r.storyLineId!.isNotEmpty)
        .length;
    final unlinkedRecordCount = records.length - linkedRecordCount;
    final total = records.length;
    final linkedPct = total == 0 ? 0.0 : linkedRecordCount / total * 100;
    final unlinkedPct = total == 0 ? 0.0 : unlinkedRecordCount / total * 100;

    // --- 置顶统计 ---
    final pinnedRecordCount = records.where((r) => r.isPinned).length;
    final pinnedStoryLineCount = storyLines.where((s) => s.isPinned).length;

    // --- 签到统计 ---
    final totalCheckInDays = checkIns.length;
    final checkInDateRange = _checkInRepository.getCheckInDateRange(userId: userId);
    final longestStreak =
        _checkInRepository.calculateLongestConsecutiveStreak(userId: userId);

    // --- 账号注册时间（本地无法获取，由调用方在 Repository 层注入）---
    // 收藏数（本地无法统计，由调用方在 Repository 层注入）
    // 此数据源只负责本地可算的部分，favorites 与 registeredAt 留给 Repository 层补充
    return StatisticsOverview(
      basic: basic,
      storyLineCount: storyLines.length,
      linkedRecordCount: linkedRecordCount,
      unlinkedRecordCount: unlinkedRecordCount,
      linkedRecordPercentage: linkedPct,
      unlinkedRecordPercentage: unlinkedPct,
      registeredAt: null, // 由 StatisticsRepository 注入
      totalCheckInDays: totalCheckInDays,
      totalCheckInStartDate: checkInDateRange.startDate,
      totalCheckInEndDate: checkInDateRange.endDate,
      longestCheckInStreakDays: longestStreak.days,
      longestCheckInStreakStartDate: longestStreak.startDate,
      longestCheckInStreakEndDate: longestStreak.endDate,
      favoritesAvailable: false, // 由 StatisticsRepository 注入
      favoritedRecordCount: 0,   // 由 StatisticsRepository 注入
      favoritedPostCount: 0,     // 由 StatisticsRepository 注入
      pinnedRecordCount: pinnedRecordCount,
      pinnedStoryLineCount: pinnedStoryLineCount,
    );
  }

  @override
  Future<BasicStatistics> getLocalBasicStatistics({
    required String? userId,
  }) async {
    final records = _storage.getRecordsByUser(userId);
    return StatisticsService.calculateBasicStatistics(records);
  }

  @override
  Future<AdvancedStatistics> getAdvancedStatistics({
    required String? userId,
  }) async {
    final records = _storage.getRecordsByUser(userId);
    return StatisticsService.calculateAdvancedStatistics(records);
  }
}

