import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/story_line.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/status_color_extension.dart';
import '../../core/providers/page_transition_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/utils/page_transition_builder.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../record/record_detail_page.dart';
import '../record/create_record_page.dart';
import 'add_existing_records_dialog.dart';

/// 故事线详情页面
class StoryLineDetailPage extends ConsumerStatefulWidget {
  final StoryLine storyLine;

  const StoryLineDetailPage({
    super.key,
    required this.storyLine,
  });

  @override
  ConsumerState<StoryLineDetailPage> createState() => _StoryLineDetailPageState();
}

class _StoryLineDetailPageState extends ConsumerState<StoryLineDetailPage> {
  late StoryLine _currentStoryLine;
  List<EncounterRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentStoryLine = widget.storyLine;
    _loadRecords();
  }

  /// 加载记录
  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storage = StorageService();
      final records = <EncounterRecord>[];

      for (final recordId in _currentStoryLine.recordIds) {
        final record = storage.getRecord(recordId);
        if (record != null) {
          records.add(record);
        }
      }

      // 按时间排序
      records.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 刷新故事线数据
  Future<void> _refresh() async {
    final storage = StorageService();
    final updatedStoryLine = storage.getStoryLine(_currentStoryLine.id);
    if (updatedStoryLine != null) {
      setState(() {
        _currentStoryLine = updatedStoryLine;
      });
    }
    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStoryLine.name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, value),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length + 1, // +1 for the add button
                    itemBuilder: (context, index) {
                      if (index == _records.length) {
                        return _buildAddButton(context);
                      }

                      final record = _records[index];
                      final isLast = index == _records.length - 1;

                      return Column(
                        children: [
                          _buildRecordCard(context, record),
                          if (!isLast) _buildArrow(context),
                        ],
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateRecord(context),
        icon: const Icon(Icons.add),
        label: const Text('添加新的进展'),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有记录',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加第一条记录',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 记录卡片
  Widget _buildRecordCard(BuildContext context, EncounterRecord record) {
    final statusColor = record.status.getColor(context, ref);

    return Card(
      child: InkWell(
        onTap: () => _navigateToRecordDetail(context, record),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor.withOpacity(0.1),
                statusColor.withOpacity(0.05),
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
                    _formatDate(record.timestamp),
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
                  Text(
                    record.status.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
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
                      _getLocationText(record),
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
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          size: 24,
        ),
      ),
    );
  }

  /// 添加按钮
  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OutlinedButton.icon(
        onPressed: () => _navigateToCreateRecord(context),
        icon: const Icon(Icons.add),
        label: const Text('添加新的进展'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'add_existing':
        _showAddExistingRecordsDialog(context);
        break;
      case 'rename':
        _showRenameDialog(context);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context);
        break;
    }
  }

  /// 显示添加现有记录对话框
  void _showAddExistingRecordsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddExistingRecordsDialog(storyLine: _currentStoryLine),
    ).then((result) {
      if (result == true) {
        // 添加成功后刷新
        _refresh();
      }
    });
  }

  /// 显示重命名对话框
  void _showRenameDialog(BuildContext context) {
    final nameController = TextEditingController(text: _currentStoryLine.name);

    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名故事线'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: '输入新名称...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                MessageHelper.showWarning(context, '请输入故事线名称');
                return;
              }

              final updatedStoryLine = _currentStoryLine.copyWith(
                name: name,
                updatedAt: DateTime.now(),
              );

              try {
                await ref.read(storyLinesProvider.notifier).updateStoryLine(updatedStoryLine);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentStoryLine = updatedStoryLine;
                  });
                  MessageHelper.showSuccess(context, '已重命名');
                }
              } catch (e) {
                if (context.mounted) {
                  MessageHelper.showError(context, '重命名失败：$e');
                }
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除故事线'),
        content: Text('确定要删除"${_currentStoryLine.name}"吗？\n\n记录不会被删除，只是取消关联。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(storyLinesProvider.notifier).deleteStoryLine(_currentStoryLine.id);
                if (context.mounted) {
                  Navigator.of(context).pop(); // 关闭对话框
                  Navigator.of(context).pop(); // 返回列表页
                  MessageHelper.showSuccess(context, '故事线已删除');
                }
              } catch (e) {
                if (context.mounted) {
                  MessageHelper.showError(context, '删除失败：$e');
                }
              }
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

  /// 导航到记录详情
  void _navigateToRecordDetail(BuildContext context, EncounterRecord record) {
    var transitionType = ref.read(pageTransitionProvider);
    if (transitionType == PageTransitionType.random) {
      transitionType = PageTransitionBuilder.getRandomType();
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return RecordDetailPage(record: record);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitionBuilder.buildTransition(
            transitionType,
            context,
            animation,
            secondaryAnimation,
            child,
          );
        },
        transitionDuration: transitionType == PageTransitionType.none
            ? Duration.zero
            : const Duration(milliseconds: 300),
      ),
    ).then((_) {
      // 返回后刷新
      _refresh();
    });
  }

  /// 导航到创建记录页面
  void _navigateToCreateRecord(BuildContext context) {
    var transitionType = ref.read(pageTransitionProvider);
    if (transitionType == PageTransitionType.random) {
      transitionType = PageTransitionBuilder.getRandomType();
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return CreateRecordPage(
            initialStoryLineId: _currentStoryLine.id,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitionBuilder.buildTransition(
            transitionType,
            context,
            animation,
            secondaryAnimation,
            child,
          );
        },
        transitionDuration: transitionType == PageTransitionType.none
            ? Duration.zero
            : const Duration(milliseconds: 300),
      ),
    ).then((_) {
      // 返回后刷新
      _refresh();
    });
  }

  /// 格式化日期
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// 获取地点文本
  String _getLocationText(EncounterRecord record) {
    if (record.location.placeName != null) {
      return record.location.placeName!;
    }
    if (record.location.address != null) {
      return record.location.address!;
    }
    if (record.location.placeType != null) {
      return record.location.placeType!.label;
    }
    return '未知地点';
  }
}

