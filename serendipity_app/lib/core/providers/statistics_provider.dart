import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/statistics.dart';
import '../../models/enums.dart';
import '../config/app_config.dart';
import '../services/statistics_service.dart';
import 'records_provider.dart';
import 'membership_provider.dart';

/// 月度图表状态筛选 Provider
/// 
/// null = 全部状态，非 null = 仅显示该状态
final monthlyStatusFilterProvider = StateProvider<EncounterStatus?>((ref) => null);

/// 状态统计视图模式 Provider
/// 
/// true = 列表视图，false = 饼图视图
final statusViewModeProvider = StateProvider<bool>((ref) => true);

/// 基础统计 Provider
/// 
/// 职责：
/// - 依赖 recordsProvider，自动响应数据变化
/// - 计算基础统计数据
/// - 支持异步加载和错误处理
/// 
/// 设计原则：
/// - 单一职责：只负责基础统计的状态管理
/// - 自动响应：监听 recordsProvider 变化，自动重新计算
/// - 依赖倒置：依赖 StatisticsService，不依赖具体的计算逻辑
/// 
/// 调用者：
/// - StatisticsPage：UI 层
/// - AdvancedStatisticsProvider：高级统计依赖
final basicStatisticsProvider = FutureProvider<BasicStatistics>((ref) async {
  // 监听记录列表变化
  final recordsAsync = ref.watch(recordsProvider);
  
  // 等待记录列表加载完成
  final records = await recordsAsync.when(
    data: (data) async => data,
    loading: () async => throw Exception('Records loading'),
    error: (error, stack) async => throw error,
  );
  
  // 计算基础统计
  return StatisticsService.calculateBasicStatistics(records);
});

/// 高级统计 Provider（会员版）
/// 
/// 职责：
/// - 依赖 basicStatisticsProvider 和 membershipProvider
/// - 计算高级统计数据（仅会员可用）
/// - 支持异步加载和错误处理
/// 
/// 设计原则：
/// - 单一职责：只负责高级统计的状态管理
/// - 权限检查：检查用户是否为会员，非会员返回 null
/// - 自动响应：监听 recordsProvider 和 membershipProvider 变化
/// 
/// 调用者：
/// - StatisticsPage：UI 层（会员功能部分）
final advancedStatisticsProvider = FutureProvider<AdvancedStatistics?>((ref) async {
  // 检查用户是否为会员
  final membershipAsync = ref.watch(membershipProvider);
  // 检查用户是否为会员（开发者模式下直接放行）
  final isPremium = AppConfig.isDeveloperMode || await membershipAsync.when(
    data: (membership) async => membership.isPremium,
    loading: () async => false,
    error: (error, stackTrace) async => false,
  );
  
  // 非会员返回 null
  if (!isPremium) {
    return null;
  }
  
  // 监听记录列表变化
  final recordsAsync = ref.watch(recordsProvider);
  
  // 等待记录列表加载完成
  final records = await recordsAsync.when(
    data: (data) async => data,
    loading: () async => throw Exception('Records loading'),
    error: (error, stack) async => throw error,
  );
  
  // 计算高级统计
  return StatisticsService.calculateAdvancedStatistics(records);
});

/// 基础统计摘要 Provider
/// 
/// 职责：
/// - 提供统计数据的简化版本（用于卡片展示）
/// - 包含：总数、各状态数、成功率
/// 
/// 设计原则：
/// - 单一职责：只提供摘要数据，不提供完整统计
/// - 性能优化：避免重复计算，直接依赖 basicStatisticsProvider
/// 
/// 调用者：
/// - StatisticsPage：UI 层（摘要卡片）
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

