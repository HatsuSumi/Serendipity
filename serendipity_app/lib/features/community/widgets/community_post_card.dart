import 'package:flutter/material.dart';
import '../../../models/community_post.dart';
import '../../../core/utils/record_helper.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/widgets/common_filter_widgets.dart';

/// 社区帖子卡片
/// 
/// 职责：
/// - 显示社区帖子内容
/// - 支持删除操作（仅自己的帖子）
/// - 支持标签高亮（筛选时）
/// 
/// 调用者：CommunityPage、MyPostsPage
class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onDelete;
  final List<String>? highlightKeywords;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onDelete,
    this.highlightKeywords,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：时间 + 状态 + 菜单按钮
            _buildHeader(context),
            const SizedBox(height: 8),
            
            // 第二行：地点
            _buildLocation(context),
            const SizedBox(height: 12),
            
            // 第三行：描述
            if (post.description != null && post.description!.isNotEmpty) ...[
              _buildDescription(context),
              const SizedBox(height: 12),
            ],
            
            // 第四行：标签
            if (post.tags.isNotEmpty) ...[
              _buildTags(context),
              const SizedBox(height: 12),
            ],
            
            // 第五行：发布时间
            _buildPublishTime(context),
          ],
        ),
      ),
    );
  }

  /// 构建头部（时间 + 状态 + 删除按钮）
  /// 
  /// 性能优化：
  /// - 提取为独立方法，提高代码可读性
  /// - 使用 const 优化固定 Widget
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // 时间
        Text(
          DateTimeHelper.formatShortDate(post.timestamp),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        
        // 状态
        Row(
          children: [
            Text(
              post.status.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              post.status.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        
        // 删除按钮（仅自己的帖子显示）
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: theme.colorScheme.error,
            tooltip: '删除',
            onPressed: onDelete,
          ),
      ],
    );
  }

  /// 构建地点
  /// 
  /// 性能优化：
  /// - 使用 const 优化固定 Widget
  Widget _buildLocation(BuildContext context) {
    final theme = Theme.of(context);
    
    final locationText = RecordHelper.getCommunityLocationText(
      placeTypeLabel: post.placeType?.label,
      address: post.address,
      placeName: post.placeName,
      province: post.province,
      city: post.city,
      area: post.area,
    );

    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            locationText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 构建描述
  Widget _buildDescription(BuildContext context) {
    final theme = Theme.of(context);
    
    return Text(
      post.description ?? '',
      style: theme.textTheme.bodyLarge,
      maxLines: 10,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建标签
  Widget _buildTags(BuildContext context) {
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: post.tags.map((tagWithNote) {
        // 判断是否需要高亮这个标签
        final shouldHighlight = highlightKeywords != null && 
            highlightKeywords!.isNotEmpty &&
            highlightKeywords!.any((keyword) => tagWithNote.tag.contains(keyword));
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标签名称
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: shouldHighlight && highlightKeywords != null && highlightKeywords!.isNotEmpty
                  ? buildHighlightedText(
                      tagWithNote.tag,
                      keyword: highlightKeywords!.first,
                      highlightColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                      textStyle: theme.textTheme.bodySmall,
                    )
                  : Text(
                      tagWithNote.tag,
                      style: theme.textTheme.bodySmall,
                    ),
            ),
            
            // 标签备注（如果有）
            if (tagWithNote.note != null && tagWithNote.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  '备注：${tagWithNote.note}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  /// 构建发布时间
  Widget _buildPublishTime(BuildContext context) {
    final theme = Theme.of(context);
    
    return Text(
      '发布于 ${DateTimeHelper.formatPublishTime(post.publishedAt)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
      ),
    );
  }
}

