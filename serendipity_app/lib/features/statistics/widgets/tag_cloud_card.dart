import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/statistics.dart';

// ---------------------------------------------------------------------------
// 公共入口
// ---------------------------------------------------------------------------

/// 标签词云卡片
///
/// 核心算法：螺旋碰撞检测布局（Archimedean spiral placement）
///
/// 关键设计：
/// 1. TextPainter 精确测量文字尺寸，消除近似估算误差
/// 2. 按 size 降序排列，大词优先占据中心区域
/// 3. 螺旋起点加随机偏移（基于 tag hashCode，保证确定性），避免完全对称
/// 4. 螺旋参数 a=0.6 / dθ=0.15，步长更密，填充更均匀
/// 5. 竖排概率 25%（基于 hashCode 确定性），比固定间隔更自然
/// 6. 颜色按 size 在 primary→tertiary 间线性插值，大词更饱和
class TagCloudCard extends StatelessWidget {
  final List<TagCloudItem> tagCloud;

  const TagCloudCard({
    super.key,
    required this.tagCloud,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (tagCloud.isEmpty) {
      return _EmptyState(colorScheme: colorScheme);
    }

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
            '🏷️ 我最常错过的类型',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => _WordCloud(
              items: tagCloud.take(25).toList(),
              colorScheme: colorScheme,
              canvasWidth: constraints.maxWidth,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 尺寸精确测量
// ---------------------------------------------------------------------------

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

  const pH = 3.0;
  const pW = 7.0;
  final w = tp.width + pW * 2;
  final h = tp.height + pH * 2;
  // 竖排时宽高互换
  return vertical ? Size(h, w) : Size(w, h);
}

// ---------------------------------------------------------------------------
// 布局引擎
// ---------------------------------------------------------------------------

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

  /// AABB 碰撞检测（含 3px gap）
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
  // 大词优先放置
  final sorted = [...items]..sort((a, b) => b.size.compareTo(a.size));

  final placed = <_PlacedWord>[];
  final center = Offset(canvasWidth / 2, canvasHeight / 2);

  for (final item in sorted) {
    // 竖排概率 25%，基于 hashCode 保证确定性（同数据同布局）
    final rand = math.Random(item.tag.hashCode);
    final vertical = rand.nextDouble() < 0.25;

    final fontSize = 11.0 + item.size * 15.0;
    final size = _measureWord(item.tag, fontSize, vertical);

    // 螺旋起点加确定性随机偏移，避免完全对称
    final startOffset = Offset(
      rand.nextDouble() * 20 - 10,
      rand.nextDouble() * 20 - 10,
    );
    final start = center + startOffset;

    // 阿基米德螺旋：r = a * θ，椭圆拉伸 1.5x
    const a = 0.6;
    const dTheta = 0.15;
    const maxIter = 1200;

    bool placed_ = false;
    for (var iter = 0; iter < maxIter; iter++) {
      final theta = dTheta * iter;
      final r = a * theta;
      final dx = r * math.cos(theta) * 1.5;
      final dy = r * math.sin(theta);

      final x = start.dx + dx - size.width / 2;
      final y = start.dy + dy - size.height / 2;

      if (x < 0 || y < 0 ||
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

      if (!placed.any((p) => candidate.overlaps(p))) {
        placed.add(candidate);
        placed_ = true;
        break;
      }
    }

    if (!placed_) continue;
  }

  return placed;
}

// ---------------------------------------------------------------------------
// Widget 层
// ---------------------------------------------------------------------------

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
    final h = _canvasHeight;
    final placed = _layout(
      items: items,
      canvasWidth: canvasWidth,
      canvasHeight: h,
    );

    return SizedBox(
      width: canvasWidth,
      height: h,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final pw in placed)
            Positioned(
              left: pw.topLeft.dx,
              top: pw.topLeft.dy,
              child: _WordChip(
                placed: pw,
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

  /// 颜色按 size 在 primary → tertiary 间线性插值
  Color _resolveColor() {
    final color = Color.lerp(
      colorScheme.primary,
      colorScheme.tertiary,
      placed.item.size,
    )!;
    return color.withValues(alpha: 0.5 + placed.item.size * 0.5);
  }

  /// 背景同色系，低透明度
  Color _resolveBg() {
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
        color: _resolveBg(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: placed.vertical
          ? RotatedBox(quarterTurns: 1, child: text)
          : text,
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          '暂无标签数据',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
