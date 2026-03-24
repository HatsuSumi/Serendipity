import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/statistics.dart';
import '../../models/user.dart';
import '../config/app_config.dart';
import '../services/http_client_service.dart';
import 'i_statistics_data_source.dart';

/// 统计仓储
///
/// 职责：
/// - 作为统计层的唯一入口，屏蔽本地与远端数据源的差异
/// - 管理统计数据来源策略：登录状态下优先尝试远端，失败后降级本地
/// - 注入本地数据源无法计算的账号级字段（registeredAt、favorites）
/// - 支持未登录离线场景
///
/// 策略规则：
/// - 未登录：始终使用本地数据源
/// - 已登录：优先使用远端数据源；远端不可用时自动降级为本地数据源
///
/// 设计原则：
/// - 依赖倒置（DIP）：依赖 IStatisticsDataSource 抽象，不依赖具体数据源
/// - 单一职责（SRP）：只负责策略选择与字段注入，不做聚合计算
/// - 容错降级：远端不可用时静默降级，保持离线能力
final class StatisticsRepository {
  final IStatisticsDataSource _local;
  final IStatisticsDataSource _remote;

  const StatisticsRepository({
    required IStatisticsDataSource local,
    required IStatisticsDataSource remote,
  })  : _local = local,
        _remote = remote;

  // ---------------------------------------------------------------------------
  // Overview
  // ---------------------------------------------------------------------------

  /// 获取统计总览
  ///
  /// 字段注入策略：
  /// - registeredAt：从传入的 [currentUser] 读取，与数据源无关
  /// - favoritesAvailable / favoritedRecordCount / favoritedPostCount：
  ///   由调用方（Provider 层）传入，保持与 favoritesProvider 数据一致
  ///
  /// 参数：
  /// - currentUser：当前登录用户，null 表示未登录
  /// - favoritedRecordCount：已收藏记录数，由 favoritesProvider 提供
  /// - favoritedPostCount：已收藏帖子数，由 favoritesProvider 提供
  Future<StatisticsOverview> getOverview({
    required User? currentUser,
    required int favoritedRecordCount,
    required int favoritedPostCount,
  }) async {
    final userId = currentUser?.id;
    final favoritesAvailable = currentUser != null;

    // 选择数据源并获取基础 overview（已登录时优先尝试远端）
    final base = await _fetchOverview(userId: userId);

    // 注入本地数据源无法填充的账号级字段
    return _injectAccountFields(
      base: base,
      registeredAt: currentUser?.createdAt,
      favoritesAvailable: favoritesAvailable,
      favoritedRecordCount: favoritedRecordCount,
      favoritedPostCount: favoritedPostCount,
    );
  }

  // ---------------------------------------------------------------------------
  // Advanced Statistics
  // ---------------------------------------------------------------------------

  /// 获取高级图表统计数据
  ///
  /// 权限门控由调用方（Provider 层）完成，此方法不做会员检查。
  ///
  /// 参数：
  /// - currentUser：当前登录用户，null 表示未登录
  Future<AdvancedStatistics> getAdvancedStatistics({
    required User? currentUser,
  }) async {
    final userId = currentUser?.id;
    return await _fetchAdvancedStatistics(userId: userId);
  }

  // ---------------------------------------------------------------------------
  // Private: source selection
  // ---------------------------------------------------------------------------

  /// 选择数据源并获取 overview
  ///
  /// - 未登录：直接使用本地
  /// - 开发者模式强制本地：直接使用本地（便于调试）
  /// - 已登录：优先远端，UnsupportedError / Exception 时静默降级本地
  Future<StatisticsOverview> _fetchOverview({required String? userId}) async {
    if (userId == null || AppConfig.forceLocalStatistics) {
      return _local.getOverview(userId: userId);
    }

    try {
      return await _remote.getOverview(userId: userId);
    } on UnsupportedError {
      // 远端接口尚未实现，静默降级
      return _local.getOverview(userId: userId);
    } on HttpException {
      // HTTP 4xx/5xx，静默降级（服务端暂不可用）
      return _local.getOverview(userId: userId);
    } on TimeoutException {
      // 请求超时，静默降级
      return _local.getOverview(userId: userId);
    } on SocketException {
      // 网络不通，静默降级
      return _local.getOverview(userId: userId);
    } on http.ClientException {
      // HTTP 客户端层错误（DNS 失败等），静默降级
      return _local.getOverview(userId: userId);
    }
    // 其他异常（编程错误、本地存储异常等）继续向上传播
  }

  /// 选择数据源并获取高级统计
  ///
  /// 图表类统计短期内始终使用本地；
  /// 远端返回 UnsupportedError 时静默降级。
  Future<AdvancedStatistics> _fetchAdvancedStatistics({
    required String? userId,
  }) async {
    // 图表类统计短期内始终本地优先
    if (userId == null || AppConfig.forceLocalStatistics) {
      return _local.getAdvancedStatistics(userId: userId);
    }

    try {
      return await _remote.getAdvancedStatistics(userId: userId);
    } on UnsupportedError {
      return _local.getAdvancedStatistics(userId: userId);
    } on HttpException {
      return _local.getAdvancedStatistics(userId: userId);
    } on TimeoutException {
      return _local.getAdvancedStatistics(userId: userId);
    } on SocketException {
      return _local.getAdvancedStatistics(userId: userId);
    } on http.ClientException {
      return _local.getAdvancedStatistics(userId: userId);
    }
    // 其他异常继续向上传播
  }

  // ---------------------------------------------------------------------------
  // Private: field injection
  // ---------------------------------------------------------------------------

  /// 将账号级字段注入 overview
  ///
  /// 账号级字段（registeredAt、favorites）与记录业务逻辑无关，
  /// 由 Repository 层统一注入，保持数据源职责单一。
  StatisticsOverview _injectAccountFields({
    required StatisticsOverview base,
    required DateTime? registeredAt,
    required bool favoritesAvailable,
    required int favoritedRecordCount,
    required int favoritedPostCount,
  }) {
    return StatisticsOverview(
      basic: base.basic,
      storyLineCount: base.storyLineCount,
      linkedRecordCount: base.linkedRecordCount,
      unlinkedRecordCount: base.unlinkedRecordCount,
      linkedRecordPercentage: base.linkedRecordPercentage,
      unlinkedRecordPercentage: base.unlinkedRecordPercentage,
      registeredAt: registeredAt,
      totalCheckInDays: base.totalCheckInDays,
      totalCheckInStartDate: base.totalCheckInStartDate,
      totalCheckInEndDate: base.totalCheckInEndDate,
      longestCheckInStreakDays: base.longestCheckInStreakDays,
      longestCheckInStreakStartDate: base.longestCheckInStreakStartDate,
      longestCheckInStreakEndDate: base.longestCheckInStreakEndDate,
      favoritesAvailable: favoritesAvailable,
      favoritedRecordCount: favoritedRecordCount,
      favoritedPostCount: favoritedPostCount,
      pinnedRecordCount: base.pinnedRecordCount,
      pinnedStoryLineCount: base.pinnedStoryLineCount,
    );
  }
}
