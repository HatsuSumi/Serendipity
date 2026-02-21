import 'package:flutter/material.dart';

/// 空状态通用组件
/// 
/// 用于显示列表为空时的提示信息。
/// 
/// 调用者：
/// - StoryLinesPage: 故事线列表为空
/// - StoryLineDetailPage: 故事线中没有记录
/// - TimelinePage: 记录列表为空
/// - AddExistingRecordsDialog: 没有可添加的记录
/// 
/// 设计原则：
/// - DRY: 避免跨文件重复空状态UI代码
/// - 灵活性: 支持自定义图标、标题、描述
/// - 一致性: 保持所有空状态UI的视觉风格统一
class EmptyStateWidget extends StatelessWidget {
  /// 图标（可以是 IconData 或 emoji 字符串）
  final dynamic icon;
  
  /// 标题文本
  final String title;
  
  /// 描述文本
  final String description;
  
  /// 图标大小（默认 80）
  final double iconSize;
  
  /// 图标颜色（可选，如果是 emoji 则忽略）
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconSize = 80,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标（支持 IconData 或 emoji 字符串）
          _buildIcon(context),
          
          const SizedBox(height: 24),
          
          // 标题
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          
          const SizedBox(height: 8),
          
          // 描述
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建图标
  Widget _buildIcon(BuildContext context) {
    if (icon is IconData) {
      // 使用 Icon widget
      return Icon(
        icon as IconData,
        size: iconSize,
        color: iconColor ?? 
               Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      );
    } else if (icon is String) {
      // 使用 emoji 字符串
      return Text(
        icon as String,
        style: TextStyle(fontSize: iconSize),
      );
    } else {
      // 默认图标
      return Icon(
        Icons.inbox_outlined,
        size: iconSize,
        color: iconColor ?? 
               Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      );
    }
  }
}

