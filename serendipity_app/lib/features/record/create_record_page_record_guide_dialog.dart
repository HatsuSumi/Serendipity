part of 'create_record_page.dart';

extension _CreateRecordPageRecordGuideDialog on _CreateRecordPageState {
  void _showRecordGuideDialog(BuildContext context) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('💡 '),
            Expanded(
              child: Text(
                '如何记录？',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '每次见面 = 一条新记录',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '例如：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildGuideItem(
                context,
                '今天在地铁看到 TA',
                '→ 创建记录，选择"错过"',
              ),
              const SizedBox(height: 8),
              _buildGuideItem(
                context,
                '明天看到 TA，但低头假装没看见',
                '→ 创建新记录，选择"回避"',
              ),
              const SizedBox(height: 8),
              _buildGuideItem(
                context,
                '后天看到 TA，鼓起勇气看了一眼（没说话）',
                '→ 创建新记录，选择"再遇"',
              ),
              const SizedBox(height: 8),
              _buildGuideItem(
                context,
                '大后天又看到 TA（还是没说话）',
                '→ 创建新记录，还是选择"再遇"',
              ),
              const SizedBox(height: 8),
              _buildGuideItem(
                context,
                '第 N 天终于说话了',
                '→ 创建新记录，选择"邂逅"',
              ),
              const SizedBox(height: 12),
              Text(
                '一直不说话，就一直选择"再遇"。',
                style: TextStyle(
                  fontSize: 13,
                  color: _colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '然后通过"故事线"功能把这些记录关联起来',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: _colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '💡 什么时候停止记录？',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '邂逅后如果继续在一起，就不用再记录了\n'
                      '但如果经历了"别离"或"失联"，之后又"重逢"，可以继续记录，即邂逅→别离/失联→重逢',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                color: _colorScheme.outline.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '关于状态间的区别详见关于页面',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
}

