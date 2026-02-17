import 'package:flutter/material.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/message_helper.dart';
import '../../../models/encounter_record.dart';

/// 标签管理组件
/// 
/// 用于添加、删除和展示标签，带动画效果
class TagsSection extends StatefulWidget {
  final List<TagWithNote> tags;
  final ValueChanged<List<TagWithNote>> onTagsChanged;
  
  const TagsSection({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends State<TagsSection> {
  // 正在删除的标签（使用标签名而不是索引）
  final Set<String> _removingTagNames = {};
  
  // 正在添加的标签（用于添加动画）
  final Set<String> _addingTagNames = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🏷️ 特征标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 已选择的标签
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tagWithNote) {
              final isRemoving = _removingTagNames.contains(tagWithNote.tag);
              final isAdding = _addingTagNames.contains(tagWithNote.tag);
              
              // 添加时从0到1，删除时从1到0，正常时保持1
              final scale = (isAdding || isRemoving) ? 0.0 : 1.0;
              final opacity = (isAdding || isRemoving) ? 0.0 : 1.0;
              
              return AnimatedScale(
                key: ValueKey('scale_${tagWithNote.tag}'),
                scale: scale,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Chip(
                    label: Text(tagWithNote.tag),
                    onDeleted: () => _removeTagWithAnimation(tagWithNote),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // 添加标签按钮
        OutlinedButton.icon(
          onPressed: _showAddTagDialog,
          icon: const Icon(Icons.add),
          label: const Text('添加标签'),
        ),
      ],
    );
  }

  /// 删除标签（带动画）
  Future<void> _removeTagWithAnimation(TagWithNote tagWithNote) async {
    // 标记为删除中，触发动画
    setState(() {
      _removingTagNames.add(tagWithNote.tag);
    });
    
    // 等待动画完成
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 从列表中移除
    if (!mounted) return;
    
    final updatedTags = List<TagWithNote>.from(widget.tags)..remove(tagWithNote);
    widget.onTagsChanged(updatedTags);
    
    setState(() {
      _removingTagNames.remove(tagWithNote.tag);
    });
  }

  /// 显示添加标签对话框
  Future<void> _showAddTagDialog() async {
    final tagController = TextEditingController();
    final noteController = TextEditingController();
    
    final result = await DialogHelper.show<TagWithNote>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加标签'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tagController,
              decoration: const InputDecoration(
                labelText: '标签名称',
                hintText: '例如：长发、黑色外套...',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '例如：光线不好，可能是深棕色',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final tag = tagController.text.trim();
              if (tag.isNotEmpty) {
                // 检查是否已存在同名标签
                final isDuplicate = widget.tags.any((t) => t.tag == tag);
                if (isDuplicate) {
                  MessageHelper.showWarning(context, '该标签已存在');
                  return;
                }
                
                final note = noteController.text.trim();
                Navigator.of(context).pop(
                  TagWithNote(
                    tag: tag,
                    note: note.isEmpty ? null : note,
                  ),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      // 先标记为添加中
      setState(() {
        _addingTagNames.add(result.tag);
      });
      
      final updatedTags = List<TagWithNote>.from(widget.tags)..add(result);
      widget.onTagsChanged(updatedTags);
      
      // 等待一帧后触发动画
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {
          _addingTagNames.remove(result.tag);
        });
      }
    }
  }
}

