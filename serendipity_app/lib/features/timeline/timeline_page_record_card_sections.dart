part of 'timeline_page.dart';

extension _TimelinePageRecordCardSections on _TimelinePageState {
  Widget _buildRecordCardHeader(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
    Color statusColor,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Text(
          record.status.icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            record.status.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
        Text(
          '创建：${DateTimeHelper.formatRelativeTime(record.createdAt)}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        _buildRecordCardMenuButton(context, ref, record),
      ],
    );
  }

  Widget _buildRecordCardMenuButton(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuAction(context, ref, record, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 8),
              Text('编辑'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(record.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              const SizedBox(width: 8),
              Text(record.isPinned ? '取消置顶' : '置顶'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'link',
          child: Row(
            children: [
              Icon(Icons.auto_stories_outlined),
              SizedBox(width: 8),
              Text('关联到故事线'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.image_outlined),
              SizedBox(width: 8),
              Text('导出为图片'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'publish',
          child: Row(
            children: [
              Icon(Icons.cloud_outlined),
              SizedBox(width: 8),
              Text('发布到社区'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCardFooter(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
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
              if (record.createdAt != record.updatedAt) ...[
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
        if (record.storyLineId != null)
          _buildStoryLineInfo(context, ref, record.storyLineId!),
        Consumer(
          builder: (context, ref, _) {
            final isFavorited = ref.watch(isRecordFavoritedProvider(record.id));
            return IconButton(
              icon: Icon(
                isFavorited ? Icons.bookmark : Icons.bookmark_border,
                size: 20,
                color: colorScheme.primary,
              ),
              tooltip: isFavorited ? '取消收藏' : '收藏',
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleFavoriteRecord(context, ref, record),
            );
          },
        ),
      ],
    );
  }
}

