import '../../models/statistics.dart';

/// 统计数据源抽象接口
///
/// 职责：
/// - 定义获取统计总览与高级图表的统一契约
/// - 屏蔽本地聚合与远端 API 之间的差异
///
/// 实现：
/// - LocalStatisticsDataSource：基于本地 Hive 数据聚合
/// - RemoteStatisticsDataSource：基于后端 /statistics/overview 接口
///
/// 设计原则：
/// - 依赖倒置（DIP）：上层仓储依赖此接口，不依赖具体实现
/// - 接口隔离（ISP）：overview 与 charts 分开，允许各自独立迁移
abstract interface class IStatisticsDataSource {
  /// 获取统计总览
  ///
  /// 包含：注册时间、记录数、故事线数、签到摘要、收藏数、置顶数、
  ///       各状态计数、成功率、已关联/未关联故事线记录等。
  ///
  /// 参数：
  /// - userId：当前用户 ID，null 表示未登录（仅返回本地离线数据）
  Future<StatisticsOverview> getOverview({required String? userId});

  /// 获取高级图表统计数据（会员功能）
  ///
  /// 包含：标签词云、月度分布、情绪分布、天气分布、场所分布、
  ///       成功率趋势、字段排名。
  ///
  /// 参数：
  /// - userId：当前用户 ID，null 表示未登录
  Future<AdvancedStatistics> getAdvancedStatistics({required String? userId});
}

