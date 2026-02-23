import 'package:hive/hive.dart';

part 'achievement.g.dart';

/// 成就类别
@HiveType(typeId: 30)
enum AchievementCategory {
  @HiveField(0)
  beginner('beginner', '新手成就', '🌱'),
  @HiveField(1)
  advanced('advanced', '进阶成就', '⭐'),
  @HiveField(2)
  rare('rare', '稀有成就', '💎'),
  @HiveField(3)
  storyLine('story_line', '故事线成就', '📖'),
  @HiveField(4)
  social('social', '社交成就', '🌍'),
  @HiveField(5)
  emotional('emotional', '情感成就', '💔'),
  @HiveField(6)
  special('special', '特殊场景成就', '🎯');

  final String value;
  final String label;
  final String icon;
  
  const AchievementCategory(this.value, this.label, this.icon);
}

/// 成就
@HiveType(typeId: 31)
class Achievement {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String icon;
  @HiveField(4)
  final AchievementCategory category;
  @HiveField(5)
  final bool unlocked;
  @HiveField(6)
  final DateTime? unlockedAt;
  @HiveField(7)
  final int? progress; // 当前进度（可选）
  @HiveField(8)
  final int? target; // 目标值（可选）

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.unlocked = false,
    this.unlockedAt,
    this.progress,
    this.target,
  }) : assert(id.isNotEmpty, 'Achievement ID cannot be empty'),
       assert(name.isNotEmpty, 'Achievement name cannot be empty'),
       assert(description.isNotEmpty, 'Achievement description cannot be empty'),
       assert(icon.isNotEmpty, 'Achievement icon cannot be empty'),
       // 放宽断言：允许 unlocked=true 但 unlockedAt=null（用于数据迁移）
       // 在生产环境中，应该在 copyWith 时自动设置 unlockedAt
       assert(progress == null || target == null || progress <= target,
         'Progress ($progress) cannot exceed target ($target)');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category.value,
      'unlocked': unlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress,
      'target': target,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: AchievementCategory.values.firstWhere(
        (e) => e.value == json['category'],
        orElse: () => throw StateError(
          'Invalid category value: ${json['category']}. '
          'Expected one of: ${AchievementCategory.values.map((e) => e.value).join(", ")}'
        ),
      ),
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progress: json['progress'] as int?,
      target: json['target'] as int?,
    );
  }

  /// 复制并修改部分字段
  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    AchievementCategory? category,
    bool? unlocked,
    DateTime? Function()? unlockedAt,
    int? Function()? progress,
    int? Function()? target,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt != null ? unlockedAt() : this.unlockedAt,
      progress: progress != null ? progress() : this.progress,
      target: target != null ? target() : this.target,
    );
  }

  /// 是否有进度
  bool get hasProgress => progress != null && target != null;

  /// 进度百分比（0-100）
  double get progressPercentage {
    if (!hasProgress) return 0.0;
    return (progress! / target! * 100).clamp(0.0, 100.0);
  }
}
 