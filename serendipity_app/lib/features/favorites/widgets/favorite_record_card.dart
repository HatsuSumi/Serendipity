import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/story_lines_provider.dart';
import '../../../core/theme/status_color_extension.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/utils/record_helper.dart';
import '../../../models/encounter_record.dart';
import '../../record/create_record_page.dart';
import '../../record/record_detail_page.dart';

class FavoriteRecordCard extends ConsumerWidget {
  final EncounterRecord record;
  final bool isDeleted;
  final VoidCallback onUnfavorite;

  const FavoriteRecordCard({
    super.key,
    required this.record,
    required this.isDeleted,
    required this.onUnfavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final statusColor = record.status.getColor(context, ref);
    final borderAlpha = isDeleted ? 0.2 : 0.3;
    final labelAlpha = isDeleted ? 0.6 : 1.0;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(record.status.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.status.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor.withValues(alpha: labelAlpha),
                  ),
                ),
              ),
              Text(
                '创建：${DateTimeHelper.formatRelativeTime(record.createdAt)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isDeleted)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleMenuAction(context, ref, value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  RecordHelper.getLocationText(record.location),
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDeleted ? colorScheme.onSurfaceVariant : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (record.description != null && record.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.description!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (record.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: record.tags.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDeleted ? 0.08 : 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag.tag,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor.withValues(alpha: isDeleted ? 0.7 : 1.0),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '发生：${DateTimeHelper.formatRelativeTime(record.timestamp)}',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!isDeleted && record.createdAt != record.updatedAt) ...[
                      Text(
                        ' | ',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '更新：${DateTimeHelper.formatRelativeTime(record.updatedAt)}',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isDeleted) ...[
                Text(
                  '该记录已被删除',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (record.storyLineId != null) ...[
                _FavoriteRecordStoryLineInfo(storyLineId: record.storyLineId!),
                const SizedBox(width: 4),
              ],
              GestureDetector(
                onTap: onUnfavorite,
                child: Icon(
                  Icons.bookmark,
                  size: 16,
                  color: colorScheme.primary.withValues(alpha: isDeleted ? 0.5 : 1.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withValues(alpha: borderAlpha),
          width: 2,
        ),
      ),
      child: isDeleted
          ? content
          : InkWell(
              onTap: () => NavigationHelper.pushWithTransition(
                context,
                ref,
                RecordDetailPage(record: record),
              ),
              borderRadius: BorderRadius.circular(16),
              child: content,
            ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        NavigationHelper.pushWithTransition(
          context,
          ref,
          CreateRecordPage(recordToEdit: record),
        );
        break;
    }
  }
}

class _FavoriteRecordStoryLineInfo extends ConsumerWidget {
  final String storyLineId;

  const _FavoriteRecordStoryLineInfo({required this.storyLineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyLines = ref.watch(storyLinesProvider).valueOrNull ?? [];
    final storyLine = storyLines.where((item) => item.id == storyLineId).firstOrNull;
    if (storyLine == null) {
      return const SizedBox.shrink();
    }

    final primary = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_stories, size: 12, color: primary),
        const SizedBox(width: 4),
        Text(
          storyLine.name,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: primary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

