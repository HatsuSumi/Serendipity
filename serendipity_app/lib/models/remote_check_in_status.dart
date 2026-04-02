import 'check_in_record.dart';

class RemoteCheckInStatus {
  final bool hasCheckedInToday;
  final int consecutiveDays;
  final int totalDays;
  final int currentMonthDays;
  final List<CheckInRecord> recentCheckIns;
  final List<DateTime> checkedInDatesInMonth;

  const RemoteCheckInStatus({
    required this.hasCheckedInToday,
    required this.consecutiveDays,
    required this.totalDays,
    required this.currentMonthDays,
    required this.recentCheckIns,
    required this.checkedInDatesInMonth,
  });

  factory RemoteCheckInStatus.fromJson(Map<String, dynamic> json) {
    final recentCheckInsJson = json['recentCheckIns'] as List<dynamic>? ?? const [];
    final checkedInDatesJson = json['checkedInDatesInMonth'] as List<dynamic>? ?? const [];

    return RemoteCheckInStatus(
      hasCheckedInToday: json['hasCheckedInToday'] as bool? ?? false,
      consecutiveDays: (json['consecutiveDays'] as num? ?? 0).toInt(),
      totalDays: (json['totalDays'] as num? ?? 0).toInt(),
      currentMonthDays: (json['currentMonthDays'] as num? ?? 0).toInt(),
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
      'totalDays': totalDays,
      'currentMonthDays': currentMonthDays,
      'recentCheckIns': recentCheckIns.map((item) => item.toJson()).toList(),
      'checkedInDatesInMonth': checkedInDatesInMonth
          .map((item) => item.toIso8601String())
          .toList(),
    };
  }
}

