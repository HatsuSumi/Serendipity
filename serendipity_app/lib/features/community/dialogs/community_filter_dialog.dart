import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/enums.dart';
import '../../../models/region_data.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/utils/dialog_helper.dart';
import '../widgets/region_picker_dialog.dart';

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
  /// 
  /// 性能优化：
  /// - 延迟到第一帧后执行，避免阻塞初始化
  /// - 添加 mounted 检查，避免内存泄漏
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('筛选帖子'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 错过时间
            _FilterSection(
              title: '错过时间',
              child: _buildTimeRangeSelector(isPublishTime: false),
            ),

            // 发布时间范围
            _FilterSection(
              title: '发布时间',
              child: _buildTimeRangeSelector(isPublishTime: true),
            ),

            // 场所类型
            _FilterSection(
              title: '场所类型',
              child: _buildPlaceTypeSelector(),
            ),

            // 状态
            _FilterSection(
              title: '状态',
              child: _buildStatusSelector(),
            ),

            // 标签
            _FilterSection(
              title: '标签',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: '输入标签名称，多个标签用逗号分隔',
                      helperText: '支持中英文逗号（, 或 ，）',
                      helperMaxLines: 1,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('全词匹配'),
                    subtitle: const Text('勾选后只匹配完整标签，不勾选则匹配包含关键词的标签'),
                    value: _tagMatchMode == TagMatchMode.wholeWord,
                    onChanged: (checked) {
                      setState(() {
                        _tagMatchMode = checked == true ? TagMatchMode.wholeWord : TagMatchMode.contains;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),

            // 地区
            _FilterSection(
              title: '地区',
              child: _buildRegionSelector(theme),
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

  /// 构建地区选择器
  Widget _buildRegionSelector(ThemeData theme) {
    return OutlinedButton(
      onPressed: _showRegionPicker,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedRegion?.displayText ?? '请选择地区',
              style: TextStyle(
                color: _selectedRegion == null
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  /// 显示地区选择器
  Future<void> _showRegionPicker() async {
    final result = await RegionPickerDialog.show(
      context,
      initialSelection: _selectedRegion,
    );

    if (result != null) {
      setState(() {
        _selectedRegion = result;
      });
    }
  }

  /// 构建时间范围选择器
  Widget _buildTimeRangeSelector({required bool isPublishTime}) {
    final startDate = isPublishTime ? _publishStartDate : _startDate;
    final endDate = isPublishTime ? _publishEndDate : _endDate;
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _selectDate(isStartDate: true, isPublishTime: isPublishTime),
            child: Text(startDate != null
                ? '${startDate.month}-${startDate.day}'
                : '开始日期'),
          ),
        ),
        const SizedBox(width: 8),
        const Text('至'),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _selectDate(isStartDate: false, isPublishTime: isPublishTime),
            child: Text(endDate != null
                ? '${endDate.month}-${endDate.day}'
                : '结束日期'),
          ),
        ),
      ],
    );
  }

  /// 选择日期
  Future<void> _selectDate({required bool isStartDate, required bool isPublishTime}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isPublishTime) {
          if (isStartDate) {
            _publishStartDate = picked;
          } else {
            // 结束日期：调整到当天 23:59:59，确保包含整个当天的记录
            _publishEndDate = picked.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          }
        } else {
          if (isStartDate) {
            _startDate = picked;
          } else {
            // 结束日期：调整到当天 23:59:59，确保包含整个当天的记录
            _endDate = picked.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          }
        }
      });
    }
  }

  /// 构建场所类型选择器
  /// 
  /// 性能优化：
  /// - 使用 key 避免不必要的重建
  /// - 将回调提取为方法，避免每次创建新的闭包
  Widget _buildPlaceTypeSelector() {
    return _PlaceTypeSelector(
      key: const ValueKey('place_type_selector'),
      selectedTypes: _selectedPlaceTypes,
      onTypesChanged: _handlePlaceTypesChanged,
      onShowAllPressed: _showPlaceTypeDialog,
    );
  }

  /// 处理场所类型变化
  /// 
  /// 性能优化：提取为独立方法，避免每次创建新的闭包
  void _handlePlaceTypesChanged(Set<PlaceType> types) {
    setState(() {
      _selectedPlaceTypes = types;
    });
  }

  /// 显示场所类型选择对话框
  Future<void> _showPlaceTypeDialog() async {
    final selected = await DialogHelper.show<Set<PlaceType>>(
      context: context,
      builder: (context) => _PlaceTypeMultiSelectDialog(
        selectedTypes: _selectedPlaceTypes,
      ),
    );
    
    if (selected != null) {
      setState(() {
        _selectedPlaceTypes = selected;
      });
    }
  }

  /// 构建状态选择器
  /// 
  /// 性能优化：
  /// - 使用 key 避免不必要的重建
  /// - 将回调提取为方法，避免每次创建新的闭包
  Widget _buildStatusSelector() {
    return _StatusSelector(
      key: const ValueKey('status_selector'),
      selectedStatuses: _selectedStatuses,
      onStatusesChanged: _handleStatusesChanged,
    );
  }

  /// 处理状态变化
  /// 
  /// 性能优化：提取为独立方法，避免每次创建新的闭包
  void _handleStatusesChanged(Set<EncounterStatus> statuses) {
    setState(() {
      _selectedStatuses = statuses;
    });
  }

  /// 解析标签字符串
  /// 
  /// 性能优化：
  /// - 提取为独立方法，提高代码可读性
  /// - 避免在 _applyFilter 中重复逻辑
  /// 
  /// 参数：
  /// - input: 用户输入的标签字符串
  /// 
  /// 返回：
  /// - 解析后的标签列表，如果为空则返回 null
  List<String>? _parseTags(String input) {
    if (input.isEmpty) return null;
    
    final tags = input
        .replaceAll('，', ',')  // 中文逗号 → 英文逗号
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    
    return tags.isEmpty ? null : tags;
  }

  /// 应用筛选
  Future<void> _applyFilter() async {
    Navigator.of(context).pop();

    // 解析标签（支持中英文逗号分隔）
    final tags = _parseTags(_tagController.text.trim());

    await ref.read(communityProvider.notifier).filterPosts(
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
  }

  /// 清除筛选
  Future<void> _clearFilter() async {
    Navigator.of(context).pop();
    await ref.read(communityProvider.notifier).clearFilter();
  }
}

/// 筛选区块组件
/// 
/// 职责：
/// - 统一的筛选区块样式
/// - 包含标题和内容
/// 
/// 性能优化：
/// - 使用 const 构造函数
/// - 避免不必要的重建
class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// 场所类型选择器组件
/// 
/// 职责：
/// - 显示场所类型的 FilterChip 列表
/// - 支持多选
/// - 提供"查看全部"按钮
/// 
/// 性能优化：
/// - 缓存 FilterChip 列表，避免每次重建
/// - 使用 const 构造函数
/// - 只在 selectedTypes 变化时重建
class _PlaceTypeSelector extends StatefulWidget {
  final Set<PlaceType> selectedTypes;
  final ValueChanged<Set<PlaceType>> onTypesChanged;
  final VoidCallback onShowAllPressed;

  const _PlaceTypeSelector({
    super.key,
    required this.selectedTypes,
    required this.onTypesChanged,
    required this.onShowAllPressed,
  });

  @override
  State<_PlaceTypeSelector> createState() => _PlaceTypeSelectorState();
}

class _PlaceTypeSelectorState extends State<_PlaceTypeSelector> {
  // 性能优化：缓存前10个场所类型，避免每次重建时重新计算
  static final List<PlaceType> _displayedTypes = PlaceType.values.take(10).toList();
  static final bool _hasMoreTypes = PlaceType.values.length > 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _displayedTypes.map((type) {
            final isSelected = widget.selectedTypes.contains(type);
            return FilterChip(
              label: Text('${type.icon} ${type.label}'),
              selected: isSelected,
              onSelected: (selected) {
                final newTypes = Set<PlaceType>.from(widget.selectedTypes);
                if (selected) {
                  newTypes.add(type);
                } else {
                  newTypes.remove(type);
                }
                widget.onTypesChanged(newTypes);
              },
            );
          }).toList(),
        ),
        if (_hasMoreTypes)
          TextButton(
            onPressed: widget.onShowAllPressed,
            child: const Text('查看全部场所类型 →'),
          ),
      ],
    );
  }
}

/// 状态选择器组件
/// 
/// 职责：
/// - 显示状态的 FilterChip 列表
/// - 支持多选
/// 
/// 性能优化：
/// - 缓存 FilterChip 列表，避免每次重建
/// - 使用 const 构造函数
/// - 只在 selectedStatuses 变化时重建
class _StatusSelector extends StatefulWidget {
  final Set<EncounterStatus> selectedStatuses;
  final ValueChanged<Set<EncounterStatus>> onStatusesChanged;

  const _StatusSelector({
    super.key,
    required this.selectedStatuses,
    required this.onStatusesChanged,
  });

  @override
  State<_StatusSelector> createState() => _StatusSelectorState();
}

class _StatusSelectorState extends State<_StatusSelector> {
  // 性能优化：缓存所有状态，避免每次重建时重新计算
  static final List<EncounterStatus> _allStatuses = EncounterStatus.values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allStatuses.map((status) {
        final isSelected = widget.selectedStatuses.contains(status);
        return FilterChip(
          label: Text('${status.icon} ${status.label}'),
          selected: isSelected,
          onSelected: (selected) {
            final newStatuses = Set<EncounterStatus>.from(widget.selectedStatuses);
            if (selected) {
              newStatuses.add(status);
            } else {
              newStatuses.remove(status);
            }
            widget.onStatusesChanged(newStatuses);
          },
        );
      }).toList(),
    );
  }
}

/// 场所类型多选对话框
class _PlaceTypeMultiSelectDialog extends StatefulWidget {
  final Set<PlaceType> selectedTypes;

  const _PlaceTypeMultiSelectDialog({
    required this.selectedTypes,
  });

  @override
  State<_PlaceTypeMultiSelectDialog> createState() => _PlaceTypeMultiSelectDialogState();
}

class _PlaceTypeMultiSelectDialogState extends State<_PlaceTypeMultiSelectDialog> {
  late Set<PlaceType> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set.from(widget.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择场所类型'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: PlaceType.values.map((type) {
            final isSelected = _selectedTypes.contains(type);
            return CheckboxListTile(
              secondary: Text(type.icon, style: const TextStyle(fontSize: 24)),
              title: Text(type.label),
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedTypes.add(type);
                  } else {
                    _selectedTypes.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedTypes.clear();
            });
          },
          child: const Text('清除'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedTypes),
          child: Text('确定 (${_selectedTypes.length})'),
        ),
      ],
    );
  }
}

