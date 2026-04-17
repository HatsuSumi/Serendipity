import 'package:flutter/material.dart';

import '../../../core/utils/auth_error_helper.dart';

class FavoritesPageErrorState extends StatelessWidget {
  final Object error;
  final Future<void> Function() onRetry;

  const FavoritesPageErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('加载失败：${AuthErrorHelper.extractErrorMessage(error)}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

