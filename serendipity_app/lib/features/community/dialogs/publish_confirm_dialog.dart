import 'package:flutter/material.dart';
import '../../../models/encounter_record.dart';
import '../widgets/record_preview_card.dart';

/// 发布状态枚举
enum PublishStatus {
  canPublish,      // 可以发布（未发布过）
  needConfirm,     // 需要确认（已发布，内容已变化）
  cannotPublish,   // 不能发布（已发布，内容未变化）
}

/// 记录发布状态
class RecordPublishInfo {
  final EncounterRecord record;
  final PublishStatus status;

  RecordPublishInfo({
    required this.record,
    required this.status,
  });
}

/// 发布确认对话框
/// 
/// 职责：
/// - 显示将要发布的记录列表
/// - 按状态分组显示（新发布、替换旧帖、跳过）
/// - 用户确认后返回 true，取消返回 false
/// 
/// 调用者：PublishToCommunityDialog._handleConfirm()
class PublishConfirmDialog extends StatelessWidget {
  final List<RecordPublishInfo> records;

  const PublishConfirmDialog({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    // Fail Fast: 参数验证
    if (records.isEmpty) {
      throw ArgumentError('records cannot be empty');
    }

    // 按状态分组
    final canPublish = records.where((r) => r.status == PublishStatus.canPublish).toList();
    final needConfirm = records.where((r) => r.status == PublishStatus.needConfirm).toList();
    final cannotPublish = records.where((r) => r.status == PublishStatus.cannotPublish).toList();

    final willPublishCount = canPublish.length + needConfirm.length;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(context),

            const Divider(height: 1),

            // 可滚动内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 总结
                    _buildSummary(context, canPublish.length, needConfirm.length, cannotPublish.length),

                    const SizedBox(height: 16),

                    // 新发布分组
                    if (canPublish.isNotEmpty) ...[
                      _buildSectionHeader(context, '✅ 新发布', canPublish.length),
                      const SizedBox(height: 8),
                      ...canPublish.map((info) => RecordPreviewCard(record: info.record)),
                      const SizedBox(height: 16),
                    ],

                    // 替换旧帖分组
                    if (needConfirm.isNotEmpty) ...[
                      _buildSectionHeader(context, '⚠️ 替换旧帖', needConfirm.length),
                      const SizedBox(height: 8),
                      ...needConfirm.map((info) => RecordPreviewCard(record: info.record)),
                      const SizedBox(height: 16),
                    ],

                    // 跳过分组
                    if (cannotPublish.isNotEmpty) ...[
                      _buildSectionHeader(context, '❌ 跳过', cannotPublish.length),
                      const SizedBox(height: 8),
                      ...cannotPublish.map((info) => RecordPreviewCard(
                            record: info.record,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '内容未变化',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // 底部按钮
            _buildBottomBar(context, willPublishCount, canPublish.length, needConfirm.length),
          ],
        ),
      ),
    );
  }

  /// 标题栏
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '发布确认',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  /// 总结
  Widget _buildSummary(BuildContext context, int newCount, int replaceCount, int skipCount) {
    return Text(
      '共选择 ${records.length} 条记录',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
    );
  }

  /// 分组标题
  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Text(
      '$title（$count条）',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /// 底部按钮栏
  Widget _buildBottomBar(BuildContext context, int willPublishCount, int newCount, int replaceCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 说明文字
          Text(
            '将发布 $willPublishCount 条记录（$newCount条新发布，$replaceCount条替换旧帖）',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // 按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: willPublishCount > 0
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: const Text('确认发布'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

