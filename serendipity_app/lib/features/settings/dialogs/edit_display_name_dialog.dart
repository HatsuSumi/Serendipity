import 'package:flutter/material.dart';
import '../../../core/utils/message_helper.dart';

/// 修改昵称 Dialog
///
/// 使用 StatefulWidget 管理 TextEditingController 生命周期，
/// 避免外部 controller 在 dialog 关闭后被 dispose 引发断言。
class EditDisplayNameDialog extends StatefulWidget {
  final String initialName;
  final void Function(String) onChanged;

  const EditDisplayNameDialog({
    super.key,
    required this.initialName,
    required this.onChanged,
  });

  @override
  State<EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<EditDisplayNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _controller.addListener(() => widget.onChanged(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_controller.text.trim().isEmpty) {
      MessageHelper.showWarning(context, '昵称不能为空');
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('修改昵称'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        decoration: const InputDecoration(
          hintText: '请输入昵称',
          border: OutlineInputBorder(),
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: const Text('确认'),
        ),
      ],
    );
  }
}

