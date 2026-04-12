import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/statistics.dart';
import '../../models/enums.dart';
import '../config/app_config.dart';
import '../repositories/local_statistics_data_source.dart';
import '../repositories/remote_statistics_data_source.dart';
import '../repositories/statistics_repository.dart';
import 'auth_provider.dart';
import 'check_in_provider.dart';
import 'favorites_provider.dart';
import 'membership_provider.dart';
import 'records_provider.dart';

// ---------------------------------------------------------------------------
// UI 状态 Providers（与数据源无关的纯 UI 状态）
// ---------------------------------------------------------------------------

/// 字段排名维度筛选 Provider
///
/// 控制字段排名表格当前展示哪个维度
final fieldRankingDimensionProvider =
    StateProvider<FieldRankingDimension>((ref) => FieldRankingDimension.weather);

/// 月度图表状态筛选 Provider
///
/// null = 全部状态，非 null = 仅显示该状态
final monthlyStatusFilterProvider = StateProvider<EncounterStatus?>((ref) => null);

/// 月度记录数图表时间范围 Provider
///
/// 控制月度记录数图表使用最近12个月还是全部月份。
final monthlyChartRangeProvider =
    StateProvider<StatisticsChartRange>((ref) => StatisticsChartRange.last12Months);

/// 成功率趋势图表时间范围 Provider
///
/// 控制成功率趋势图表使用最近12个月还是全部月份。
final successRateChartRangeProvider =
    StateProvider<StatisticsChartRange>((ref) => StatisticsChartRange.last12Months);

/// 状态统计视图模式 Provider
///
/// true = 列表视图，false = 饼图视图
final statusViewModeProvider = StateProvider<bool>((ref) => true);

// ---------------------------------------------------------------------------
// Infrastructure Providers
// ---------------------------------------------------------------------------

/// 本地统计数据源 Provider
final _localStatisticsDataSourceProvider = Provider<LocalStatisticsDataSource>((ref) {
  return LocalStatisticsDataSource(
    storage: ref.read(storageServiceProvider),
    checkInRepository: ref.read(checkInRepositoryProvider),
  );
});

/// 远端统计数据源 Provider
final _remoteStatisticsDataSourceProvider = Provider<RemoteStatisticsDataSource>((ref) {
  return RemoteStatisticsDataSource(
    httpClient: ref.read(httpClientServiceProvider),
  );
});

/// 统计仓储 Provider
///
/// 统计层的唯一入口；所有统计 Provider 均通过此仓储获取数据。
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(
    local: ref.read(_localStatisticsDataSourceProvider),
    remote: ref.read(_remoteStatisticsDataSourceProvider),
  );
});

// ---------------------------------------------------------------------------
// Data Providers
// ---------------------------------------------------------------------------

/// 统计页总览 Provider
///
/// 职责：
/// - 通过 StatisticsRepository 获取总览数据
/// - 注入账号级字段（registeredAt、favorites）
/// - 自动响应 recordsProvider、syncCompletedProvider、favoritesProvider、authProvider 的变化
///
/// 设计原则：
/// - Provider 层不做聚合计算，只负责依赖编排与参数准备
/// - 账号级字段由 Provider 层从对应 Provider 读取后注入 Repository
final statisticsOverviewProvider = FutureProvider<StatisticsOverview>((ref) async {
  // 监听记录/同步/认证/收藏相关依赖变化，变化时自动重算
  ref.watch(recordsProvider);
  ref.watch(syncCompletedProvider);

  final currentUser = ref.watch(authProvider).value;
  final repository = ref.read(statisticsRepositoryProvider);

  // 收藏数据：仅登录后可用
  // 口径与“我的收藏”页面一致：包含仍存在的收藏条目 + 已删除但仍保留收藏关系的条目
  int favoritedRecordCount = 0;
  int favoritedPostCount = 0;
  if (currentUser != null) {
    try {
      final favoritesState = await ref.watch(favoritesProvider.future);
      favoritedRecordCount =
          favoritesState.favoritedRecords.length + favoritesState.deletedFavoritedRecords.length;
      favoritedPostCount =
          favoritesState.favoritedPosts.length + favoritesState.deletedFavoritedPosts.length;
    } catch (_) {
      // 收藏加载失败不影响统计总览展示
    }
  }

  return repository.getOverview(
    currentUser: currentUser,
    favoritedRecordCount: favoritedRecordCount,
    favoritedPostCount: favoritedPostCount,
  );
});

/// 基础统计 Provider
///
/// 提供 BasicStatistics 供不需要完整 StatisticsOverview 的场景使用。
/// 依赖 statisticsOverviewProvider，避免重复计算。
final basicStatisticsProvider = FutureProvider<BasicStatistics>((ref) async {
  final overview = await ref.watch(statisticsOverviewProvider.future);
  return overview.basic;
});

/// 高级统计 Provider（会员版）
///
/// 职责：
/// - 会员权限检查（非会员返回 null）
/// - 通过 StatisticsRepository 获取图表数据
/// - 自动响应 recordsProvider 与 membershipProvider 的变化
///
/// 设计原则：
/// - 权限门控留在 Provider 层，Repository 层不感知会员状态
final advancedStatisticsProvider = FutureProvider<AdvancedStatistics?>((ref) async {
  final membershipAsync = ref.watch(membershipProvider);

  final isPremium = AppConfig.isDeveloperMode ||
      await membershipAsync.when(
        data: (m) async => m.isPremium,
        loading: () async => false,
        error: (_, _) async => false,
      );

  if (!isPremium) return null;

  // 监听记录变化，记录更新时自动重算图表
  ref.watch(recordsProvider);
  ref.watch(syncCompletedProvider);

  final currentUser = ref.watch(authProvider).value;
  final repository = ref.read(statisticsRepositoryProvider);

  return repository.getAdvancedStatistics(currentUser: currentUser);
});

/// 基础统计摘要 Provider
///
/// 提供统计数据的简化版本（总数、各状态数、成功率），
/// 直接复用 basicStatisticsProvider，避免重复计算。
final statisticsSummaryProvider = FutureProvider<({
  int total,
  int met,
  int reunion,
  double successRate,
})>((ref) async {
  final stats = await ref.watch(basicStatisticsProvider.future);
  return (
    total: stats.totalRecords,
    met: stats.metCount,
    reunion: stats.reunionCount,
    successRate: stats.successRate,
  );
});
