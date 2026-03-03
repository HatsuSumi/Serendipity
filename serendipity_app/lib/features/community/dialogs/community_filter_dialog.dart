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
            // 时间范围
            Row(
              children: [
                Text(
                  '时间范围',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.help_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: _showTimeFilterHelpDialog,
                  tooltip: '时间说明',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTimeRangeSelector(),
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
  Widget _buildTimeRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _selectDate(isStartDate: true),
            child: Text(_startDate != null
                ? '${_startDate!.month}-${_startDate!.day}'
                : '开始日期'),
          ),
        ),
        const SizedBox(width: 8),
        const Text('至'),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _selectDate(isStartDate: false),
            child: Text(_endDate != null
                ? '${_endDate!.month}-${_endDate!.day}'
                : '结束日期'),
          ),
        ),
      ],
    );
  }

  /// 选择日期
  Future<void> _selectDate({required bool isStartDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// 构建场所类型选择器
  Widget _buildPlaceTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PlaceType.values.map((type) {
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
    );
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

  /// 显示时间筛选帮助对话框
  void _showTimeFilterHelpDialog() {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('💡 '),
            Expanded(
              child: Text(
                '时间说明',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '这里的时间是指：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '别人错过 TA 的时间',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '不是指发布到社区的时间',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '举例说明：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildHelpItem(
              context,
              '小明在 2月1日 错过了 TA',
              '但直到 2月10日 才发布到社区',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '筛选时间范围为 2月1日 - 2月5日：',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '会显示这条帖子（因为错过时间是 2月1日）',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  /// 构建帮助项
  Widget _buildHelpItem(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

