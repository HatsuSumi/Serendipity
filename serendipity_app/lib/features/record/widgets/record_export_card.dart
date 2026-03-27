import 'package:flutter/material.dart';
import '../../../core/services/export_service.dart';
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

  const RecordExportCard({super.key, required this.record});

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
    final key = GlobalKey();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -2000,
        top: -2000,
        child: RepaintBoundary(
          key: key,
          child: MediaQuery(
            data: MediaQuery.of(context),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: RecordExportCard(record: record),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    // 等待渲染完成
    await Future.delayed(const Duration(milliseconds: 300));

    final bytes = await ExportService.capture(key);
    entry.remove();

    if (bytes == null) return false;
    return ExportService.saveToGallery(bytes, name: 'serendipity_record');
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

  const _CardContent({required this.record});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF1A1A2E);
    const cardColor = Color(0xFF16213E);
    const accentColor = Color(0xFFE94560);
    const textPrimary = Color(0xFFF5F5F5);
    const textSecondary = Color(0xFFAAAAAA);

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部品牌标识
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Serendipity',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                DateTimeHelper.formatChineseDate(record.timestamp),
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 状态核心区
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态图标 + 标签
                Row(
                  children: [
                    Text(
                      record.status.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.status.label,
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateTimeHelper.formatDateTime(record.timestamp),
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 地点
                _InfoRow(
                  icon: '📍',
                  text: RecordHelper.getLocationText(record.location),
                ),

                // 描述
                if (record.description != null &&
                    record.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: '💭',
                    text: record.description!,
                    maxLines: 4,
                  ),
                ],

                // 情绪
                if (record.emotion != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: '❤️',
                    text: record.emotion!.label,
                  ),
                ],

                // 天气
                if (record.weather.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: '🌤️',
                    text: record.weather.map((w) => w.label).join('  '),
                  ),
                ],

                // 背景音乐
                if (record.backgroundMusic != null &&
                    record.backgroundMusic!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: '🎵',
                    text: record.backgroundMusic!,
                  ),
                ],

                // 对话契机（邂逅状态）
                if (record.conversationStarter != null &&
                    record.conversationStarter!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: '💬',
                    text: record.conversationStarter!,
                    maxLines: 3,
                  ),
                ],

                // 标签
                if (record.tags.isNotEmpty) ...[
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
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              t.tag,
                              style: const TextStyle(
                                color: textPrimary,
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

          // 底部水印
          Center(
            child: Text(
              '错过了么 · 有些错过，只能被记住',
              style: TextStyle(
                color: textSecondary.withValues(alpha: 0.6),
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

  const _InfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    const textSecondary = Color(0xFFAAAAAA);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: textSecondary,
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

