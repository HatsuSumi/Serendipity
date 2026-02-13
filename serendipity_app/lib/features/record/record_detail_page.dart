import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/theme/status_color_extension.dart';

/// 记录详情页面
class RecordDetailPage extends ConsumerWidget {
  final EncounterRecord record;

  const RecordDetailPage({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用主题自适应的状态颜色
    final statusColor = record.status.getColor(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
        actions: [
          // 编辑按钮
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: 跳转到编辑页面
              MessageHelper.showInfo(context, '编辑功能待开发');
            },
            tooltip: '编辑',
          ),
          // 更多操作菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'storyline',
                child: Row(
                  children: [
                    Icon(Icons.auto_stories_outlined),
                    SizedBox(width: 8),
                    Text('关联到故事线'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'community',
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
                    Text('删除记录', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态卡片（顶部）
            _buildStatusCard(context, statusColor),
            
            const SizedBox(height: 8),
            
            // 详细信息
            _buildDetailSection(context),
          ],
        ),
      ),
    );
  }

  /// 状态卡片
  Widget _buildStatusCard(BuildContext context, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.2),
            statusColor.withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          // 状态图标
          Text(
            record.status.icon,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 12),
          
          // 状态名称
          Text(
            record.status.label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          
          // 时间
          Text(
            _formatDateTime(record.timestamp),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 详细信息区域
  Widget _buildDetailSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 对话契机（仅邂逅状态且有内容）
          if (record.status == EncounterStatus.met &&
              record.conversationStarter != null &&
              record.conversationStarter!.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.chat_bubble_outline,
              title: '对话契机',
              child: Text(
                record.conversationStarter!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          
          // 地点信息
          _buildInfoCard(
            context,
            icon: Icons.location_on,
            title: '地点',
            child: _buildLocationInfo(context),
          ),
          
          // 描述（如果有）
          if (record.description != null && record.description!.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.description_outlined,
              title: '描述',
              child: Text(
                record.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          
          // 标签（如果有）
          if (record.tags.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.label_outlined,
              title: '特征标签',
              child: _buildTagsInfo(context),
            ),
          
          // 情绪强度（如果有）
          if (record.emotion != null)
            _buildInfoCard(
              context,
              icon: Icons.favorite_outline,
              title: '情绪强度',
              child: Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < record.emotion!.value
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                      size: 20,
                    );
                  }),
                  const SizedBox(width: 12),
                  Text(
                    record.emotion!.label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          
          // 背景音乐（如果有）
          if (record.backgroundMusic != null && record.backgroundMusic!.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.music_note_outlined,
              title: '背景音乐',
              child: Text(
                record.backgroundMusic!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          
          // 天气（如果有）
          if (record.weather.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.wb_sunny_outlined,
              title: '天气',
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: record.weather.map((weather) {
                  return Chip(
                    avatar: Text(weather.icon),
                    label: Text(weather.label),
                  );
                }).toList(),
              ),
            ),
          
          // "如果再遇"备忘（如果有）
          if (record.ifReencounter != null && record.ifReencounter!.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.lightbulb_outline,
              title: '如果再遇',
              child: Text(
                record.ifReencounter!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          
          // 故事线信息（如果有）
          if (record.storyLineId != null)
            _buildInfoCard(
              context,
              icon: Icons.auto_stories_outlined,
              title: '所属故事线',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      record.storyLineId!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          
          // 元数据
          _buildMetadataCard(context),
        ],
      ),
    );
  }

  /// 信息卡片
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  /// 地点信息
  Widget _buildLocationInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 地点名称 + 场所类型
        if (record.location.placeName != null || record.location.placeType != null)
          Row(
            children: [
              if (record.location.placeType != null) ...[
                Text(
                  record.location.placeType!.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  record.location.placeName ?? record.location.placeType?.label ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        
        // 地址
        if (record.location.address != null) ...[
          if (record.location.placeName != null || record.location.placeType != null)
            const SizedBox(height: 8),
          Text(
            record.location.address!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        
        // GPS 坐标
        if (record.location.latitude != null && record.location.longitude != null) ...[
          const SizedBox(height: 8),
          Text(
            '${record.location.latitude!.toStringAsFixed(6)}, ${record.location.longitude!.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
          ),
        ],
        
        // 如果什么都没有
        if (record.location.placeName == null &&
            record.location.placeType == null &&
            record.location.address == null)
          Text(
            '未知地点',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
      ],
    );
  }

  /// 标签信息
  Widget _buildTagsInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: record.tags.map((tagWithNote) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标签名称
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tagWithNote.tag,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              
              // 标签备注（如果有）
              if (tagWithNote.note != null && tagWithNote.note!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    tagWithNote.note!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 元数据卡片
  Widget _buildMetadataCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '记录信息',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            _buildMetadataRow(
              context,
              label: '记录ID',
              value: record.id,
            ),
            _buildMetadataRow(
              context,
              label: '创建时间',
              value: _formatDateTime(record.createdAt),
            ),
            _buildMetadataRow(
              context,
              label: '更新时间',
              value: _formatDateTime(record.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  /// 元数据行
  Widget _buildMetadataRow(BuildContext context, {required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'storyline':
        // TODO: 关联到故事线
        MessageHelper.showInfo(context, '关联到故事线功能待开发');
        break;
      case 'community':
        // TODO: 发布到社区
        MessageHelper.showInfo(context, '发布到社区功能待开发');
        break;
      case 'delete':
        _showDeleteConfirmDialog(context);
        break;
    }
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 删除记录
              MessageHelper.showInfo(context, '删除功能待开发');
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

