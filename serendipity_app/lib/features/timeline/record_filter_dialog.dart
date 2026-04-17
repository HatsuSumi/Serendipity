import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../models/region_data.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/widgets/common_filter_widgets.dart';
import '../../core/providers/records_filter_provider.dart';

String? _joinKeywords(List<String>? keywords) {
  if (keywords == null || keywords.isEmpty) return null;
  return keywords.join(', ');
}

/// 记录筛选对话框
/// 
/// 职责：
/// - 提供记录特定的筛选条件选择
/// - 应用筛选
/// - 清除筛选
/// 
/// 调用者：TimelinePage（筛选按钮）
/// 
/// 筛选字段：
/// - 时间范围（发生时间）
/// - 场所类型
/// - 状态
/// - 标签
/// - 天气
/// - 情绪强度
class RecordFilterDialog extends ConsumerStatefulWidget {
  const RecordFilterDialog({super.key});

  @override
  ConsumerState<RecordFilterDialog> createState() => _RecordFilterDialogState();

  /// 显示对话框（静态方法）
  /// 
  /// 调用者：TimelinePage._showFilterDialog()
  static Future<void> show(BuildContext context) async {
    await DialogHelper.show(
      context: context,
      builder: (context) => const RecordFilterDialog(),
    );
  }
}

class _RecordFilterDialogState extends ConsumerState<RecordFilterDialog> {
  // 筛选条件
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _createdStartDate;
  DateTime? _createdEndDate;
  SelectedRegion? _selectedRegion;
  Set<PlaceType> _selectedPlaceTypes = {};
  Set<EncounterStatus> _selectedStatuses = {};
  Set<EmotionIntensity> _selectedIntensities = {};
  Set<Weather> _selectedWeathers = {};
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ifReencounterController = TextEditingController();
  final TextEditingController _conversationStarterController = TextEditingController();
  final TextEditingController _backgroundMusicController = TextEditingController();
  TagMatchMode _tagMatchMode = TagMatchMode.contains;

  @override
  void initState() {
    super.initState();
    _initializeFromProvider();
  }

  /// 从 Provider 读取筛选条件并初始化
  void _initializeFromProvider() {
    final criteria = ref.read(recordsFilterProvider);
    
    setState(() {
      _startDate = criteria.startDate;
      _endDate = criteria.endDate;
      _createdStartDate = criteria.createdStartDate;
      _createdEndDate = criteria.createdEndDate;
      _selectedPlaceTypes = criteria.placeTypes?.toSet() ?? {};
      _selectedStatuses = criteria.statuses?.toSet() ?? {};
      _selectedIntensities = criteria.emotionIntensities?.toSet() ?? {};
      _selectedWeathers = criteria.weathers?.toSet() ?? {};
      _tagController.text = criteria.tags?.join(', ') ?? '';
      _tagMatchMode = criteria.tagMatchMode;
      _placeNameController.text = _joinKeywords(criteria.placeNameKeywords) ?? '';
      _descriptionController.text = _joinKeywords(criteria.descriptionKeywords) ?? '';
      _ifReencounterController.text = _joinKeywords(criteria.ifReencounterKeywords) ?? '';
      _conversationStarterController.text = _joinKeywords(criteria.conversationStarterKeywords) ?? '';
      _backgroundMusicController.text = _joinKeywords(criteria.backgroundMusicKeywords) ?? '';
      
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
    _placeNameController.dispose();
    _descriptionController.dispose();
    _ifReencounterController.dispose();
    _conversationStarterController.dispose();
    _backgroundMusicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('筛选记录'),
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

            // 创建时间
            FilterSection(
              title: '创建时间',
              child: TimeRangeSelector(
                startDate: _createdStartDate,
                endDate: _createdEndDate,
                onStartDateChanged: (date) => setState(() => _createdStartDate = date),
                onEndDateChanged: (date) => setState(() => _createdEndDate = date),
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

            // 情绪强度
            FilterSection(
              title: '情绪强度',
              child: EmotionIntensitySelector(
                selectedIntensities: _selectedIntensities,
                onIntensitiesChanged: (intensities) => setState(() => _selectedIntensities = intensities),
              ),
            ),

            // 天气
            FilterSection(
              title: '天气',
              child: WeatherSelector(
                selectedWeathers: _selectedWeathers,
                onWeathersChanged: (weathers) => setState(() => _selectedWeathers = weathers),
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

            // 地点名称关键词
            FilterSection(
              title: '地点名称',
              child: TextField(
                controller: _placeNameController,
                decoration: const InputDecoration(
                  hintText: '输入手动填写的地点名称，多个关键词用逗号分隔',
                  helperText: '支持中英文逗号（, 或 ，）',
                  helperMaxLines: 1,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ),

            // 描述关键词
            FilterSection(
              title: '描述关键词',
              child: TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: '输入关键词搜索描述，多个关键词用逗号分隔',
                  helperText: '支持中英文逗号（, 或 ，）',
                  helperMaxLines: 1,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ),

            // 如果再遇备忘关键词
            FilterSection(
              title: '如果再遇备忘',
              child: TextField(
                controller: _ifReencounterController,
                decoration: const InputDecoration(
                  hintText: '输入关键词搜索，多个关键词用逗号分隔',
                  helperText: '支持中英文逗号（, 或 ，）',
                  helperMaxLines: 1,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ),

            // 对话契机关键词
            FilterSection(
              title: '对话契机',
              child: TextField(
                controller: _conversationStarterController,
                decoration: const InputDecoration(
                  hintText: '输入关键词搜索，多个关键词用逗号分隔',
                  helperText: '支持中英文逗号（, 或 ，）',
                  helperMaxLines: 1,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ),

            // 背景音乐关键词
            FilterSection(
              title: '背景音乐',
              child: TextField(
                controller: _backgroundMusicController,
                decoration: const InputDecoration(
                  hintText: '输入关键词搜索，多个关键词用逗号分隔',
                  helperText: '支持中英文逗号（, 或 ，）',
                  helperMaxLines: 1,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
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
  /// 3. 更新 recordsFilterProvider
  /// 4. RecordsNotifier 监听 recordsFilterProvider 变化并自动过滤
  Future<void> _applyFilter() async {
    // Fail Fast：验证时间范围
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      if (mounted) {
        MessageHelper.showError(context, '错过时间：开始日期不能晚于结束日期');
      }
      return;
    }
    
    if (_createdStartDate != null && _createdEndDate != null && _createdStartDate!.isAfter(_createdEndDate!)) {
      if (mounted) {
        MessageHelper.showError(context, '创建时间：开始日期不能晚于结束日期');
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }

    final tags = parseTags(_tagController.text.trim());
    final placeNameKeywords = parseCommaSeparatedKeywords(_placeNameController.text.trim());
    final descriptionKeywords = parseCommaSeparatedKeywords(_descriptionController.text.trim());
    final ifReencounterKeywords = parseCommaSeparatedKeywords(_ifReencounterController.text.trim());
    final conversationStarterKeywords = parseCommaSeparatedKeywords(_conversationStarterController.text.trim());
    final backgroundMusicKeywords = parseCommaSeparatedKeywords(_backgroundMusicController.text.trim());

    // 构建筛选条件
    final criteria = RecordsFilterCriteria(
      startDate: _startDate,
      endDate: _endDate,
      createdStartDate: _createdStartDate,
      createdEndDate: _createdEndDate,
      province: _selectedRegion?.province,
      city: _selectedRegion?.city,
      area: _selectedRegion?.area,
      placeNameKeywords: placeNameKeywords,
      placeTypes: _selectedPlaceTypes.isEmpty ? null : _selectedPlaceTypes.toList(),
      statuses: _selectedStatuses.isEmpty ? null : _selectedStatuses.toList(),
      emotionIntensities: _selectedIntensities.isEmpty ? null : _selectedIntensities.toList(),
      weathers: _selectedWeathers.isEmpty ? null : _selectedWeathers.toList(),
      tags: tags,
      tagMatchMode: _tagMatchMode,
      descriptionKeywords: descriptionKeywords,
      ifReencounterKeywords: ifReencounterKeywords,
      conversationStarterKeywords: conversationStarterKeywords,
      backgroundMusicKeywords: backgroundMusicKeywords,
    );

    // 更新 Provider，RecordsNotifier 会自动监听并过滤
    ref.read(recordsFilterProvider.notifier).updateFilter(criteria);
  }

  /// 清除筛选
  /// 
  /// 流程：
  /// 1. 关闭对话框
  /// 2. 清除 recordsFilterProvider
  /// 3. RecordsNotifier 监听变化并恢复全部记录
  Future<void> _clearFilter() async {
    Navigator.of(context).pop();
    ref.read(recordsFilterProvider.notifier).clearFilter();
  }
}

