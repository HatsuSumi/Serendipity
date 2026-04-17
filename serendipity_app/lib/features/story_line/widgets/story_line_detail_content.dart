import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/encounter_record.dart';
import '../../../models/enums.dart';
import '../../../models/story_line.dart';
import '../story_line_tag_cloud_section.dart';
import 'story_line_record_card.dart';

class StoryLineDetailContent extends StatelessWidget {
  final String storyLineId;
  final StoryLine storyLine;
  final List<EncounterRecord> records;
  final Future<void> Function() onRefresh;
  final void Function(EncounterRecord record) onRecordTap;
  final void Function(EncounterRecord record, String action) onRecordMenuSelected;

  const StoryLineDetailContent({
    super.key,
    required this.storyLineId,
    required this.storyLine,
    required this.records,
    required this.onRefresh,
    required this.onRecordTap,
    required this.onRecordMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.auto_stories_outlined,
        title: '还没有记录',
        description: '点击下方按钮添加第一条记录',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return StoryLineTagCloudSection(storyLineId: storyLineId);
          }

          if (index == records.length + 1) {
            return _StoryLineEndingEpitaph(records: records);
          }

          final record = records[index - 1];
          final isLast = index == records.length;

          return Column(
            children: [
              StoryLineRecordCard(
                record: record,
                storyLine: storyLine,
                onTap: () => onRecordTap(record),
                onMenuSelected: (action) => onRecordMenuSelected(record, action),
              ),
              if (!isLast) const _StoryLineArrow(),
            ],
          );
        },
      ),
    );
  }
}

class _StoryLineEndingEpitaph extends StatelessWidget {
  final List<EncounterRecord> records;

  const _StoryLineEndingEpitaph({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }

    final lastStatus = records.last.status;
    String? text;
    if (lastStatus == EncounterStatus.lost) {
      text = 'TA 没有说再见。\n只是有一天，就再也没出现了。\n\n这种结局没有仪式感，\n所以才更难放下。';
    } else if (lastStatus == EncounterStatus.farewell) {
      text = '你们好好说了再见。\n\n这已经是很多人\n求而不得的奢侈了。';
    }

    if (text == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.8,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _StoryLineArrow extends StatelessWidget {
  const _StoryLineArrow();

  @override
  Widget build(BuildContext context) {
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
}

