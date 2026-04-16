import 'package:flutter/material.dart';

class RecordDetailStorylineSection extends StatelessWidget {
  final String storyLineName;
  final VoidCallback onTap;

  const RecordDetailStorylineSection({
    super.key,
    required this.storyLineName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Text('📖 '),
            Expanded(
              child: Text(
                storyLineName,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

