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
/// 
/// 性能优化：
/// - 使用 ListView.builder 替代 spread 操作符
/// - 避免每次 build 都创建所有 Widget
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
              child: _buildRecordsList(
                context,
                canPublish,
                needConfirm,
                cannotPublish,
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

  /// 构建记录列表
  /// 
  /// 性能优化：
  /// - 使用 ListView.builder 替代 spread 操作符
  /// - 只在需要时创建 Widget，避免一次性创建所有 Widget
  Widget _buildRecordsList(
    BuildContext context,
    List<RecordPublishInfo> canPublish,
    List<RecordPublishInfo> needConfirm,
    List<RecordPublishInfo> cannotPublish,
  ) {
    // 计算各分组的起始索引
    final sections = <_RecordSection>[];
    
    if (canPublish.isNotEmpty) {
      sections.add(_RecordSection(
        title: '✅ 新发布',
        count: canPublish.length,
        records: canPublish,
        showWarning: false,
      ));
    }
    
    if (needConfirm.isNotEmpty) {
      sections.add(_RecordSection(
        title: '⚠️ 替换旧帖',
        count: needConfirm.length,
        records: needConfirm,
        showWarning: false,
      ));
    }
    
    if (cannotPublish.isNotEmpty) {
      sections.add(_RecordSection(
        title: '❌ 跳过',
        count: cannotPublish.length,
        records: cannotPublish,
        showWarning: true,
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _calculateTotalItems(sections),
      itemBuilder: (context, index) {
        return _buildItem(context, sections, index);
      },
    );
  }

  /// 计算总项数（包括标题、记录、间距）
  int _calculateTotalItems(List<_RecordSection> sections) {
    int count = 1; // 总结
    
    for (final section in sections) {
      count += 1; // 分组标题
      count += section.records.length; // 记录
      count += 1; // 间距
    }
    
    return count;
  }

  /// 构建列表项
  Widget _buildItem(BuildContext context, List<_RecordSection> sections, int index) {
    int currentIndex = 0;
    
    // 总结
    if (index == currentIndex) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildSummary(context),
      );
    }
    currentIndex++;
    
    // 遍历各分组
    for (final section in sections) {
      // 分组标题
      if (index == currentIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildSectionHeader(context, section.title, section.count),
        );
      }
      currentIndex++;
      
      // 记录列表
      for (int i = 0; i < section.records.length; i++) {
        if (index == currentIndex) {
          final info = section.records[i];
          return RecordPreviewCard(
            record: info.record,
            trailing: section.showWarning
                ? Container(
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
                  )
                : null,
          );
        }
        currentIndex++;
      }
      
      // 间距
      if (index == currentIndex) {
        return const SizedBox(height: 16);
      }
      currentIndex++;
    }
    
    return const SizedBox.shrink();
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
  Widget _buildSummary(BuildContext context) {
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
    final skipCount = records.length - willPublishCount;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 说明文字
          Text(
            skipCount > 0
                ? '将发布 $willPublishCount 条记录（$newCount条新发布，$replaceCount条替换旧帖），跳过 $skipCount 条'
                : '将发布 $willPublishCount 条记录（$newCount条新发布，$replaceCount条替换旧帖）',
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

/// 记录分组
/// 
/// 性能优化：用于 ListView.builder 的数据结构
class _RecordSection {
  final String title;
  final int count;
  final List<RecordPublishInfo> records;
  final bool showWarning;

  _RecordSection({
    required this.title,
    required this.count,
    required this.records,
    required this.showWarning,
  });
}

