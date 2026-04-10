import 'package:flutter/material.dart';
import '../../core/services/export_service.dart';
import '../../core/theme/export_card_palette.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/utils/record_helper.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';

/// 故事线导出长图卡片（会员功能）
///
/// 将故事线所有记录渲染为一张竖向长图，供保存到相册使用。
/// 通过 [RepaintBoundary] + [GlobalKey] 截图，再交给 [ExportService] 保存。
///
/// 使用方式：
/// ```dart
/// final success = await StoryLineExportCard.export(context, storyLine, records);
/// ```
///
/// 调用者：
/// - StoryLinesPage 卡片菜单（会员校验由调用方负责）
/// - StoryLineDetailPage 菜单（会员校验由调用方负责）
class StoryLineExportCard extends StatelessWidget {
  final StoryLine storyLine;
  final List<EncounterRecord> records;

  const StoryLineExportCard({
    super.key,
    required this.storyLine,
    required this.records,
  });

  /// 将故事线渲染并保存到相册
  ///
  /// [records] 必须非空，调用方保证已按时间排序。
  /// 返回 true 表示保存成功。
  ///
  /// 调用者：StoryLinesPage、StoryLineDetailPage
  static Future<bool> export(
    BuildContext context,
    StoryLine storyLine,
    List<EncounterRecord> records,
  ) async {
    assert(records.isNotEmpty, 'records must not be empty');

    return ExportService.runWithDebugPaintDisabled(() async {
      final key = GlobalKey();
      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -2000,
          top: -2000,
          child: RepaintBoundary(
            key: key,
            child: InheritedTheme.captureAll(
              context,
              MediaQuery(
                data: MediaQuery.of(context),
                child: Directionality(
                  textDirection: Directionality.of(context),
                  child: StoryLineExportCard(
                    storyLine: storyLine,
                    records: records,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(entry);
      await Future.delayed(const Duration(milliseconds: 300));

      final bytes = await ExportService.capture(key);
      entry.remove();

      if (bytes == null) return false;
      return ExportService.saveToGallery(bytes, name: 'serendipity_storyline');
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 375,
      child: _CardContent(storyLine: storyLine, records: records),
    );
  }
}

class _CardContent extends StatelessWidget {
  final StoryLine storyLine;
  final List<EncounterRecord> records;

  const _CardContent({
    required this.storyLine,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ExportCardPalette.light(
      accentColor: const Color(0xFF7D6BC9),
    );

    return Container(
      color: palette.backgroundColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部品牌
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: palette.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Serendipity',
                  style: TextStyle(
                    color: palette.secondaryTextColor,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 故事线标题
          Text(
            '📖 ${storyLine.name}',
            style: TextStyle(
              color: palette.primaryTextColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '共 ${records.length} 段记录 · ${DateTimeHelper.formatChineseDate(records.first.timestamp)} 起',
            style: TextStyle(
              color: palette.secondaryTextColor,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // 时间线记录列表
          ...List.generate(records.length, (index) {
            final record = records[index];
            final isLast = index == records.length - 1;
            return _TimelineItem(
              record: record,
              isLast: isLast,
              accentColor: palette.accentColor,
              cardColor: palette.surfaceColor,
              lineColor: palette.dividerColor,
              textPrimary: palette.primaryTextColor,
              textSecondary: palette.secondaryTextColor,
            );
          }),

          const SizedBox(height: 16),

          // 底部水印
          Center(
            child: Text(
              '错过了么 · 有些错过，只能被记住',
              style: TextStyle(
                color: palette.secondaryTextColor.withValues(alpha: 0.72),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final EncounterRecord record;
  final bool isLast;
  final Color accentColor;
  final Color cardColor;
  final Color lineColor;
  final Color textPrimary;
  final Color textSecondary;

  const _TimelineItem({
    required this.record,
    required this.isLast,
    required this.accentColor,
    required this.cardColor,
    required this.lineColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间线轴
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      record.status.icon,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 记录内容
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.22),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 状态 + 日期
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          record.status.label,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateTimeHelper.formatShortDate(record.timestamp),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 地点
                  Text(
                    '📍 ${RecordHelper.getLocationText(record.location)}',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 描述
                  if (record.description != null &&
                      record.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      record.description!,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // 标签
                  if (record.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: record.tags
                          .take(3)
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Text(
                                t.tag,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

