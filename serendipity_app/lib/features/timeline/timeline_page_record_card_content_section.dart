part of 'timeline_page.dart';

extension _TimelinePageRecordCardContentSection on _TimelinePageState {
  Widget _buildRecordCardContent(
    BuildContext context,
    EncounterRecord record,
    RecordsFilterCriteria filterCriteria,
    Color statusColor,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecordLocationSection(record, colorScheme, textTheme),
        if ((filterCriteria.placeNameKeywords?.isNotEmpty ?? false) &&
            record.location.placeName != null &&
            record.location.placeName!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPlaceNameHighlight(record, filterCriteria, statusColor, colorScheme, textTheme),
        ],
        if (record.description != null && record.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildDescriptionHighlight(record, filterCriteria, statusColor, colorScheme, textTheme),
        ],
        if (record.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTagSection(record, filterCriteria, statusColor),
        ],
      ],
    );
  }

  Widget _buildRecordLocationSection(
    EncounterRecord record,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _isMasked
                ? _maskText(RecordHelper.getLocationText(record.location))
                : RecordHelper.getLocationText(record.location),
            style: textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceNameHighlight(
    EncounterRecord record,
    RecordsFilterCriteria filterCriteria,
    Color statusColor,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return buildHighlightedText(
      _isMasked ? _maskText(record.location.placeName!) : record.location.placeName!,
      keywords: _isMasked ? null : filterCriteria.placeNameKeywords,
      highlightColor: statusColor.withValues(alpha: 0.3),
      textStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescriptionHighlight(
    EncounterRecord record,
    RecordsFilterCriteria filterCriteria,
    Color statusColor,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return buildHighlightedText(
      _isMasked ? _maskText(record.description!) : record.description!,
      keywords: _isMasked ? null : filterCriteria.descriptionKeywords,
      highlightColor: statusColor.withValues(alpha: 0.3),
      textStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTagSection(
    EncounterRecord record,
    RecordsFilterCriteria filterCriteria,
    Color statusColor,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: record.tags.take(3).map((tag) {
        bool shouldHighlight = false;
        if (filterCriteria.tags != null && filterCriteria.tags!.isNotEmpty) {
          for (final keyword in filterCriteria.tags!) {
            if (filterCriteria.tagMatchMode == TagMatchMode.wholeWord) {
              if (tag.tag == keyword) {
                shouldHighlight = true;
                break;
              }
            } else {
              if (tag.tag.contains(keyword)) {
                shouldHighlight = true;
                break;
              }
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: shouldHighlight && filterCriteria.tags != null && filterCriteria.tags!.isNotEmpty
              ? buildHighlightedText(
                  _isMasked ? _maskText(tag.tag) : tag.tag,
                  keywords: _isMasked ? null : filterCriteria.tags,
                  highlightColor: statusColor.withValues(alpha: 0.3),
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                  ),
                )
              : Text(
                  _isMasked ? _maskText(tag.tag) : tag.tag,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                  ),
                ),
        );
      }).toList(),
    );
  }
}

