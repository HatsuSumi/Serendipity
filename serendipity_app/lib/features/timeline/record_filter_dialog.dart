import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../models/region_data.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/widgets/common_filter_widgets.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/records_filter_provider.dart';

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
      _descriptionController.text = criteria.descriptionKeyword ?? '';
      _ifReencounterController.text = criteria.ifReencounterKeyword ?? '';
      _conversationStarterController.text = criteria.conversationStarterKeyword ?? '';
      _backgroundMusicController.text = criteria.backgroundMusicKeyword ?? '';
      
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

            // 描述关键词
            FilterSection(
              title: '描述关键词',
              child: TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: '输入关键词搜索描述',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 1,
              ),
            ),

            // 如果再遇备忘关键词
            FilterSection(
              title: '如果再遇备忘',
              child: TextField(
                controller: _ifReencounterController,
                decoration: const InputDecoration(
                  hintText: '输入关键词搜索',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 1,
              ),
            ),

            // 对话契机关键词
            FilterSection(
              title: '对话契机',
              child: TextField(
                controller: _conversationStarterController,
                decoration: const InputDecoration(
                  hintText: '输入关键词搜索',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 1,
              ),
            ),

            // 背景音乐关键词
            FilterSection(
              title: '背景音乐',
              child: TextField(
                controller: _backgroundMusicController,
                decoration: const InputDecoration(
                  hintText: '输入关键词搜索',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 1,
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
    final descriptionKeyword = _descriptionController.text.trim().isEmpty 
        ? null 
        : _descriptionController.text.trim();
    final ifReencounterKeyword = _ifReencounterController.text.trim().isEmpty
        ? null
        : _ifReencounterController.text.trim();
    final conversationStarterKeyword = _conversationStarterController.text.trim().isEmpty
        ? null
        : _conversationStarterController.text.trim();
    final backgroundMusicKeyword = _backgroundMusicController.text.trim().isEmpty
        ? null
        : _backgroundMusicController.text.trim();

    await ref.read(recordsProvider.notifier).filterRecords(
          startDate: _startDate,
          endDate: _endDate,
          createdStartDate: _createdStartDate,
          createdEndDate: _createdEndDate,
          province: _selectedRegion?.province,
          city: _selectedRegion?.city,
          area: _selectedRegion?.area,
          placeTypes: _selectedPlaceTypes.isEmpty ? null : _selectedPlaceTypes.toList(),
          statuses: _selectedStatuses.isEmpty ? null : _selectedStatuses.toList(),
          emotionIntensities: _selectedIntensities.isEmpty ? null : _selectedIntensities.toList(),
          weathers: _selectedWeathers.isEmpty ? null : _selectedWeathers.toList(),
          tags: tags,
          tagMatchMode: _tagMatchMode,
          descriptionKeyword: descriptionKeyword,
          ifReencounterKeyword: ifReencounterKeyword,
          conversationStarterKeyword: conversationStarterKeyword,
          backgroundMusicKeyword: backgroundMusicKeyword,
        );
  }

  /// 清除筛选
  Future<void> _clearFilter() async {
    Navigator.of(context).pop();
    await ref.read(recordsProvider.notifier).clearRecordsFilter();
  }
}

