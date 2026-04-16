import 'package:flutter/material.dart';
import '../../../models/enums.dart';
import '../../../models/encounter_record.dart';
import '../../../core/utils/date_time_helper.dart';

class RecordDetailStatusHeader extends StatelessWidget {
  final EncounterRecord record;
  final Color statusColor;
  final int reencounterCount;

  const RecordDetailStatusHeader({
    super.key,
    required this.record,
    required this.statusColor,
    required this.reencounterCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.2),
            statusColor.withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            record.status.icon,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 12),
          Text(
            record.status.label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateTimeHelper.formatDateTime(record.timestamp),
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (record.status == EncounterStatus.reencounter &&
              record.storyLineId != null &&
              reencounterCount >= 5)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                '第 $reencounterCount 次看到 TA，\n还是没有说话。\n\n你在等什么，\n你自己知道。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.8,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

