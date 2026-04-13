import 'package:hive/hive.dart';

part 'check_in_record.g.dart';

/// 签到记录
/// 
/// 支持本地存储（Hive）和云端同步（PostgreSQL）
/// 
/// 调用者：
/// - CheckInRepository：签到数据访问层
/// - SyncService：云端同步服务
@HiveType(typeId: 32)
class CheckInRecord {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime date; // 签到日期（只保留年月日）
  
  @HiveField(2)
  final DateTime checkedAt; // 签到时间（完整时间戳）
  
  @HiveField(3)
  final String? userId; // 用户ID（可选，未登录时为 null）
  
  @HiveField(4)
  final DateTime createdAt; // 创建时间
  
  @HiveField(5)
  final DateTime updatedAt; // 更新时间（用于同步冲突解决）

  @HiveField(6)
  final DateTime? deletedAt; // 删除时间（墓碑同步）

  CheckInRecord({
    required this.id,
    required this.date,
    required this.checkedAt,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : assert(id.isNotEmpty, 'CheckIn ID cannot be empty');

  /// 创建签到记录（自动生成ID和时间）
  /// 
  /// 参数：
  /// - userId: 用户ID（可选，未登录时为 null）
  /// 
  /// ID 生成策略：
  /// - 使用 UUID 保证全局唯一性
  /// - 后端通过 (userId, date) 唯一约束去重
  /// - 支持离线签到（未登录时 userId 为 null）
  /// 
  /// 调用者：
  /// - CheckInRepository.checkIn()
  factory CheckInRecord.create({String? userId}) {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    
    // 使用时间戳作为简单的 ID（客户端本地唯一即可）
    // 后端会根据 (userId, date) 唯一约束去重
    final id = '${dateOnly.millisecondsSinceEpoch}_${now.millisecondsSinceEpoch}';
    
    return CheckInRecord(
      id: id,
      date: dateOnly,
      checkedAt: now,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );
  }

  /// 转换为 JSON（用于云端同步）
  /// 
  /// 调用者：
  /// - CustomServerRemoteDataRepository.uploadCheckIn()
  /// - CustomServerRemoteDataRepository.uploadCheckIns()
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'checkedAt': checkedAt.toIso8601String(),
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// 从 JSON 创建（用于云端同步）
  /// 
  /// Fail Fast：
  /// - 必填字段缺失：抛出 TypeError
  /// - 日期格式错误：抛出 FormatException
  /// 
  /// 调用者：
  /// - CustomServerRemoteDataRepository.downloadCheckIns()
  factory CheckInRecord.fromJson(Map<String, dynamic> json) {
    return CheckInRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      checkedAt: DateTime.parse(json['checkedAt'] as String),
      userId: json['userId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  /// 复制并修改部分字段
  /// 
  /// 调用者：
  /// - CheckInRepository（如需更新签到记录）
  CheckInRecord copyWith({
    String? id,
    DateTime? date,
    DateTime? checkedAt,
    String? Function()? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? Function()? deletedAt,
  }) {
    return CheckInRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      checkedAt: checkedAt ?? this.checkedAt,
      userId: userId != null ? userId() : this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
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

