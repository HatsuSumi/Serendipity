import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/enums.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/smart_navigator.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/utils/record_helper.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/theme/status_color_extension.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/utils/page_transition_builder.dart';
import '../story_line/link_to_story_line_dialog.dart';
import '../story_line/story_line_detail_page.dart';
import '../community/dialogs/publish_warning_dialog.dart';
import 'create_record_page.dart';

/// 记录详情页面
class RecordDetailPage extends ConsumerStatefulWidget {
  final EncounterRecord record;

  const RecordDetailPage({
    super.key,
    required this.record,
  });

  @override
  ConsumerState<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends ConsumerState<RecordDetailPage> {
  /// 获取当前记录（从 Provider 实时获取）
  EncounterRecord get _currentRecord {
    final recordsAsync = ref.watch(recordsProvider);
    final records = recordsAsync.value;
    if (records == null) return widget.record;
    
    try {
      return records.firstWhere((r) => r.id == widget.record.id);
    } catch (e) {
      return widget.record;
    }
  }

  /// 获取故事线名称（通过 Provider）
  /// 
  /// 注意：此方法只在 storyLineId != null 时被调用
  String _getStoryLineName() {
    final storyLinesAsync = ref.read(storyLinesProvider);
    final storyLines = storyLinesAsync.value;
    
    // 如果故事线列表还在加载中，显示"加载中..."
    if (storyLines == null) return '加载中...';
    
    try {
      final storyLine = storyLines.firstWhere(
        (sl) => sl.id == _currentRecord.storyLineId,
      );
      return storyLine.name;
    } catch (e) {
      // 如果找不到对应的故事线（数据不一致，理论上不应该发生）
      // 因为删除故事线时会自动将记录的 storyLineId 设为 null
      return '故事线已删除';
    }
  }

  /// 导航到编辑页面
  void _navigateToEditPage(BuildContext context, WidgetRef ref) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      CreateRecordPage(recordToEdit: _currentRecord),
    ).then((result) {
      // 如果返回了更新后的记录，让 Provider 失效，触发自动重新加载
      if (mounted && result != null && result is EncounterRecord) {
        ref.invalidate(recordsProvider);
      }
    });
  }

  /// 导航到故事线详情页面
  void _navigateToStoryLineDetail(BuildContext context) {
    if (_currentRecord.storyLineId == null) return;
    
    // 通过 Provider 获取故事线
    final storyLinesAsync = ref.read(storyLinesProvider);
    final storyLines = storyLinesAsync.value;
    if (storyLines == null) {
      MessageHelper.showError(context, '故事线数据未加载');
      return;
    }
    
    StoryLine? storyLine;
    try {
      storyLine = storyLines.firstWhere(
        (sl) => sl.id == _currentRecord.storyLineId,
      );
    } catch (e) {
      MessageHelper.showError(context, '故事线不存在');
      return;
    }
    
    // 获取用户设置的页面切换动画类型
    var transitionType = ref.read(pageTransitionProvider);
    
    // 如果是随机动画，获取一个具体的动画类型
    if (transitionType == PageTransitionType.random) {
      transitionType = PageTransitionBuilder.getRandomType();
    }
    
    // 使用 SmartNavigator 自动处理导航栈
    SmartNavigator.push(
      context: context,
      targetPage: StoryLineDetailPage(storyLineId: storyLine.id),
      currentPageType: RecordDetailPage,
      targetPageType: StoryLineDetailPage,
      transitionDuration: transitionType == PageTransitionType.none
          ? Duration.zero
          : const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return PageTransitionBuilder.buildTransition(
          transitionType,
          context,
          animation,
          secondaryAnimation,
          child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用主题自适应的状态颜色
    final statusColor = _currentRecord.status.getColor(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
        actions: [
          // 编辑按钮
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _navigateToEditPage(context, ref),
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
            statusColor.withValues(alpha: 0.2),
            statusColor.withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          // 状态图标
          Text(
            _currentRecord.status.icon,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 12),
          
          // 状态名称
          Text(
            _currentRecord.status.label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          
          // 时间
          Text(
            DateTimeHelper.formatDateTime(_currentRecord.timestamp),
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
          if (_currentRecord.status == EncounterStatus.met &&
              _currentRecord.conversationStarter != null &&
              _currentRecord.conversationStarter!.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.chat_bubble_outline,
              title: '对话契机',
              child: Text(
                _currentRecord.conversationStarter!,
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
          if (_currentRecord.description != null && _currentRecord.description!.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.description_outlined,
              title: '描述',
              child: Text(
                _currentRecord.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          
          // 标签（如果有）
          if (_currentRecord.tags.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.label_outlined,
              title: '特征标签',
              child: _buildTagsInfo(context),
            ),
          
          // 情绪强度（如果有）
          if (_currentRecord.emotion != null)
            _buildInfoCard(
              context,
              icon: Icons.favorite_outline,
              title: '情绪强度',
              child: Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < _currentRecord.emotion!.value
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                      size: 20,
                    );
                  }),
                  const SizedBox(width: 12),
                  Text(
                    _currentRecord.emotion!.label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          
          // 背景音乐（如果有）
          if (_currentRecord.backgroundMusic != null && _currentRecord.backgroundMusic!.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.music_note_outlined,
              title: '背景音乐',
              child: Text(
                _currentRecord.backgroundMusic!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          
          // 天气（如果有）
          if (_currentRecord.weather.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.wb_sunny_outlined,
              title: '天气',
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _currentRecord.weather.map((weather) {
                  return Chip(
                    avatar: Text(weather.icon),
                    label: Text(weather.label),
                  );
                }).toList(),
              ),
            ),
          
          // "如果再遇"备忘（如果有）
          if (_currentRecord.ifReencounter != null && _currentRecord.ifReencounter!.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.lightbulb_outline,
              title: '如果再遇',
              child: Text(
                _currentRecord.ifReencounter!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          
          // 故事线信息（如果有）
          if (_currentRecord.storyLineId != null)
            _buildInfoCard(
              context,
              icon: Icons.auto_stories_outlined,
              title: '所属故事线',
              child: InkWell(
                onTap: () => _navigateToStoryLineDetail(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Text('📖 '),
                      Expanded(
                        child: Text(
                          _getStoryLineName(),
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
    // 使用 RecordHelper 判断地点是否为空
    if (RecordHelper.isLocationEmpty(_currentRecord.location)) {
      return Text(
        '未知地点',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    // 详情页：分别显示所有字段，不使用优先级
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 场所类型（如果有）- 始终放在第一行
        if (_currentRecord.location.placeType != null) ...[
          Row(
            children: [
              Text(
                _currentRecord.location.placeType!.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                _currentRecord.location.placeType!.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        // 地点名称（如果有）
        if (_currentRecord.location.placeName != null && 
            _currentRecord.location.placeName!.isNotEmpty) ...[
          Text(
            _currentRecord.location.placeName!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
        ],
        
        // 详细地址（完整显示，不截断）
        if (_currentRecord.location.address != null &&
            _currentRecord.location.address!.isNotEmpty) ...[
          Text(
            _currentRecord.location.address!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
        ],
        
        // GPS 坐标（如果有）
        if (RecordHelper.hasCoordinates(_currentRecord.location))
          Text(
            '纬度: ${_currentRecord.location.latitude!.toStringAsFixed(6)}, 经度: ${_currentRecord.location.longitude!.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
          ),
      ],
    );
  }

  /// 标签信息
  Widget _buildTagsInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _currentRecord.tags.map((tagWithNote) {
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
              value: _currentRecord.id,
            ),
            _buildMetadataRow(
              context,
              label: '创建时间',
              value: DateTimeHelper.formatDateTime(_currentRecord.createdAt),
            ),
            _buildMetadataRow(
              context,
              label: '更新时间',
              value: DateTimeHelper.formatDateTime(_currentRecord.updatedAt),
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
        _showLinkToStoryLineDialog(context);
        break;
      case 'community':
        _publishToCommunity(context);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context);
        break;
    }
  }

  /// 发布到社区
  /// 
  /// 调用者：_handleMenuAction()
  Future<void> _publishToCommunity(BuildContext context) async {
    final communityNotifier = ref.read(communityProvider.notifier);
    
    try {
      // 步骤1：先检查发布状态
      final statusMap = await communityNotifier.checkPublishStatus([_currentRecord]);
      final status = statusMap[_currentRecord.id] ?? 'can_publish';
      
      if (status == 'cannot_publish') {
        // 内容未变化，不允许发布，直接提示错误
        if (context.mounted) {
          MessageHelper.showError(context, '该记录已发布且内容未变化');
        }
        return;
      }
      
      // 步骤2：显示警告对话框
      final shouldPublish = await PublishWarningDialog.show(context, ref);
      
      if (!shouldPublish) return;
      
      // 步骤3：根据状态执行发布
      if (status == 'need_confirm') {
        // 需要用户确认替换
        if (!context.mounted) return;
        
        final confirmed = await DialogHelper.show<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('发布确认'),
            content: const Text('该记录已发布到社区，重新发布会替换旧帖，是否继续？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确认'),
              ),
            ],
          ),
        );
        
        if (confirmed != true) return;
        
        // 用户确认，强制替换
        await AsyncActionHelper.execute(
          context,
          action: () => communityNotifier.publishPost(_currentRecord, forceReplace: true),
          successMessage: '已发布到树洞',
          errorMessagePrefix: '发布失败',
        );
      } else {
        // 可以直接发布
        await AsyncActionHelper.execute(
          context,
          action: () => communityNotifier.publishPost(_currentRecord),
          successMessage: '已发布到树洞',
          errorMessagePrefix: '发布失败',
        );
      }
    } catch (e) {
      if (context.mounted) {
        MessageHelper.showError(context, '检查发布状态失败：$e');
      }
    }
  }

  /// 显示关联到故事线对话框
  void _showLinkToStoryLineDialog(BuildContext context) {
    DialogHelper.show(
      context: context,
      builder: (context) => LinkToStoryLineDialog(
        recordId: _currentRecord.id,
      ),
    ).then((result) {
      // 如果关联成功，让 Provider 失效，触发自动重新加载
      if (result == true && mounted) {
        ref.invalidate(recordsProvider);
      }
    });
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context) async {
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '删除记录',
      content: '确定要删除这条记录吗？此操作无法撤销。',
    );

    if (confirmed == true && context.mounted) {
      _deleteRecord(context);
    }
  }

  /// 删除记录
  Future<void> _deleteRecord(BuildContext context) async {
    try {
      // 通过 Provider 删除记录
      await ref.read(recordsProvider.notifier).deleteRecord(_currentRecord.id);
      
      if (!mounted) return;
      
      // 让 Provider 失效，触发自动重新加载
      ref.invalidate(recordsProvider);
      
      if (!context.mounted) return;
      
      // 返回上一页
      Navigator.of(context).pop();
      
      // 显示成功提示
      MessageHelper.showSuccess(context, '记录已删除');
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      
      // 显示错误提示
      MessageHelper.showError(context, '删除失败：$e');
    }
  }
}

