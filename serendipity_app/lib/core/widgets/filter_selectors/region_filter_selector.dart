import 'package:flutter/material.dart';

import '../../../models/region_data.dart';
import '../../../features/community/widgets/region_picker_dialog.dart';

/// 地区选择器
/// 
/// 职责：显示地区选择按钮
/// 
/// 调用者：各筛选对话框
class RegionSelector extends StatelessWidget {
  final SelectedRegion? selectedRegion;
  final ValueChanged<SelectedRegion?> onRegionChanged;

  const RegionSelector({
    super.key,
    required this.selectedRegion,
    required this.onRegionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: () => _showRegionPicker(context),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedRegion?.displayText ?? '请选择地区',
              style: TextStyle(
                color: selectedRegion == null
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

  Future<void> _showRegionPicker(BuildContext context) async {
    final result = await RegionPickerDialog.show(
      context,
      initialSelection: selectedRegion,
    );

    if (result != null) {
      onRegionChanged(result);
    }
  }
}

