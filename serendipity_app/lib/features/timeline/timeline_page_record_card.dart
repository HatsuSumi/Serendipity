part of 'timeline_page.dart';

extension _TimelinePageRecordCardSection on _TimelinePageState {
  /// 记录卡片
  Widget _buildRecordCard(
    BuildContext context,
    EncounterRecord record,
    WidgetRef ref,
    RecordsFilterCriteria filterCriteria,
  ) {
    // 使用主题自适应的状态颜色
    final statusColor = record.status.getColor(context, ref);
    final colorScheme = _colorScheme;
    final textTheme = _textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToRecordDetail(context, ref, record),
        // 自定义悬停动画时长（更柔和）
        hoverDuration: const Duration(milliseconds: 300),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 置顶图标（左上角）
            if (record.isPinned)
              Positioned(
                top: 8,
                left: 8,
                child: Icon(
                  Icons.push_pin,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
            // 主要内容
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecordCardHeader(
                    context,
                    ref,
                    record,
                    statusColor,
                    colorScheme,
                    textTheme,
                  ),
                  const SizedBox(height: 12),
                  _buildRecordCardContent(
                    context,
                    record,
                    filterCriteria,
                    statusColor,
                    colorScheme,
                    textTheme,
                  ),
                  if (_hasRecordCardAdditionalFields(record, filterCriteria)) ...[
                    const SizedBox(height: 12),
                    _buildRecordCardAdditionalFields(
                      context,
                      record,
                      filterCriteria,
                      statusColor,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildRecordCardFooter(
                    context,
                    ref,
                    record,
                    colorScheme,
                    textTheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建故事线信息组件
  Widget _buildStoryLineInfo(
    BuildContext context,
    WidgetRef ref,
    String storyLineId,
  ) {
    final storyLinesAsync = ref.watch(storyLinesProvider);

    return storyLinesAsync.when(
      data: (storyLines) {
        try {
          final storyLine = storyLines.firstWhere((sl) => sl.id == storyLineId);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToStoryLineDetail(context, ref, storyLineId),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories,
                      size: 12,
                      color: _colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _isMasked ? _maskText(storyLine.name) : storyLine.name,
                        style: _textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: _colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  /// 构建筛选字段显示（带标题和高亮）
  Widget _buildFilteredField(
    BuildContext context,
    String label,
    String content,
    List<String> keywords,
    Color statusColor,
  ) {
    final displayContent = _isMasked ? _maskText(content) : content;
    final displayKeywords = _isMasked ? null : keywords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _textTheme.labelSmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        buildHighlightedText(
          displayContent,
          keywords: displayKeywords,
          highlightColor: statusColor.withValues(alpha: 0.3),
          textStyle: _textTheme.bodySmall?.copyWith(
            color: _colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 打码文本（将文本替换为星号）
  String _maskText(String text) {
    if (text.isEmpty) return text;

    return text.split('').map((char) {
      if (char == ' ') return ' ';
      return '*';
    }).join();
  }
}

