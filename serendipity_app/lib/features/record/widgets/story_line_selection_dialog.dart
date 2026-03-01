import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/story_lines_provider.dart';
import '../../../core/utils/message_helper.dart';
import '../../../models/story_line.dart';

/// 故事线选择对话框
/// 
/// 用于创建/编辑记录时选择或创建故事线
/// 
/// 注意：使用旧的 Radio API（groupValue/onChanged）
/// 原因：Flutter 3.32+ 的新 RadioGroup API 还不够稳定
/// 计划：等 Flutter 生态稳定后再迁移
// ignore_for_file: deprecated_member_use
class StoryLineSelectionDialog extends ConsumerStatefulWidget {
  final List<StoryLine> storyLines;
  final String? currentStoryLineId;
  
  const StoryLineSelectionDialog({
    super.key,
    required this.storyLines,
    this.currentStoryLineId,
  });

  @override
  ConsumerState<StoryLineSelectionDialog> createState() => _StoryLineSelectionDialogState();
}

class _StoryLineSelectionDialogState extends ConsumerState<StoryLineSelectionDialog> {
  final _nameController = TextEditingController();
  String? _selectedStoryLineId;
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    _selectedStoryLineId = widget.currentStoryLineId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                '选择故事线',
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
              if (widget.storyLines.isNotEmpty) ...[
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
                          child: Text('选择现有故事线'),
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
                      itemCount: widget.storyLines.length,
                      itemBuilder: (context, index) {
                        final storyLine = widget.storyLines[index];
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
      if (_isCreatingNew) {
        // 创建新故事线并返回ID
        final name = _nameController.text.trim();
        final now = DateTime.now();
        final newStoryLineId = const Uuid().v4();
        final newStoryLine = StoryLine(
          id: newStoryLineId,
          name: name,
          recordIds: [],
          createdAt: now,
          updatedAt: now,
        );

        // 通过 Provider 创建故事线（会自动刷新列表）
        await ref.read(storyLinesProvider.notifier).createStoryLine(newStoryLine);
        
        if (!mounted) return;
        Navigator.of(context).pop(newStoryLineId);
      } else {
        // 返回选中的故事线ID
        if (_selectedStoryLineId != null && mounted) {
          Navigator.of(context).pop(_selectedStoryLineId);
        }
      }
    } catch (e) {
      if (!mounted) return;
      MessageHelper.showError(context, '操作失败：$e');
    }
  }
}

