import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/story_line.dart';
import '../../models/encounter_record.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/providers/membership_provider.dart';
import '../../core/theme/status_color_extension.dart';
import '../../core/providers/theme_provider.dart' show appColorSchemeProvider, appTextThemeProvider;
import '../../core/providers/page_transition_provider.dart';
import '../../core/utils/page_transition_builder.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/smart_navigator.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/record_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/enums.dart';
import '../record/record_detail_page.dart';
import '../record/create_record_page.dart';
import 'add_existing_records_dialog.dart';
import 'story_line_tag_cloud_section.dart';
import 'story_line_export_card.dart';

/// 故事线详情页面
class StoryLineDetailPage extends ConsumerWidget {
  final String storyLineId;

  const StoryLineDetailPage({
    super.key,
    required this.storyLineId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 Provider 直接取颜色，无竞态条件
    final colorScheme = ref.watch(appColorSchemeProvider);
    final textTheme = ref.watch(appTextThemeProvider);
    // 使用 ref.watch() 自动响应数据变化
    final storyLinesAsync = ref.watch(storyLinesProvider);
    final recordsAsync = ref.watch(storyLineRecordsProvider(storyLineId));

    return storyLinesAsync.when(
      data: (storyLines) {
        // 查找当前故事线
        final storyLine = storyLines.firstWhere(
          (sl) => sl.id == storyLineId,
          orElse: () => throw StateError('Story line $storyLineId not found'),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(storyLine.name),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, ref, storyLine, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_existing',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add),
                        SizedBox(width: 8),
                        Text('添加现有记录'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.image_outlined),
                        SizedBox(width: 8),
                        Text('导出为图文卡片'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 8),
                        Text('重命名'),
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
              ),
            ],
          ),
          body: recordsAsync.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      ref.read(storyLinesProvider.notifier).refresh(),
                      ref.read(recordsProvider.notifier).refresh(),
                    ]);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: recordsAsync.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return StoryLineTagCloudSection(
                          storyLineId: storyLineId,
                        );
                      }

                      final record = recordsAsync[index - 1];
                      final isLast = index == recordsAsync.length;

                      return Column(
                        children: [
                          _buildRecordCard(context, ref, record, storyLine),
                          if (!isLast) _buildArrow(context),
                        ],
                      );
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToCreateRecord(context, ref, storyLine),
            icon: const Icon(Icons.add),
            label: const Text('添加新的进展'),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('故事线详情')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '加载失败：$error',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.auto_stories_outlined,
      title: '还没有记录',
      description: '点击下方按钮添加第一条记录',
    );
  }

  /// 记录卡片
  Widget _buildRecordCard(BuildContext context, WidgetRef ref, EncounterRecord record, StoryLine storyLine) {
    final statusColor = record.status.getColor(context, ref);

    return Card(
      child: InkWell(
        onTap: () => _navigateToRecordDetail(context, ref, record),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor.withValues(alpha: 0.1),
                statusColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期和状态
              Row(
                children: [
                  Text(
                    DateTimeHelper.formatShortDate(record.timestamp),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    record.status.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.status.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                  // 菜单按钮
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleRecordMenuAction(context, ref, record, storyLine, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.link_off),
                            SizedBox(width: 8),
                            Text('从故事线移除'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('编辑记录'),
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
              const SizedBox(height: 12),

              // 地点
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      RecordHelper.getLocationText(record.location),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // 描述
              if (record.description != null && record.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  record.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 标签
              if (record.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: record.tags.take(3).map((tagWithNote) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tagWithNote.tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 箭头
  Widget _buildArrow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Icon(
          Icons.arrow_downward,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          size: 24,
        ),
      ),
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(BuildContext context, WidgetRef ref, StoryLine storyLine, String action) {
    switch (action) {
      case 'add_existing':
        _showAddExistingRecordsDialog(context, storyLine);
        break;
      case 'export':
        _exportStoryLine(context, ref, storyLine);
        break;
      case 'rename':
        _showRenameDialog(context, ref, storyLine);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, ref, storyLine);
        break;
    }
  }

  /// 处理记录卡片菜单操作
  void _handleRecordMenuAction(BuildContext context, WidgetRef ref, EncounterRecord record, StoryLine storyLine, String action) {
    switch (action) {
      case 'remove':
        _showRemoveRecordConfirmDialog(context, ref, record, storyLine);
        break;
      case 'edit':
        _navigateToEditRecord(context, ref, record);
        break;
      case 'delete':
        _showDeleteRecordConfirmDialog(context, ref, record);
        break;
    }
  }

  /// 显示从故事线移除记录确认对话框
  void _showRemoveRecordConfirmDialog(BuildContext context, WidgetRef ref, EncounterRecord record, StoryLine storyLine) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从故事线移除'),
        content: const Text('确定要将这条记录从故事线中移除吗？\n\n记录本身不会被删除，只是取消关联。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AsyncActionHelper.execute(
                context,
                action: () => ref.read(storyLinesProvider.notifier).unlinkRecord(record.id, storyLine.id),
                successMessage: '已从故事线移除',
                errorMessagePrefix: '移除失败',
              );
            },
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }

  /// 导航到编辑记录页面
  void _navigateToEditRecord(BuildContext context, WidgetRef ref, EncounterRecord record) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      CreateRecordPage(recordToEdit: record),
    );
  }

  /// 显示删除记录确认对话框
  void _showDeleteRecordConfirmDialog(BuildContext context, WidgetRef ref, EncounterRecord record) {
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
            onPressed: () async {
              Navigator.of(context).pop();
              await AsyncActionHelper.execute(
                context,
                action: () => ref.read(recordsProvider.notifier).deleteRecord(record.id),
                successMessage: '记录已删除',
                errorMessagePrefix: '删除失败',
              );
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

  /// 导出故事线为图文卡片并保存到相册（会员功能）
  ///
  /// 调用者：_handleMenuAction()
  void _exportStoryLine(
    BuildContext context,
    WidgetRef ref,
    StoryLine storyLine,
  ) async {
    final membershipInfo = ref.read(membershipProvider).valueOrNull;
    if (membershipInfo == null || !membershipInfo.canExportStoryLineCard) {
      MessageHelper.showWarning(context, '导出故事线图文卡片是会员专属功能');
      return;
    }

    final records = List<EncounterRecord>.from(
      ref.read(storyLineRecordsProvider(storyLine.id)),
    )..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (records.isEmpty) {
      MessageHelper.showWarning(context, '故事线暂无记录，无法导出');
      return;
    }

    final success = await StoryLineExportCard.export(context, storyLine, records);
    if (!context.mounted) return;
    if (success) {
      MessageHelper.showSuccess(context, '已保存到相册');
    } else {
      MessageHelper.showError(context, '导出失败，请重试');
    }
  }

  /// 显示添加现有记录对话框
  void _showAddExistingRecordsDialog(BuildContext context, StoryLine storyLine) {
    DialogHelper.show(
      context: context,
      builder: (context) => AddExistingRecordsDialog(storyLine: storyLine),
    );
  }

  /// 显示重命名对话框
  void _showRenameDialog(BuildContext context, WidgetRef ref, StoryLine storyLine) async {
    final newName = await DialogHelper.showRenameDialog(
      context: context,
      title: '重命名故事线',
      initialValue: storyLine.name,
      hintText: '输入新名称...',
      emptyWarning: '请输入故事线名称',
    );

    if (newName != null && context.mounted) {
      final updatedStoryLine = storyLine.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );

      await AsyncActionHelper.execute(
        context,
        action: () => ref.read(storyLinesProvider.notifier).updateStoryLine(updatedStoryLine),
        successMessage: '已重命名',
        errorMessagePrefix: '重命名失败',
      );
    }
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, StoryLine storyLine) async {
    final confirmed = await DialogHelper.showDeleteConfirm(
      context: context,
      title: '删除故事线',
      content: '确定要删除"${storyLine.name}"吗？\n\n记录不会被删除，只是取消关联。',
    );

    if (confirmed == true && context.mounted) {
      final success = await AsyncActionHelper.execute(
        context,
        action: () => ref.read(storyLinesProvider.notifier).deleteStoryLine(storyLine.id),
        successMessage: '故事线已删除',
        errorMessagePrefix: '删除失败',
      );
      
      if (success && context.mounted) {
        Navigator.of(context).pop(); // 返回列表页
      }
    }
  }

  /// 导航到记录详情
  void _navigateToRecordDetail(BuildContext context, WidgetRef ref, EncounterRecord record) {
    // 获取动画类型
    var transitionType = ref.read(pageTransitionProvider);
    if (transitionType == PageTransitionType.random) {
      transitionType = PageTransitionBuilder.getRandomType();
    }

    // 使用 SmartNavigator 自动处理导航栈
    SmartNavigator.push(
      context: context,
      targetPage: RecordDetailPage(record: record),
      currentPageType: StoryLineDetailPage,
      targetPageType: RecordDetailPage,
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

  /// 导航到创建记录页面
  void _navigateToCreateRecord(BuildContext context, WidgetRef ref, StoryLine storyLine) {
    NavigationHelper.pushWithTransition(
      context,
      ref,
      CreateRecordPage(initialStoryLineId: storyLine.id),
    );
  }
}
