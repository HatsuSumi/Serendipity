import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../models/region_data.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/validation_helper.dart';
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
  Set<PlaceType> _selectedPlaceTypes = {};
  Set<EncounterStatus> _selectedStatuses = {};
  Set<EmotionIntensity> _selectedIntensities = {};
  Set<Weather> _selectedWeathers = {};
  final TextEditingController _tagController = TextEditingController();

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
    final criteria = ref.read(recordsFilterProvider);
    
    setState(() {
      _startDate = criteria.startDate;
      _endDate = criteria.endDate;
      _selectedPlaceTypes = criteria.placeTypes?.toSet() ?? {};
      _selectedStatuses = criteria.statuses?.toSet() ?? {};
      _selectedIntensities = criteria.emotionIntensities?.toSet() ?? {};
      _selectedWeathers = criteria.weathers?.toSet() ?? {};
      _tagController.text = criteria.tags?.join(', ') ?? '';
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
      title: const Text('筛选记录'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间范围
            FilterSection(
              title: '发生时间',
              child: TimeRangeSelector(
                startDate: _startDate,
                endDate: _endDate,
                onStartDateChanged: (date) => setState(() => _startDate = date),
                onEndDateChanged: (date) => setState(() => _endDate = date),
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
              child: TagInputField(controller: _tagController),
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

    await ref.read(recordsProvider.notifier).filterRecords(
          startDate: _startDate,
          endDate: _endDate,
          placeTypes: _selectedPlaceTypes.isEmpty ? null : _selectedPlaceTypes.toList(),
          statuses: _selectedStatuses.isEmpty ? null : _selectedStatuses.toList(),
          emotionIntensities: _selectedIntensities.isEmpty ? null : _selectedIntensities.toList(),
          weathers: _selectedWeathers.isEmpty ? null : _selectedWeathers.toList(),
          tags: tags,
        );
  }

  /// 清除筛选
  Future<void> _clearFilter() async {
    Navigator.of(context).pop();
    await ref.read(recordsProvider.notifier).clearRecordsFilter();
  }
}

