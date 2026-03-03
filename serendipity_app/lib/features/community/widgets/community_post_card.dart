import 'package:flutter/material.dart';
import '../../../models/community_post.dart';
import '../../../core/utils/record_helper.dart';
import '../../../core/utils/date_time_helper.dart';

/// 社区帖子卡片
/// 
/// 职责：
/// - 显示社区帖子内容
/// - 支持删除操作（仅自己的帖子）
/// 
/// 调用者：CommunityPage
class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onDelete;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onDelete,
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
            if (post.description.isNotEmpty) ...[
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

  /// 构建头部（时间 + 状态 + 菜单按钮）
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
        
        // 菜单按钮（仅自己的帖子显示）
        if (onDelete != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                onDelete?.call();
              }
            },
            itemBuilder: (context) => [
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
          ),
      ],
    );
  }

  /// 构建地点
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
      post.description,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标签名称
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
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

