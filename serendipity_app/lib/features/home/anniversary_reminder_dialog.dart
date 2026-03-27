import 'package:flutter/material.dart';
import '../../core/utils/anniversary_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../models/encounter_record.dart';
import '../record/record_detail_page.dart';

/// 纪念日提醒弹窗
///
/// 展示今天所有"邂逅"周年纪念日的记录列表。
/// 每天首次打开 App 时由 MainNavigationPage 触发，每天最多显示一次。
///
/// 调用者：
/// - MainNavigationPage._checkAnniversaryReminder()
class AnniversaryReminderDialog extends StatelessWidget {
  final List<EncounterRecord> records;

  const AnniversaryReminderDialog({super.key, required this.records})
      : assert(records.length > 0, 'records must not be empty');

  /// 显示纪念日提醒弹窗
  ///
  /// 调用者：MainNavigationPage._checkAnniversaryReminder()
  static Future<void> show(
    BuildContext context,
    List<EncounterRecord> records,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => AnniversaryReminderDialog(records: records),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Text('🌸', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '今天是特别的纪念日',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '你有 ${records.length} 段邂逅迎来了周年纪念日',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: records.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final record = records[index];
                  final years = AnniversaryHelper.getAnniversaryYears(record);
                  final place = record.location.placeName ??
                      record.location.address ??
                      record.location.placeType?.label ??
                      '某个地方';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Text('💫', style: TextStyle(fontSize: 20)),
                    title: Text(
                      '$years 年前的今天',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '在$place邂逅了TA · ${DateTimeHelper.formatChineseDate(record.timestamp)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecordDetailPage(record: record),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('好的'),
        ),
      ],
    );
  }
}

