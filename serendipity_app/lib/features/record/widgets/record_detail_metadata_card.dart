import 'package:flutter/material.dart';

class RecordDetailMetadataCard extends StatelessWidget {
  final String recordId;
  final String createdAtText;
  final String updatedAtText;

  const RecordDetailMetadataCard({
    super.key,
    required this.recordId,
    required this.createdAtText,
    required this.updatedAtText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '记录信息',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _RecordDetailMetadataRow(label: '记录ID', value: recordId),
            _RecordDetailMetadataRow(label: '创建时间', value: createdAtText),
            _RecordDetailMetadataRow(label: '更新时间', value: updatedAtText),
          ],
        ),
      ),
    );
  }
}

class _RecordDetailMetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _RecordDetailMetadataRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

