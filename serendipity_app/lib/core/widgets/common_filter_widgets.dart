import 'package:flutter/material.dart';

export 'filter_selectors.dart';
export 'filter_text_utils.dart';
export 'highlighted_text.dart';

/// 筛选区块组件
/// 
/// 职责：统一的筛选区块样式
/// 
/// 调用者：各筛选对话框
class FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const FilterSection({
    super.key,
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
