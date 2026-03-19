import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/enums.dart';
import '../../../models/region_data.dart';
import '../../../core/providers/community_filter_provider.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/message_helper.dart';
import '../../../core/widgets/common_filter_widgets.dart';

/// 社区筛选对话框
/// 
/// 职责：
/// - 提供筛选条件选择
/// - 应用筛选
/// - 清除筛选
/// 
/// 调用者：CommunityPage（筛选按钮）
class CommunityFilterDialog extends ConsumerStatefulWidget {
  const CommunityFilterDialog({super.key});

  @override
  ConsumerState<CommunityFilterDialog> createState() => _CommunityFilterDialogState();

  /// 显示对话框（静态方法）
  /// 
  /// 调用者：CommunityPage._showFilterDialog()
  static Future<void> show(BuildContext context) async {
    await DialogHelper.show(
      context: context,
      builder: (context) => const CommunityFilterDialog(),
    );
  }
}

class _CommunityFilterDialogState extends ConsumerState<CommunityFilterDialog> {
  // 筛选条件
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _publishStartDate;
  DateTime? _publishEndDate;
  Set<PlaceType> _selectedPlaceTypes = {};
  Set<EncounterStatus> _selectedStatuses = {};
  final TextEditingController _tagController = TextEditingController();
  SelectedRegion? _selectedRegion;
  TagMatchMode _tagMatchMode = TagMatchMode.contains;

  @override
  void initState() {
    super.initState();
        _initializeFromProvider();
  }

  /// 从 Provider 读取筛选条件并初始化
  void _initializeFromProvider() {
    final criteria = ref.read(communityFilterProvider);
    
    setState(() {
      _startDate = criteria.startDate;
      _endDate = criteria.endDate;
      _publishStartDate = criteria.publishStartDate;
      _publishEndDate = criteria.publishEndDate;
      _selectedPlaceTypes = criteria.placeTypes?.toSet() ?? {};
      _selectedStatuses = criteria.statuses?.toSet() ?? {};
      _tagController.text = criteria.tags?.join(', ') ?? '';
      _tagMatchMode = criteria.tagMatchMode;
      
      // 恢复地区选择
      if (criteria.province != null || criteria.city != null || criteria.area != null) {
        _selectedRegion = SelectedRegion(
          province: criteria.province,
          city: criteria.city,
          area: criteria.area,
        );
      }
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('筛选帖子'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 错过时间
            FilterSection(
              title: '错过时间',
              child: TimeRangeSelector(
                startDate: _startDate,
                endDate: _endDate,
                onStartDateChanged: (date) => setState(() => _startDate = date),
                onEndDateChanged: (date) => setState(() => _endDate = date),
              ),
            ),

            // 发布时间范围
            FilterSection(
              title: '发布时间',
              child: TimeRangeSelector(
                startDate: _publishStartDate,
                endDate: _publishEndDate,
                onStartDateChanged: (date) => setState(() => _publishStartDate = date),
                onEndDateChanged: (date) => setState(() => _publishEndDate = date),
              ),
            ),

            // 场所类型
            FilterSection(
              title: '场所类型',
              child: PlaceTypeSelector(
                selectedTypes: _selectedPlaceTypes,
                onTypesChanged: (types) => setState(() => _selectedPlaceTypes = types),
              ),
            ),

            // 状态
            FilterSection(
              title: '状态',
              child: StatusSelector(
                selectedStatuses: _selectedStatuses,
                onStatusesChanged: (statuses) => setState(() => _selectedStatuses = statuses),
              ),
            ),

            // 标签
            FilterSection(
              title: '标签',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TagInputField(controller: _tagController),
                  const SizedBox(height: 8),
                  TagMatchModeSelector(
                    matchMode: _tagMatchMode,
                    onChanged: (mode) => setState(() => _tagMatchMode = mode),
                  ),
                ],
              ),
            ),

            // 地区
            FilterSection(
              title: '地区',
              child: RegionSelector(
                selectedRegion: _selectedRegion,
                onRegionChanged: (region) => setState(() => _selectedRegion = region),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _clearFilter,
          child: const Text('清除筛选'),
        ),
        FilledButton(
          onPressed: _applyFilter,
          child: const Text('应用'),
        ),
      ],
    );
  }

  /// 应用筛选
  /// 
  /// 流程：
  /// 1. 验证时间范围
  /// 2. 关闭对话框
  /// 3. 更新 communityFilterProvider
  /// 4. CommunityNotifier 监听 communityFilterProvider 变化并自动过滤
  Future<void> _applyFilter() async {
    // Fail Fast：验证时间范围
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      if (mounted) {
        MessageHelper.showError(context, '错过时间：开始日期不能晚于结束日期');
      }
      return;
    }
    
    if (_publishStartDate != null && _publishEndDate != null && _publishStartDate!.isAfter(_publishEndDate!)) {
      if (mounted) {
        MessageHelper.showError(context, '发布时间：开始日期不能晚于结束日期');
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }

    final tags = parseTags(_tagController.text.trim());

    // 构建筛选条件
    final criteria = CommunityFilterCriteria(
      startDate: _startDate,
      endDate: _endDate,
      publishStartDate: _publishStartDate,
      publishEndDate: _publishEndDate,
      province: _selectedRegion?.province,
      city: _selectedRegion?.city,
      area: _selectedRegion?.area,
      placeTypes: _selectedPlaceTypes.isEmpty ? null : _selectedPlaceTypes.toList(),
      statuses: _selectedStatuses.isEmpty ? null : _selectedStatuses.toList(),
      tags: tags,
      tagMatchMode: _tagMatchMode,
    );

    // 更新 Provider，CommunityNotifier 会自动监听并过滤
    ref.read(communityFilterProvider.notifier).updateFilter(criteria);
  }

  /// 清除筛选
  /// 
  /// 流程：
  /// 1. 关闭对话框
  /// 2. 清除 communityFilterProvider
  /// 3. CommunityNotifier 监听变化并恢复全部帖子
  Future<void> _clearFilter() async {
    Navigator.of(context).pop();
    ref.read(communityFilterProvider.notifier).clearFilter();
  }
}
