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
  PlaceType? _selectedPlaceType;
  EncounterStatus? _selectedStatus;
  final TextEditingController _tagController = TextEditingController();
  SelectedRegion? _selectedRegion;

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
            Text(
              '错过时间',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildTimeRangeSelector(isPublishTime: false),
            const SizedBox(height: 16),

            // 发布时间范围
            Text(
              '发布时间',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildTimeRangeSelector(isPublishTime: true),
            const SizedBox(height: 16),

            // 场所类型
            Text(
              '场所类型',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildPlaceTypeSelector(),
            const SizedBox(height: 16),

            // 状态
            Text(
              '状态',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusSelector(),
            const SizedBox(height: 16),

            // 标签
            Text(
              '标签',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                hintText: '输入标签名称',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // 地区
            Text(
              '地区',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildRegionSelector(theme),
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
            _publishEndDate = picked;
          }
        } else {
          if (isStartDate) {
            _startDate = picked;
          } else {
            _endDate = picked;
          }
        }
      });
    }
  }

  /// 构建场所类型选择器
  Widget _buildPlaceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlaceType.values.take(10).map((type) {
            final isSelected = _selectedPlaceType == type;
            return FilterChip(
              label: Text('${type.icon} ${type.label}'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedPlaceType = selected ? type : null;
                });
              },
            );
          }).toList(),
        ),
        if (PlaceType.values.length > 10)
          TextButton(
            onPressed: _showPlaceTypeDialog,
            child: const Text('查看全部场所类型 →'),
          ),
      ],
    );
  }

  /// 显示场所类型选择对话框
  Future<void> _showPlaceTypeDialog() async {
    final selected = await DialogHelper.show<PlaceType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择场所类型'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: PlaceType.values.map((type) {
              return ListTile(
                leading: Text(type.icon, style: const TextStyle(fontSize: 24)),
                title: Text(type.label),
                selected: _selectedPlaceType == type,
                onTap: () => Navigator.of(context).pop(type),
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
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    
    if (selected != null || selected == null && _selectedPlaceType != null) {
      setState(() {
        _selectedPlaceType = selected;
      });
    }
  }

  /// 构建状态选择器
  Widget _buildStatusSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: EncounterStatus.values.map((status) {
        final isSelected = _selectedStatus == status;
        return FilterChip(
          label: Text('${status.icon} ${status.label}'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedStatus = selected ? status : null;
            });
          },
        );
      }).toList(),
    );
  }

  /// 应用筛选
  Future<void> _applyFilter() async {
    Navigator.of(context).pop();

    await ref.read(communityProvider.notifier).filterPosts(
          startDate: _startDate,
          endDate: _endDate,
          publishStartDate: _publishStartDate,
          publishEndDate: _publishEndDate,
          province: _selectedRegion?.province,
          city: _selectedRegion?.city,
          area: _selectedRegion?.area,
          placeType: _selectedPlaceType,
          status: _selectedStatus,
          tag: _tagController.text.trim().isEmpty ? null : _tagController.text.trim(),
        );
  }

  /// 清除筛选
  Future<void> _clearFilter() async {
    Navigator.of(context).pop();
    await ref.read(communityProvider.notifier).clearFilter();
  }
}

