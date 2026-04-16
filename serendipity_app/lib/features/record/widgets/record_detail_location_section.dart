import 'package:flutter/material.dart';
import '../../../core/utils/record_helper.dart';
import '../../../models/encounter_record.dart';

class RecordDetailLocationSection extends StatelessWidget {
  final EncounterRecord record;

  const RecordDetailLocationSection({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (RecordHelper.isLocationEmpty(record.location)) {
      return Text(
        '未知地点',
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (record.location.placeType != null) ...[
          Row(
            children: [
              Text(
                record.location.placeType!.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                record.location.placeType!.label,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (record.location.placeName != null &&
            record.location.placeName!.isNotEmpty) ...[
          Text(
            record.location.placeName!,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (record.location.address != null &&
            record.location.address!.isNotEmpty) ...[
          Text(
            record.location.address!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (RecordHelper.hasCoordinates(record.location))
          Text(
            '纬度: ${record.location.latitude!.toStringAsFixed(6)}, 经度: ${record.location.longitude!.toStringAsFixed(6)}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
      ],
    );
  }
}

