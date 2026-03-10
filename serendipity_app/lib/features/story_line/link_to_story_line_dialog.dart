import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/story_line.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/dialog_helper.dart';

/// 关联到故事线对话框
/// 
/// 注意：使用旧的 Radio API（groupValue/onChanged）
/// 原因：Flutter 3.32+ 的新 RadioGroup API 还不够稳定
/// 计划：等 Flutter 生态稳定后再迁移
// ignore_for_file: deprecated_member_use
class LinkToStoryLineDialog extends ConsumerStatefulWidget {
  final String recordId;

  const LinkToStoryLineDialog({
    super.key,
    required this.recordId,
  });

  @override
  ConsumerState<LinkToStoryLineDialog> createState() => _LinkToStoryLineDialogState();
}

class _LinkToStoryLineDialogState extends ConsumerState<LinkToStoryLineDialog> {
  final _nameController = TextEditingController();
  String? _selectedStoryLineId;
  bool _isCreatingNew = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyLinesAsync = ref.watch(storyLinesProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                '关联到故事线',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // 提示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '将同一个人的多次记录关联到一个故事线，形成完整的时间线故事。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 创建新故事线选项
              InkWell(
                onTap: () {
                  setState(() {
                    _isCreatingNew = true;
                    _selectedStoryLineId = null;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _isCreatingNew,
                        onChanged: (value) {
                          setState(() {
                            _isCreatingNew = value ?? false;
                            _selectedStoryLineId = null;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                      const Expanded(
                        child: Text('创建新故事线'),
                      ),
                    ],
                  ),
                ),
              ),

              // 新故事线名称输入
              if (_isCreatingNew) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: '输入故事线名称...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  autofocus: true,
                ),
              ],

              const SizedBox(height: 16),

              // 已有故事线列表
              storyLinesAsync.when(
                data: (storyLines) {
                  if (storyLines.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isCreatingNew = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              Radio<bool>(
                                value: false,
                                groupValue: _isCreatingNew,
                                onChanged: (value) {
                                  setState(() {
                                    _isCreatingNew = value ?? true;
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                              const Expanded(
                                child: Text('添加到现有故事线'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!_isCreatingNew) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: storyLines.length,
                            itemBuilder: (context, index) {
                              final storyLine = storyLines[index];
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedStoryLineId = storyLine.id;
                                  });
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: storyLine.id,
                                        groupValue: _selectedStoryLineId,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedStoryLineId = value;
                                          });
                                        },
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const Text('📖 '),
                                      Expanded(
                                        child: Text(
                                          storyLine.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '（${storyLine.recordIds.length}条）',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '加载失败：$error',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _nameController,
                    builder: (context, value, child) {
                      return FilledButton(
                        onPressed: _canConfirm() ? _handleConfirm : null,
                        child: const Text('确认'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 是否可以确认
  bool _canConfirm() {
    if (_isCreatingNew) {
      return _nameController.text.trim().isNotEmpty;
    } else {
      return _selectedStoryLineId != null;
    }
  }

  /// 处理确认
  Future<void> _handleConfirm() async {
    try {
      final storyLinesNotifier = ref.read(storyLinesProvider.notifier);
      final recordsNotifier = ref.read(recordsProvider.notifier);

      // 检查记录是否已关联到其他故事线
      final recordsAsync = ref.read(recordsProvider);
      final records = recordsAsync.value ?? [];
      final currentRecord = records.firstWhere(
        (r) => r.id == widget.recordId,
        orElse: () => throw StateError('Record not found'),
      );

      String? targetStoryLineId;
      String? targetStoryLineName;

      if (_isCreatingNew) {
        // 创建新故事线
        targetStoryLineName = _nameController.text.trim();
      } else {
        // 添加到现有故事线
        targetStoryLineId = _selectedStoryLineId;
        if (targetStoryLineId != null) {
          final storyLinesAsync = ref.read(storyLinesProvider);
          final storyLines = storyLinesAsync.value ?? [];
          final targetStoryLine = storyLines.firstWhere(
            (sl) => sl.id == targetStoryLineId,
            orElse: () => throw StateError('Story line not found'),
          );
          targetStoryLineName = targetStoryLine.name;
        }
      }

      // 如果记录已关联到其他故事线，弹出确认对话框
      if (currentRecord.storyLineId != null && 
          currentRecord.storyLineId != targetStoryLineId) {
        // 获取当前故事线名称
        final storyLinesAsync = ref.read(storyLinesProvider);
        final storyLines = storyLinesAsync.value ?? [];
        final currentStoryLine = storyLines.firstWhere(
          (sl) => sl.id == currentRecord.storyLineId,
          orElse: () => throw StateError('Current story line not found'),
        );

        // 弹出确认对话框
        final confirmed = await DialogHelper.show<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('移动记录'),
            content: Text(
              '该记录已关联到故事线"${currentStoryLine.name}"，\n'
              '是否移动到"$targetStoryLineName"？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('移动'),
              ),
            ],
          ),
        );

        // 用户取消操作
        if (confirmed != true) {
          return;
        }
      }

      // 执行关联操作
      if (_isCreatingNew) {
        // 创建新故事线
        final name = _nameController.text.trim();
        
        // 获取当前用户ID（用于数据归属）
        final authState = ref.read(authProvider);
        final currentUser = authState.value;
        final ownerId = currentUser?.id; // 未登录时为 null（离线数据）
        
        final now = DateTime.now();
        final newStoryLine = StoryLine(
          id: const Uuid().v4(),
          name: name,
          recordIds: [],
          createdAt: now,
          updatedAt: now,
          ownerId: ownerId,
        );

        await storyLinesNotifier.createStoryLine(newStoryLine);
        await storyLinesNotifier.linkRecord(widget.recordId, newStoryLine.id);
      } else {
        // 添加到现有故事线
        if (_selectedStoryLineId != null) {
          await storyLinesNotifier.linkRecord(widget.recordId, _selectedStoryLineId!);
        }
      }

      // 刷新记录列表和故事线列表
      await recordsNotifier.refresh();
      await storyLinesNotifier.refresh();

      if (mounted) {
        Navigator.of(context).pop(true);
        MessageHelper.showSuccess(context, '已关联到故事线');
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(context, '关联失败：${AuthErrorHelper.extractErrorMessage(e)}');
      }
    }
  }
}

