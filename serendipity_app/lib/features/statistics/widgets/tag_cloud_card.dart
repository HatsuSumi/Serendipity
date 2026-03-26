import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/statistics.dart';

const _maxVisibleTagCloudItems = 25;

/// 通用标签词云面板。
///
/// 职责：
/// - 负责词云卡片的通用容器与空状态展示
/// - 复用同一套布局与渲染算法
///
/// 调用者：
/// - `TagCloudCard`：全局统计页包装层
/// - 故事线详情页的局部词云模块
class TagCloudPanel extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<TagCloudItem> tagCloud;

  const TagCloudPanel({
    super.key,
    required this.title,
    required this.emptyText,
    required this.tagCloud,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (tagCloud.isEmpty)
            _EmptyState(
              colorScheme: colorScheme,
              emptyText: emptyText,
            )
          else
          LayoutBuilder(
            builder: (context, constraints) => _WordCloud(
              items: tagCloud.take(_maxVisibleTagCloudItems).toList(),
              colorScheme: colorScheme,
              canvasWidth: constraints.maxWidth,
            ),
          ),
        ],
      ),
    );
  }
}

/// 标签词云卡片（全局统计页包装层）
class TagCloudCard extends StatelessWidget {
  final List<TagCloudItem> tagCloud;

  const TagCloudCard({
    super.key,
    required this.tagCloud,
  });

  @override
  Widget build(BuildContext context) {
    return TagCloudPanel(
      title: '🏷️ 我最常错过的类型',
      emptyText: '暂无标签数据',
      tagCloud: tagCloud,
    );
  }
}

/// 用 TextPainter 精确测量词语渲染尺寸（含 padding）
Size _measureWord(String text, double fontSize, bool vertical) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  const paddingVertical = 3.0;
  const paddingHorizontal = 7.0;
  final width = tp.width + paddingHorizontal * 2;
  final height = tp.height + paddingVertical * 2;
  return vertical ? Size(height, width) : Size(width, height);
}

class _PlacedWord {
  final TagCloudItem item;
  final Offset topLeft;
  final double width;
  final double height;
  final bool vertical;

  const _PlacedWord({
    required this.item,
    required this.topLeft,
    required this.width,
    required this.height,
    required this.vertical,
  });

  bool overlaps(_PlacedWord other) {
    const gap = 3.0;
    return topLeft.dx < other.topLeft.dx + other.width + gap &&
        topLeft.dx + width + gap > other.topLeft.dx &&
        topLeft.dy < other.topLeft.dy + other.height + gap &&
        topLeft.dy + height + gap > other.topLeft.dy;
  }
}

List<_PlacedWord> _layout({
  required List<TagCloudItem> items,
  required double canvasWidth,
  required double canvasHeight,
}) {
  final sorted = [...items]..sort((a, b) => b.size.compareTo(a.size));

  final placed = <_PlacedWord>[];
  final center = Offset(canvasWidth / 2, canvasHeight / 2);

  for (final item in sorted) {
    final random = math.Random(item.tag.hashCode);
    final vertical = random.nextDouble() < 0.25;

    final fontSize = 11.0 + item.size * 15.0;
    final size = _measureWord(item.tag, fontSize, vertical);

    final startOffset = Offset(
      random.nextDouble() * 20 - 10,
      random.nextDouble() * 20 - 10,
    );
    final start = center + startOffset;

    const a = 0.6;
    const deltaTheta = 0.15;
    const maxIterations = 1200;

    var isPlaced = false;
    for (var iteration = 0; iteration < maxIterations; iteration++) {
      final theta = deltaTheta * iteration;
      final radius = a * theta;
      final dx = radius * math.cos(theta) * 1.5;
      final dy = radius * math.sin(theta);

      final x = start.dx + dx - size.width / 2;
      final y = start.dy + dy - size.height / 2;

      if (x < 0 ||
          y < 0 ||
          x + size.width > canvasWidth ||
          y + size.height > canvasHeight) {
        continue;
      }

      final candidate = _PlacedWord(
        item: item,
        topLeft: Offset(x, y),
        width: size.width,
        height: size.height,
        vertical: vertical,
      );

      if (!placed.any((existing) => candidate.overlaps(existing))) {
        placed.add(candidate);
        isPlaced = true;
        break;
      }
    }

    if (!isPlaced) {
      continue;
    }
  }

  return placed;
}

class _WordCloud extends StatelessWidget {
  final List<TagCloudItem> items;
  final ColorScheme colorScheme;
  final double canvasWidth;

  const _WordCloud({
    required this.items,
    required this.colorScheme,
    required this.canvasWidth,
  });

  double get _canvasHeight {
    if (items.length <= 5) return 180;
    if (items.length <= 10) return 260;
    if (items.length <= 15) return 340;
    if (items.length <= 20) return 420;
    return 480;
  }

  @override
  Widget build(BuildContext context) {
    final canvasHeight = _canvasHeight;
    final placed = _layout(
      items: items,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );

    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final word in placed)
            Positioned(
              left: word.topLeft.dx,
              top: word.topLeft.dy,
              child: _WordChip(
                placed: word,
                colorScheme: colorScheme,
              ),
            ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final _PlacedWord placed;
  final ColorScheme colorScheme;

  const _WordChip({required this.placed, required this.colorScheme});

  double get _fontSize => 11.0 + placed.item.size * 15.0;

  Color _resolveColor() {
    final color = Color.lerp(
      colorScheme.primary,
      colorScheme.tertiary,
      placed.item.size,
    )!;
    return color.withValues(alpha: 0.5 + placed.item.size * 0.5);
  }

  Color _resolveBackgroundColor() {
    final color = Color.lerp(
      colorScheme.primaryContainer,
      colorScheme.tertiaryContainer,
      placed.item.size,
    )!;
    return color.withValues(alpha: 0.30 + placed.item.size * 0.25);
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      placed.item.tag,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: placed.item.size > 0.6 ? FontWeight.w700 : FontWeight.w500,
        color: _resolveColor(),
        height: 1.2,
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: placed.vertical ? 4 : 7,
        vertical: placed.vertical ? 7 : 3,
      ),
      decoration: BoxDecoration(
        color: _resolveBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: placed.vertical
          ? RotatedBox(quarterTurns: 1, child: text)
          : text,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final String emptyText;

  const _EmptyState({
    required this.colorScheme,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(
        emptyText,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
