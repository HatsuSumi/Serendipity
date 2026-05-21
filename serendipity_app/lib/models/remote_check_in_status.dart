import 'check_in_record.dart';

class RemoteCheckInStatus {
  final bool hasCheckedInToday;
  final int consecutiveDays;
  final int displayConsecutiveDays;
  final int totalDays;
  final int currentMonthDays;
  final List<CheckInRecord> recentCheckIns;
  final List<DateTime> checkedInDatesInMonth;

  const RemoteCheckInStatus({
    required this.hasCheckedInToday,
    required this.consecutiveDays,
    required this.displayConsecutiveDays,
    required this.totalDays,
    required this.currentMonthDays,
    required this.recentCheckIns,
    required this.checkedInDatesInMonth,
  });

  factory RemoteCheckInStatus.fromJson(Map<String, dynamic> json) {
    final recentCheckInsJson = json['recentCheckIns'] as List<dynamic>? ?? const [];
    final checkedInDatesJson = json['checkedInDatesInMonth'] as List<dynamic>? ?? const [];

    int readInt(String key) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return 0;
    }

    final consecutiveDays = readInt('consecutiveDays');
    final displayConsecutiveDays = json.containsKey('displayConsecutiveDays')
        ? readInt('displayConsecutiveDays')
        : consecutiveDays;

    return RemoteCheckInStatus(
      hasCheckedInToday: json['hasCheckedInToday'] as bool? ?? false,
      consecutiveDays: consecutiveDays,
      displayConsecutiveDays: displayConsecutiveDays,
      totalDays: readInt('totalDays'),
      currentMonthDays: readInt('currentMonthDays'),
      recentCheckIns: recentCheckInsJson
          .map((item) => CheckInRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      checkedInDatesInMonth: checkedInDatesJson
          .map((item) => DateTime.parse(item as String))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasCheckedInToday': hasCheckedInToday,
      'consecutiveDays': consecutiveDays,
      'displayConsecutiveDays': displayConsecutiveDays,
      'totalDays': totalDays,
      'currentMonthDays': currentMonthDays,
      'recentCheckIns': recentCheckIns.map((item) => item.toJson()).toList(),
      'checkedInDatesInMonth': checkedInDatesInMonth
          .map((item) => item.toIso8601String())
          .toList(),
    };
  }
}
