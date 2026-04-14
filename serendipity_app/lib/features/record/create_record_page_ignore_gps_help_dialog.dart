part of 'create_record_page.dart';

extension _CreateRecordPageIgnoreGpsHelpDialog on _CreateRecordPageState {
  void _showIgnoreGPSHelpDialog(BuildContext context) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('💡 '),
            Expanded(
              child: Text(
                '为什么要忽略GPS？',
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
                '延迟记录场景',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '通勤路上擦肩而过的瞬间，往往无法立即记录：',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                context,
                '早上在地铁站看到 TA',
                '当时在赶路，没时间掏出手机（走路一般不看手机）',
              ),
              const SizedBox(height: 8),
              _buildHelpItem(
                context,
                '回到公司/家后才想起来记录',
                '此时GPS定位已经变成了公司/家的地址',
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
                      '✅ 勾选"忽略GPS定位"后：',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '不会保存当前的GPS坐标\n'
                      '只使用你手动输入的地点名称\n'
                      '适合延迟记录的场景',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '注意：时间字段也会自动获取当前时间，延迟记录时记得手动调整。',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '提示：路上快速看一眼时间，比看具体地点更快更安全。',
                            style: TextStyle(
                              fontSize: 13,
                              color: _colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
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
              Text(
                '💡 编辑模式下的"事后补救"',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '如果昨天延迟记录时GPS定位错了，今天又路过同一地点：',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildHelpItem(
                context,
                '打开昨天的记录进入编辑模式',
                '点击"重新定位"按钮获取正确的GPS坐标',
              ),
              const SizedBox(height: 8),
              _buildHelpItem(
                context,
                '或者如果想清除错误的GPS数据',
                '勾选"忽略GPS定位"，只保留地点名称',
              ),
              const SizedBox(height: 16),
              Divider(
                color: _colorScheme.outline.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '❓ 既然位置可能不准，为什么不提供地图选点功能？',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'amap_flutter_map 和 amap_flutter_base 包使用了 Dart 2.x 时代的 hashValues() 方法，该方法在 Dart 3.x 中已被移除。所有版本的高德地图 Flutter 插件都未更新以支持 Dart 3.x，导致无法编译。暂时无法提供地图选点功能。',
                style: TextStyle(
                  fontSize: 13,
                  color: _colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '目前的替代方案：\n'
                'GPS 自动定位 + 手动输入地点名称\n'
                '使用"忽略 GPS"+ 完全手动输入\n'
                '使用地点历史记录快速选择\n'
                '编辑模式下"事后补救"重新定位',
                style: TextStyle(
                  fontSize: 13,
                  color: _colorScheme.onSurfaceVariant,
                  height: 1.5,
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

