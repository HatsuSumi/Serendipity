import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../models/region_data.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/widgets/common_filter_widgets.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/my_posts_filter_provider.dart';

/// 我的帖子筛选对话框
/// 
/// 职责：
/// - 提供我的帖子特定的筛选条件选择
/// - 应用筛选
/// - 清除筛选
/// 
/// 调用者：MyPostsPage（筛选按钮）
/// 
/// 筛选字段：
/// - 时间范围（发生时间）
/// - 发布时间范围
/// - 场所类型
/// - 状态
/// - 标签
/// - 地区
class MyPostsFilterDialog extends ConsumerStatefulWidget {
  const MyPostsFilterDialog({super.key});

  @override
  ConsumerState<MyPostsFilterDialog> createState() => _MyPostsFilterDialogState();

  /// 显示对话框（静态方法）
  /// 
  /// 调用者：MyPostsPage._showFilterDialog()
  static Future<void> show(BuildContext context) async {
    await DialogHelper.show(
      context: context,
      builder: (context) => const MyPostsFilterDialog(),
    );
  }
}

class _MyPostsFilterDialogState extends ConsumerState<MyPostsFilterDialog> {
  // 筛选条件
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _publishStartDate;
  DateTime? _publishEndDate;
  Set<PlaceType> _selectedPlaceTypes = {};
  Set<EncounterStatus> _selectedStatuses = {};
  final TextEditingController _tagController = TextEditingController();
  SelectedRegion? _selectedRegion;

  @override
  void initState() {
    super.initState();
    // 延迟到第一帧后读取，确保 Provider 已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeFromProvider();
      }
    });
  }

  /// 从 Provider 读取筛选条件并初始化
  void _initializeFromProvider() {
    final criteria = ref.read(myPostsFilterProvider);
    
    setState(() {
      _startDate = criteria.startDate;
      _endDate = criteria.endDate;
      _publishStartDate = criteria.publishStartDate;
      _publishEndDate = criteria.publishEndDate;
      _selectedPlaceTypes = criteria.placeTypes?.toSet() ?? {};
      _selectedStatuses = criteria.statuses?.toSet() ?? {};
      _tagController.text = criteria.tags?.join(', ') ?? '';
      
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('筛选我的帖子'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 发生时间
            FilterSection(
              title: '发生时间',
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
              child: TagInputField(controller: _tagController),
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
  Future<void> _applyFilter() async {
    Navigator.of(context).pop();

    final tags = parseTags(_tagController.text.trim());

    await ref.read(myPostsProvider.notifier).filterPosts(
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
        );
  }

  /// 清除筛选
  Future<void> _clearFilter() async {
    Navigator.of(context).pop();
    await ref.read(myPostsProvider.notifier).clearFilter();
  }
}

