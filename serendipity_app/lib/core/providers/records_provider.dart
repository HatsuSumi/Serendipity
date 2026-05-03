import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../repositories/record_repository.dart';
import '../repositories/story_line_repository.dart';
import 'auth_provider.dart';
import 'records_filter_provider.dart';

/// 自动同步完成信号
/// 
/// 每次自动同步（App启动/网络恢复/轮询）完成后递增，
/// 让 recordsProvider / storyLinesProvider / checkInProvider 自动刷新。
final syncCompletedProvider = StateProvider<int>((ref) => 0);

/// 记录仓储 Provider
final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(ref.read(storageServiceProvider));
});

/// 故事线仓储 Provider（用于 RecordsProvider）
final storyLineRepositoryProvider = Provider<StoryLineRepository>((ref) {
  return StoryLineRepository(ref.read(storageServiceProvider));
});

/// 每页加载条数
const int _kPageSize = 20;

/// 记录列表状态管理
/// 
/// 职责：
/// - 管理记录列表状态
/// - 监听筛选条件变化并自动过滤
/// - 处理分页与刷新
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责记录列表管理
/// - 依赖倒置（DIP）：依赖 recordsFilterProvider，不依赖具体的筛选UI
/// - 自动响应：监听 recordsFilterProvider 变化，自动过滤
/// 
/// 分页策略：
/// - 无筛选时：分页加载，每页 [_kPageSize] 条，滚动到底触发 loadMore()
/// - 筛选激活时：全量加载后过滤，保证筛选语义正确（从所有数据中筛选）
class RecordsNotifier extends AsyncNotifier<List<EncounterRecord>> {
  late RecordRepository _repository;

  /// 当前已加载条数（无筛选模式下使用）
  int _loadedCount = _kPageSize;

  /// 是否还有更多数据可加载
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<EncounterRecord>> build() async {
    _repository = ref.read(recordRepositoryProvider);

    // 监听自动同步完成信号，信号变化时自动重建
    ref.watch(syncCompletedProvider);

    // 监听筛选条件变化，自动重新过滤
    final filterCriteria = ref.watch(recordsFilterProvider);

    // 筛选条件变化时重置分页状态
    _loadedCount = _kPageSize;
    _hasMore = true;

    // 获取当前登录用户
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    final userId = currentUser?.id;

    // 全量数据（Hive 全量读取，无法在存储层分页）
    final allRecords = _repository.getRecordsByUser(userId);

    // 筛选激活：全量过滤，不分页
    if (filterCriteria.isActive) {
      _hasMore = false;
      return applyFilterCriteria(allRecords, filterCriteria);
    }

    // 无筛选：只返回第一页
    _hasMore = allRecords.length > _loadedCount;
    return allRecords.take(_loadedCount).toList();
  }

  /// 加载更多记录（仅无筛选模式下有效）
  ///
  /// 调用者：TimelinePage 滚动到底部时
  Future<void> loadMore() async {
    final filterCriteria = ref.read(recordsFilterProvider);
    // 筛选激活时不分页
    if (filterCriteria.isActive || !_hasMore) return;
    // 正在加载中时不重复触发
    if (state.isLoading) return;

    final currentUser = await ref.read(authProvider.notifier).currentUser;
    final userId = currentUser?.id;
    final allRecords = _repository.getRecordsByUser(userId);

    _loadedCount += _kPageSize;
    _hasMore = allRecords.length > _loadedCount;

    // 用新数据替换 state，不触发 loading
    state = AsyncData(allRecords.take(_loadedCount).toList());
  }

  /// 应用筛选条件到记录列表
  ///
  /// 职责：
  /// - 根据筛选条件过滤记录
  /// - 支持多条件组合（AND 逻辑）
  ///
  /// 设计原则：
  /// - 循环不变量前置：所有与单条记录无关的计算在循环外完成
  /// - Fail Fast：条件不合法时直接返回空列表
  /// - 不修改原列表：返回新列表
  ///
  /// 调用者：build() / recordsCountProvider
  List<EncounterRecord> applyFilterCriteria(
    List<EncounterRecord> records,
    RecordsFilterCriteria criteria,
  ) {
    // 预计算循环不变量（只计算一次，不在每条记录里重复计算）
    final placeTypeSet = criteria.placeTypes?.isNotEmpty == true
        ? Set<PlaceType>.from(criteria.placeTypes!)
        : null;
    final statusSet = criteria.statuses?.isNotEmpty == true
        ? Set<EncounterStatus>.from(criteria.statuses!)
        : null;
    final emotionSet = criteria.emotionIntensities?.isNotEmpty == true
        ? Set<EmotionIntensity>.from(criteria.emotionIntensities!)
        : null;
    final weatherSet = criteria.weathers?.isNotEmpty == true
        ? Set<Weather>.from(criteria.weathers!)
        : null;
    final tagList = criteria.tags?.isNotEmpty == true ? criteria.tags! : null;
    final isWholeWord = criteria.tagMatchMode == TagMatchMode.wholeWord;
    // 关键词全部转小写，避免在每条记录里重复调用 toLowerCase()
    final descKeywords = criteria.descriptionKeywords?.isNotEmpty == true
        ? criteria.descriptionKeywords!.map((keyword) => keyword.toLowerCase()).toList()
        : null;
    final placeNameKeywords = criteria.placeNameKeywords?.isNotEmpty == true
        ? criteria.placeNameKeywords!.map((keyword) => keyword.toLowerCase()).toList()
        : null;
    final reencounterKeywords = criteria.ifReencounterKeywords?.isNotEmpty == true
        ? criteria.ifReencounterKeywords!.map((keyword) => keyword.toLowerCase()).toList()
        : null;
    final conversationKeywords = criteria.conversationStarterKeywords?.isNotEmpty == true
        ? criteria.conversationStarterKeywords!.map((keyword) => keyword.toLowerCase()).toList()
        : null;
    final musicKeywords = criteria.backgroundMusicKeywords?.isNotEmpty == true
        ? criteria.backgroundMusicKeywords!.map((keyword) => keyword.toLowerCase()).toList()
        : null;

    return records.where((record) {
      // 时间范围筛选（错过时间）
      if (criteria.startDate != null && record.timestamp.isBefore(criteria.startDate!)) {
        return false;
      }
      if (criteria.endDate != null && record.timestamp.isAfter(criteria.endDate!)) {
        return false;
      }

      // 创建时间范围筛选
      if (criteria.createdStartDate != null && record.createdAt.isBefore(criteria.createdStartDate!)) {
        return false;
      }
      if (criteria.createdEndDate != null && record.createdAt.isAfter(criteria.createdEndDate!)) {
        return false;
      }

      // 场所类型筛选（Set O(1) 查找）
      if (placeTypeSet != null && !placeTypeSet.contains(record.location.placeType)) {
        return false;
      }

      // 状态筛选（Set O(1) 查找）
      if (statusSet != null && !statusSet.contains(record.status)) {
        return false;
      }

      // 情绪强度筛选（Set O(1) 查找）
      if (emotionSet != null && !emotionSet.contains(record.emotion)) {
        return false;
      }

      // 天气筛选（Set O(1) 查找）
      if (weatherSet != null && !record.weather.any(weatherSet.contains)) {
        return false;
      }

      // 地区筛选
      if (criteria.province != null && record.location.province != criteria.province) {
        return false;
      }
      if (criteria.city != null && record.location.city != criteria.city) {
        return false;
      }
      if (criteria.area != null && record.location.area != criteria.area) {
        return false;
      }

      // 地点名称关键词筛选
      if (placeNameKeywords != null) {
        final recordPlaceName = (record.location.placeName ?? '').toLowerCase();
        if (!placeNameKeywords.any(recordPlaceName.contains)) {
          return false;
        }
      }

      // 标签筛选
      // - 全词匹配：record tags 转 Set，O(1) 查找
      // - 包含匹配：线性扫描，但 tagMatchMode 判断已提到循环外
      if (tagList != null) {
        final bool hasMatch;
        if (isWholeWord) {
          final recordTagSet = record.tags.map((t) => t.tag).toSet();
          hasMatch = tagList.any(recordTagSet.contains);
        } else {
          hasMatch = tagList.any(
            (kw) => record.tags.any((t) => t.tag.contains(kw)),
          );
        }
        if (!hasMatch) return false;
      }

      // 描述关键词筛选（关键词已预转小写）
      if (descKeywords != null) {
        final recordDescription = (record.description ?? '').toLowerCase();
        if (!descKeywords.any(recordDescription.contains)) {
          return false;
        }
      }

      // 如果再遇备忘关键词筛选
      if (reencounterKeywords != null) {
        final recordIfReencounter = (record.ifReencounter ?? '').toLowerCase();
        if (!reencounterKeywords.any(recordIfReencounter.contains)) {
          return false;
        }
      }

      // 对话契机关键词筛选
      if (conversationKeywords != null) {
        final recordConversationStarter = (record.conversationStarter ?? '').toLowerCase();
        if (!conversationKeywords.any(recordConversationStarter.contains)) {
          return false;
        }
      }

      // 背景音乐关键词筛选
      if (musicKeywords != null) {
        final recordBackgroundMusic = (record.backgroundMusic ?? '').toLowerCase();
        if (!musicKeywords.any(recordBackgroundMusic.contains)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// 刷新记录列表
  ///
  /// 使用 invalidateSelf() 让 build() 重新执行，自动应用当前筛选条件。
  /// 这样无论筛选状态如何，刷新后的数据都与 recordsFilterProvider 保持同步。
  ///
  /// 调用者：
  /// - TimelinePage（下拉刷新）
  /// - saveRecord / updateRecord / deleteRecord / togglePin（操作后刷新）
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// 静默刷新记录列表（不显示 loading 状态）
  ///
  /// 用于操作后的后台刷新，避免页面闪烁。
  /// 与 refresh() 的区别：不触发 loading 状态，当前数据在刷新期间保持可见。
  Future<void> refreshSilently() async {
    if (state.value == null) {
      await refresh();
      return;
    }
    // 保留当前数据，invalidateSelf 触发 build() 重新执行
    ref.invalidateSelf();
    // 等待新数据加载完成，期间 state 保持旧值不触发 loading
    await future;
  }
}

/// 记录列表 Provider
final recordsProvider = AsyncNotifierProvider<RecordsNotifier, List<EncounterRecord>>(() {
  return RecordsNotifier();
});

/// 记录统计 Provider
/// 
/// 计算当前用户在当前筛选条件下的记录总数。
///
/// 设计说明：
/// - 直接依赖仓储层与筛选条件，而不是依赖分页后的 recordsProvider
/// - 无筛选时返回真实总数；有筛选时返回筛选后的总数
/// - 与列表分页职责分离，避免 UI 标题被“已加载条数”污染
final recordsCountProvider = FutureProvider<int>((ref) async {
  ref.watch(syncCompletedProvider);
  final filterCriteria = ref.watch(recordsFilterProvider);
  final repository = ref.watch(recordRepositoryProvider);
  final currentUser = await ref.read(authProvider.notifier).currentUser;
  final userId = currentUser?.id;
  final allRecords = repository.getRecordsByUser(userId);

  if (!filterCriteria.isActive) {
    return allRecords.length;
  }

  final recordsNotifier = ref.read(recordsProvider.notifier);
  return recordsNotifier.applyFilterCriteria(allRecords, filterCriteria).length;
});
