import 'package:flutter/material.dart';

import '../../../models/enums.dart';

/// 标签输入框
/// 
/// 职责：提供标签输入和解析
/// 
/// 调用者：各筛选对话框
class TagInputField extends StatelessWidget {
  final TextEditingController controller;

  const TagInputField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: '输入标签名称，多个标签用逗号分隔',
        helperText: '支持中英文逗号（, 或 ，）',
        helperMaxLines: 1,
        border: OutlineInputBorder(),
        isDense: true,
      ),
      maxLines: 2,
    );
  }
}

/// 标签匹配模式选择器
/// 
/// 职责：提供全词匹配复选框
/// 
/// 调用者：各筛选对话框
class TagMatchModeSelector extends StatelessWidget {
  final TagMatchMode matchMode;
  final ValueChanged<TagMatchMode> onChanged;

  const TagMatchModeSelector({
    super.key,
    required this.matchMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: const Text('全词匹配'),
      subtitle: const Text('勾选后只匹配完整标签，不勾选则匹配包含关键词的标签'),
      value: matchMode == TagMatchMode.wholeWord,
      onChanged: (checked) {
        onChanged(checked == true ? TagMatchMode.wholeWord : TagMatchMode.contains);
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

