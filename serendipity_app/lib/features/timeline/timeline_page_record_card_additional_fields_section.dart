part of 'timeline_page.dart';

extension _TimelinePageRecordCardAdditionalFieldsSection on _TimelinePageState {
  bool _hasRecordCardAdditionalFields(
    EncounterRecord record,
    RecordsFilterCriteria filterCriteria,
  ) {
    final hasIfReencounterField =
        (filterCriteria.ifReencounterKeywords?.isNotEmpty ?? false) &&
        record.ifReencounter != null &&
        record.ifReencounter!.isNotEmpty;
    final hasConversationStarterField =
        (filterCriteria.conversationStarterKeywords?.isNotEmpty ?? false) &&
        record.conversationStarter != null &&
        record.conversationStarter!.isNotEmpty;
    final hasBackgroundMusicField =
        (filterCriteria.backgroundMusicKeywords?.isNotEmpty ?? false) &&
        record.backgroundMusic != null &&
        record.backgroundMusic!.isNotEmpty;

    return hasIfReencounterField ||
        hasConversationStarterField ||
        hasBackgroundMusicField;
  }

  Widget _buildRecordCardAdditionalFields(
    BuildContext context,
    EncounterRecord record,
    RecordsFilterCriteria filterCriteria,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((filterCriteria.ifReencounterKeywords?.isNotEmpty ?? false) &&
            record.ifReencounter != null &&
            record.ifReencounter!.isNotEmpty) ...[
          _buildFilteredField(
            context,
            '如果再遇',
            record.ifReencounter!,
            filterCriteria.ifReencounterKeywords!,
            statusColor,
          ),
        ],
        if ((filterCriteria.conversationStarterKeywords?.isNotEmpty ?? false) &&
            record.conversationStarter != null &&
            record.conversationStarter!.isNotEmpty) ...[
          if ((filterCriteria.ifReencounterKeywords?.isNotEmpty ?? false) &&
              record.ifReencounter != null &&
              record.ifReencounter!.isNotEmpty)
            const SizedBox(height: 12),
          _buildFilteredField(
            context,
            '对话契机',
            record.conversationStarter!,
            filterCriteria.conversationStarterKeywords!,
            statusColor,
          ),
        ],
        if ((filterCriteria.backgroundMusicKeywords?.isNotEmpty ?? false) &&
            record.backgroundMusic != null &&
            record.backgroundMusic!.isNotEmpty) ...[
          if (((filterCriteria.ifReencounterKeywords?.isNotEmpty ?? false) &&
                  record.ifReencounter != null &&
                  record.ifReencounter!.isNotEmpty) ||
              ((filterCriteria.conversationStarterKeywords?.isNotEmpty ?? false) &&
                  record.conversationStarter != null &&
                  record.conversationStarter!.isNotEmpty))
            const SizedBox(height: 12),
          _buildFilteredField(
            context,
            '背景音乐',
            record.backgroundMusic!,
            filterCriteria.backgroundMusicKeywords!,
            statusColor,
          ),
        ],
      ],
    );
  }
}

