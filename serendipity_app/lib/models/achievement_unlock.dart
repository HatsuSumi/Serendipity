/// 成就解锁记录
/// 
/// 用于云端同步的轻量级数据模型，只包含解锁元数据。
/// 
/// 设计原则：
/// - 单一职责：只负责记录"谁在什么时候解锁了什么成就"
/// - 不包含成就定义（名称、描述等），成就定义由本地 AchievementDefinitions 提供
/// - 用于云端存储和跨设备同步
/// 
/// 调用者：
/// - SyncService：上传/下载成就解锁记录
/// - AchievementRepository：解锁成就时创建记录
class AchievementUnlock {
  /// 用户ID
  final String userId;
  
  /// 成就ID
  final String achievementId;
  
  /// 解锁时间
  final DateTime unlockedAt;

  const AchievementUnlock({
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
  }) : assert(userId != '', 'User ID cannot be empty'),
       assert(achievementId != '', 'Achievement ID cannot be empty');

  /// 从 JSON 反序列化
  /// 
  /// 调用者：
  /// - RemoteDataRepository：从云端下载数据后反序列化
  /// 
  /// Fail Fast：
  /// - 缺少必需字段：抛出 TypeError
  /// - 字段类型错误：抛出 TypeError
  /// - 日期格式错误：抛出 FormatException
  factory AchievementUnlock.fromJson(Map<String, dynamic> json) {
    return AchievementUnlock(
      userId: json['userId'] as String,
      achievementId: json['achievementId'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
    );
  }

  /// 序列化为 JSON
  /// 
  /// 调用者：
  /// - RemoteDataRepository：上传到云端前序列化
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'unlockedAt': unlockedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementUnlock &&
        other.userId == userId &&
        other.achievementId == achievementId &&
        other.unlockedAt == unlockedAt;
  }

  @override
  int get hashCode => Object.hash(userId, achievementId, unlockedAt);

  @override
  String toString() {
    return 'AchievementUnlock(userId: $userId, achievementId: $achievementId, unlockedAt: $unlockedAt)';
  }
}

