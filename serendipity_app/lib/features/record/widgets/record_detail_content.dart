import 'package:flutter/material.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../models/enums.dart';
import '../../../models/encounter_record.dart';
import 'record_detail_info_card.dart';
import 'record_detail_location_section.dart';
import 'record_detail_metadata_card.dart';
import 'record_detail_storyline_section.dart';
import 'record_detail_tags_section.dart';

class RecordDetailContent extends StatelessWidget {
  final EncounterRecord record;
  final String? storyLineName;
  final VoidCallback onStoryLineTap;

  const RecordDetailContent({
    super.key,
    required this.record,
    required this.storyLineName,
    required this.onStoryLineTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (record.status == EncounterStatus.met &&
              record.conversationStarter != null &&
              record.conversationStarter!.isNotEmpty)
            RecordDetailInfoCard(
              icon: Icons.chat_bubble_outline,
              title: '对话契机',
              child: Text(
                record.conversationStarter!,
                style: textTheme.bodyLarge,
              ),
            ),
          RecordDetailInfoCard(
            icon: Icons.location_on,
            title: '地点',
            child: RecordDetailLocationSection(record: record),
          ),
          if (record.description != null && record.description!.isNotEmpty)
            RecordDetailInfoCard(
              icon: Icons.description_outlined,
              title: '描述',
              child: Text(
                record.description!,
                style: textTheme.bodyLarge,
              ),
            ),
          if (record.tags.isNotEmpty)
            RecordDetailInfoCard(
              icon: Icons.label_outlined,
              title: '特征标签',
              child: RecordDetailTagsSection(record: record),
            ),
          if (record.emotion != null)
            RecordDetailInfoCard(
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
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          if (record.backgroundMusic != null && record.backgroundMusic!.isNotEmpty)
            RecordDetailInfoCard(
              icon: Icons.music_note_outlined,
              title: '背景音乐',
              child: Text(
                record.backgroundMusic!,
                style: textTheme.bodyLarge,
              ),
            ),
          if (record.weather.isNotEmpty)
            RecordDetailInfoCard(
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
          if (record.ifReencounter != null && record.ifReencounter!.isNotEmpty)
            RecordDetailInfoCard(
              icon: Icons.lightbulb_outline,
              title: '如果再遇',
              child: Text(
                record.ifReencounter!,
                style: textTheme.bodyLarge,
              ),
            ),
          if (record.storyLineId != null && storyLineName != null)
            RecordDetailInfoCard(
              icon: Icons.auto_stories_outlined,
              title: '所属故事线',
              child: RecordDetailStorylineSection(
                storyLineName: storyLineName!,
                onTap: onStoryLineTap,
              ),
            ),
          RecordDetailMetadataCard(
            recordId: record.id,
            createdAtText: DateTimeHelper.formatDateTime(record.createdAt),
            updatedAtText: DateTimeHelper.formatDateTime(record.updatedAt),
          ),
        ],
      ),
    );
  }
}

