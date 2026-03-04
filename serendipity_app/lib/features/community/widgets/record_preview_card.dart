import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/encounter_record.dart';
import '../../../core/utils/record_helper.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/theme/status_color_extension.dart';

/// 记录预览卡片
/// 
/// 用于在发布确认对话框中显示记录预览
/// 复用 TA 页面的卡片样式，但简化版（无菜单、无点击）
/// 
/// 调用者：PublishConfirmDialog
class RecordPreviewCard extends ConsumerWidget {
  final EncounterRecord record;
  final Widget? trailing; // 可选的尾部组件（如警告标识）

  const RecordPreviewCard({
    super.key,
    required this.record,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = record.status.getColor(context, ref);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态和时间
            Row(
              children: [
                Text(
                  record.status.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.status.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                Text(
                  '创建：${DateTimeHelper.formatRelativeTime(record.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 地点
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    RecordHelper.getLocationText(record.location),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // 描述（如果有）
            if (record.description != null && record.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                record.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // 标签（如果有，最多显示3个）
            if (record.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: record.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag.tag,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // 底部时间和尾部组件
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '发生：${DateTimeHelper.formatRelativeTime(record.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

