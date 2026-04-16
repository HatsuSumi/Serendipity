import 'package:flutter/material.dart';

enum RecordDetailAction {
  export,
  storyline,
  community,
  delete,
}

class RecordDetailActionMenu extends StatelessWidget {
  final ValueChanged<RecordDetailAction> onSelected;

  const RecordDetailActionMenu({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RecordDetailAction>(
      icon: const Icon(Icons.more_vert),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem<RecordDetailAction>(
          value: RecordDetailAction.export,
          child: Row(
            children: [
              Icon(Icons.image_outlined),
              SizedBox(width: 8),
              Text('导出为图片'),
            ],
          ),
        ),
        PopupMenuItem<RecordDetailAction>(
          value: RecordDetailAction.storyline,
          child: Row(
            children: [
              Icon(Icons.auto_stories_outlined),
              SizedBox(width: 8),
              Text('关联到故事线'),
            ],
          ),
        ),
        PopupMenuItem<RecordDetailAction>(
          value: RecordDetailAction.community,
          child: Row(
            children: [
              Icon(Icons.cloud_outlined),
              SizedBox(width: 8),
              Text('发布到社区'),
            ],
          ),
        ),
        PopupMenuItem<RecordDetailAction>(
          value: RecordDetailAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('删除记录', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

