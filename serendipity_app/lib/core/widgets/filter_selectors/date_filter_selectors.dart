import 'package:flutter/material.dart';

/// 时间范围选择器
/// 
/// 职责：提供开始日期和结束日期选择
/// 
/// 调用者：各筛选对话框
class TimeRangeSelector extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;

  const TimeRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      if (isStartDate) {
        onStartDateChanged(picked);
      } else {
        final endOfDay = picked.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        onEndDateChanged(endOfDay);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _selectDate(context, true),
            child: Text(startDate != null ? '${startDate!.month}-${startDate!.day}' : '开始日期'),
          ),
        ),
        const SizedBox(width: 8),
        const Text('至'),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _selectDate(context, false),
            child: Text(endDate != null ? '${endDate!.month}-${endDate!.day}' : '结束日期'),
          ),
        ),
      ],
    );
  }
}

