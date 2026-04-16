import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../../core/theme/status_color_extension.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import 'record_detail_controller.dart';
import 'widgets/record_detail_action_menu.dart';
import 'widgets/record_detail_content.dart';
import 'widgets/record_detail_status_header.dart';

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
  EncounterRecord get _currentRecord {
    final recordsAsync = ref.watch(recordsProvider);
    final records = recordsAsync.value;
    if (records == null) return widget.record;

    try {
      return records.firstWhere((r) => r.id == widget.record.id);
    } catch (_) {
      return widget.record;
    }
  }

  String? get _storyLineName {
    final storyLineId = _currentRecord.storyLineId;
    if (storyLineId == null) return null;

    final storyLinesAsync = ref.watch(storyLinesProvider);
    final storyLines = storyLinesAsync.value;
    if (storyLines == null) return '加载中...';

    try {
      final storyLine = storyLines.firstWhere((sl) => sl.id == storyLineId);
      return storyLine.name;
    } catch (_) {
      return '故事线已删除';
    }
  }

  int get _reencounterCountInStoryLine {
    final storyLineId = _currentRecord.storyLineId;
    if (storyLineId == null) return 0;
    final records = ref.watch(storyLineRecordsProvider(storyLineId));
    return records.where((r) => r.status == EncounterStatus.reencounter).length;
  }

  @override
  Widget build(BuildContext context) {
    final controller = RecordDetailController(
      ref: ref,
      isMounted: () => mounted,
    );
    final statusColor = _currentRecord.status.getColor(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => controller.navigateToEditPage(context, _currentRecord),
            tooltip: '编辑',
          ),
          RecordDetailActionMenu(
            onSelected: (action) => controller.handleMenuAction(
              context,
              action,
              _currentRecord,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecordDetailStatusHeader(
              record: _currentRecord,
              statusColor: statusColor,
              reencounterCount: _reencounterCountInStoryLine,
            ),
            const SizedBox(height: 8),
            RecordDetailContent(
              record: _currentRecord,
              storyLineName: _storyLineName,
              onStoryLineTap: () =>
                  controller.navigateToStoryLineDetail(context, _currentRecord),
            ),
          ],
        ),
      ),
    );
  }
}
