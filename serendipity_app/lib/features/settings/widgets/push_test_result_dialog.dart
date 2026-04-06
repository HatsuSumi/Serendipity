import 'package:flutter/material.dart';

import '../../../core/services/push_models.dart';

class PushTestResultDialog extends StatelessWidget {
  const PushTestResultDialog({
    super.key,
    required this.result,
  });

  final ServerPushTestResult result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('推送测试结果'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.message),
          if (result.details != null && result.details!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(result.details!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('我知道了'),
        ),
      ],
    );
  }
}

