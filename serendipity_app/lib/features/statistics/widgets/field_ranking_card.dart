import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/statistics_provider.dart';
import '../../../models/statistics.dart';

class FieldRankingCard extends ConsumerWidget {
  final Map<FieldRankingDimension, FieldRankingTable> fieldRankings;

  const FieldRankingCard({
    super.key,
    required this.fieldRankings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = ref.watch(fieldRankingDimensionProvider);
    final table = fieldRankings[selected];
    final items = table?.items ?? [];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 16,
                color: colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                '字段分布明细',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '完整排名，含长尾数据',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: FieldRankingDimension.values.map((dim) {
                final isSelected = dim == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ref
                        .read(fieldRankingDimensionProvider.notifier)
                        .state = dim,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${dim.icon} ${dim.label}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: items.isEmpty
                ? SizedBox(
                    key: ValueKey('empty-$selected'),
                    height: 60,
                    child: Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : _RankingTable(
                    key: ValueKey(selected),
                    items: items,
                    colorScheme: colorScheme,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RankingTable extends StatelessWidget {
  final List<FieldRankingItem> items;
  final ColorScheme colorScheme;

  const _RankingTable({
    super.key,
    required this.items,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = items.first.count;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '名称',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 80),
              SizedBox(
                width: 36,
                child: Text(
                  '次数',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final item = entry.value;
          final ratio = maxCount == 0 ? 0.0 : item.count / maxCount;
          final rankColor = rank == 1
              ? const Color(0xFFFFD700)
              : rank == 2
                  ? const Color(0xFFC0C0C0)
                  : rank == 3
                      ? const Color(0xFFCD7F32)
                      : colorScheme.onSurfaceVariant;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: rank <= 3
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: rankColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor:
                            colorScheme.outline.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rank <= 3
                              ? rankColor
                              : colorScheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${item.count}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

