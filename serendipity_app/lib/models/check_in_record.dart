import 'package:hive/hive.dart';

part 'check_in_record.g.dart';

/// 签到记录
@HiveType(typeId: 32)
class CheckInRecord {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date; // 签到日期（只保留年月日）
  @HiveField(2)
  final DateTime checkedAt; // 签到时间（完整时间戳）

  CheckInRecord({
    required this.id,
    required this.date,
    required this.checkedAt,
  }) : assert(id.isNotEmpty, 'CheckIn ID cannot be empty');

  /// 创建签到记录（自动生成ID和时间）
  factory CheckInRecord.create() {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    return CheckInRecord(
      id: dateOnly.millisecondsSinceEpoch.toString(),
      date: dateOnly,
      checkedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'checkedAt': checkedAt.toIso8601String(),
    };
  }

  factory CheckInRecord.fromJson(Map<String, dynamic> json) {
    return CheckInRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      checkedAt: DateTime.parse(json['checkedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckInRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

