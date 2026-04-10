import 'package:flutter/material.dart';
import '../../../core/services/export_service.dart';
import '../../../core/theme/export_card_palette.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/record_helper.dart';
import '../../../models/encounter_record.dart';

/// 单条记录导出图片卡片
///
/// 将记录渲染为固定模板的图片，供保存到相册使用。
/// 通过 [RepaintBoundary] + [GlobalKey] 截图，再交给 [ExportService] 保存。
///
/// 使用方式：
/// ```dart
/// final success = await RecordExportCard.export(context, record);
/// ```
///
/// 调用者：
/// - TimelinePage 卡片菜单
/// - RecordDetailPage 菜单
class RecordExportCard extends StatelessWidget {
  final EncounterRecord record;

  const RecordExportCard({
    super.key,
    required this.record,
  });

  /// 将记录渲染并保存到相册
  ///
  /// 内部通过 OverlayEntry 将卡片渲染到屏幕外，截图后销毁。
  /// 返回 true 表示保存成功。
  ///
  /// 调用者：TimelinePage、RecordDetailPage
  static Future<bool> export(
    BuildContext context,
    EncounterRecord record,
  ) async {
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
                  child: RecordExportCard(record: record),
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
      return ExportService.saveToGallery(bytes, name: 'serendipity_record');
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 375,
      child: _CardContent(record: record),
    );
  }
}

/// 卡片内容（与 RecordExportCard 分离，保持 build 纯净）
class _CardContent extends StatelessWidget {
  final EncounterRecord record;

  const _CardContent({
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ExportCardPalette.light(
      accentColor: const Color(0xFFD96B7C),
    );
    final hasDescription = record.description != null && record.description!.isNotEmpty;
    final hasEmotion = record.emotion != null;
    final hasWeather = record.weather.isNotEmpty;
    final hasMusic = record.backgroundMusic != null && record.backgroundMusic!.isNotEmpty;
    final hasConversationStarter =
        record.conversationStarter != null && record.conversationStarter!.isNotEmpty;
    final hasTags = record.tags.isNotEmpty;

    return Container(
      color: palette.backgroundColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
              const SizedBox(width: 12),
              Text(
                DateTimeHelper.formatChineseDate(record.timestamp),
                style: TextStyle(
                  color: palette.secondaryTextColor,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: palette.accentColor.withValues(alpha: 0.28),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.status.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.status.label,
                            style: TextStyle(
                              color: palette.primaryTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateTimeHelper.formatDateTime(record.timestamp),
                            style: TextStyle(
                              color: palette.secondaryTextColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: '📍',
                  text: RecordHelper.getLocationText(record.location),
                  textColor: palette.secondaryTextColor,
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: '💭',
                    text: record.description!,
                    textColor: palette.primaryTextColor,
                    maxLines: 4,
                  ),
                ],
                if (hasEmotion) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: '❤️',
                    text: record.emotion!.label,
                    textColor: palette.primaryTextColor,
                  ),
                ],
                if (hasWeather) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: '🌤️',
                    text: record.weather.map((w) => w.label).join('  '),
                    textColor: palette.secondaryTextColor,
                  ),
                ],
                if (hasMusic) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: '🎵',
                    text: record.backgroundMusic!,
                    textColor: palette.primaryTextColor,
                  ),
                ],
                if (hasConversationStarter) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: '💬',
                    text: record.conversationStarter!,
                    textColor: palette.primaryTextColor,
                    maxLines: 3,
                  ),
                ],
                if (hasTags) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: record.tags
                        .take(5)
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accentColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: palette.accentColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              t.tag,
                              style: TextStyle(
                                color: palette.primaryTextColor,
                                fontSize: 12,
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
          const SizedBox(height: 16),
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

/// 信息行（图标 + 文字）
class _InfoRow extends StatelessWidget {
  final String icon;
  final String text;
  final int maxLines;
  final Color textColor;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.textColor,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.5,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
