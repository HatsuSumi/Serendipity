import '../../models/achievement.dart';

/// 成就定义常量
/// 
/// 包含所有29个成就的完整定义
/// 
/// 调用者：
/// - AchievementRepository：初始化成就列表
/// - AchievementDetector：检测成就解锁条件
class AchievementDefinitions {
  AchievementDefinitions._(); // 私有构造函数，防止实例化

  /// 所有成就的定义
  static final List<Achievement> all = [
    // ==================== 新手成就 (3个) ====================
    Achievement(
      id: 'first_missed',
      name: '第一次错过',
      description: '创建第一条记录\n这是一个新的开始',
      icon: '🌫️',
      category: AchievementCategory.beginner,
    ),
    Achievement(
      id: 'record_10',
      name: '记录10次错过',
      description: '累计创建10条记录',
      icon: '📝',
      category: AchievementCategory.beginner,
      progress: 0,
      target: 10,
    ),
    Achievement(
      id: 'streak_7_days',
      name: '连续7天签到',
      description: '连续7天签到',
      icon: '🗓️',
      category: AchievementCategory.beginner,
      progress: 0,
      target: 7,
    ),

    // ==================== 进阶成就 (7个) ====================
    Achievement(
      id: 'first_reencounter',
      name: '第一次再遇',
      description: '第一次标记"再遇"状态',
      icon: '🌟',
      category: AchievementCategory.advanced,
    ),
    Achievement(
      id: 'first_met',
      name: '第一次邂逅',
      description: '第一次标记"邂逅"状态',
      icon: '💫',
      category: AchievementCategory.advanced,
    ),
    Achievement(
      id: 'first_reunion',
      name: '第一次重逢',
      description: '第一次标记"重逢"状态',
      icon: '💝',
      category: AchievementCategory.advanced,
    ),
    Achievement(
      id: 'same_place_5',
      name: '在同一地点错过5次',
      description: '在同一地点（GPS < 100米）创建5条记录',
      icon: '🎯',
      category: AchievementCategory.advanced,
      progress: 0,
      target: 5,
    ),
    Achievement(
      id: 'rainy_day',
      name: '雨天的错过',
      description: '在雨天创建记录',
      icon: '🌧️',
      category: AchievementCategory.advanced,
    ),
    Achievement(
      id: 'late_night',
      name: '深夜的错过',
      description: '在22:00后创建记录',
      icon: '🌙',
      category: AchievementCategory.advanced,
    ),
    Achievement(
      id: 'early_morning',
      name: '清晨的错过',
      description: '在7:00前创建记录',
      icon: '🌅',
      category: AchievementCategory.advanced,
    ),

    // ==================== 稀有成就 (6个) ====================
    Achievement(
      id: 'record_50',
      name: '错过50个人',
      description: '累计创建50条记录',
      icon: '🎊',
      category: AchievementCategory.rare,
      progress: 0,
      target: 50,
    ),
    Achievement(
      id: 'record_100',
      name: '错过100个人',
      description: '累计创建100条记录',
      icon: '💯',
      category: AchievementCategory.rare,
      progress: 0,
      target: 100,
    ),
    Achievement(
      id: 'success_rate_10',
      name: '成功率达到10%',
      description: '邂逅/重逢的记录占比达到10%',
      icon: '🏆',
      category: AchievementCategory.rare,
    ),
    Achievement(
      id: 'streak_30_days',
      name: '连续30天签到',
      description: '连续30天签到',
      icon: '🔥',
      category: AchievementCategory.rare,
      progress: 0,
      target: 30,
    ),
    Achievement(
      id: 'streak_100_days',
      name: '签到大师',
      description: '连续签到100天',
      icon: '💎',
      category: AchievementCategory.rare,
      progress: 0,
      target: 100,
    ),
    Achievement(
      id: 'checkin_100_days',
      name: '百日坚持',
      description: '累计签到100天',
      icon: '💯',
      category: AchievementCategory.rare,
      progress: 0,
      target: 100,
    ),
    Achievement(
      id: 'checkin_365_days',
      name: '全年无休',
      description: '累计签到365天',
      icon: '🎊',
      category: AchievementCategory.rare,
      progress: 0,
      target: 365,
    ),

    // ==================== 故事线成就 (4个) ====================
    Achievement(
      id: 'first_story_line',
      name: '第一条故事线',
      description: '创建第一条故事线',
      icon: '📖',
      category: AchievementCategory.storyLine,
    ),
    Achievement(
      id: 'story_collector',
      name: '故事收集者',
      description: '创建3条故事线',
      icon: '📚',
      category: AchievementCategory.storyLine,
      progress: 0,
      target: 3,
    ),
    Achievement(
      id: 'story_master',
      name: '故事大师',
      description: '创建10条故事线（会员专属）',
      icon: '📕',
      category: AchievementCategory.storyLine,
      progress: 0,
      target: 10,
    ),
    Achievement(
      id: 'true_love',
      name: '真爱无价',
      description: '同一个人的故事线达到10条记录',
      icon: '💝',
      category: AchievementCategory.storyLine,
      progress: 0,
      target: 10,
    ),

    // ==================== 社交成就 (2个) ====================
    Achievement(
      id: 'first_community_post',
      name: '第一次发布到社区',
      description: '第一次匿名发布',
      icon: '🌍',
      category: AchievementCategory.social,
    ),
    Achievement(
      id: 'community_regular',
      name: '树洞常客',
      description: '发布10条到社区',
      icon: '🎭',
      category: AchievementCategory.social,
      progress: 0,
      target: 10,
    ),

    // ==================== 情感成就 (3个) ====================
    Achievement(
      id: 'first_lost',
      name: '第一次失联',
      description: '第一次标记"失联"状态',
      icon: '💔',
      category: AchievementCategory.emotional,
    ),
    Achievement(
      id: 'first_farewell',
      name: '第一次别离',
      description: '第一次标记"别离"状态',
      icon: '🥀',
      category: AchievementCategory.emotional,
    ),
    Achievement(
      id: 'new_beginning',
      name: '重新开始',
      description: '从"别离"状态再次标记"重逢"',
      icon: '🌈',
      category: AchievementCategory.emotional,
    ),

    // ==================== 特殊场景成就 (4个) ====================
    Achievement(
      id: 'subway_regular',
      name: '地铁常客',
      description: '在地铁创建10条记录',
      icon: '🚇',
      category: AchievementCategory.special,
      progress: 0,
      target: 10,
    ),
    Achievement(
      id: 'coffee_shop_met',
      name: '咖啡馆邂逅',
      description: '在咖啡馆创建5条邂逅状态的记录',
      icon: '☕',
      category: AchievementCategory.special,
      progress: 0,
      target: 5,
    ),
    Achievement(
      id: 'city_wanderer',
      name: '城市漫游者',
      description: '在5个不同城市创建记录',
      icon: '🌃',
      category: AchievementCategory.special,
      progress: 0,
      target: 5,
    ),
    Achievement(
      id: 'holiday_missed',
      name: '节日的错过',
      description: '在节日（春节、情人节、圣诞节等）创建记录',
      icon: '🎄',
      category: AchievementCategory.special,
    ),
  ];

  /// 根据ID获取成就定义
  static Achievement? getById(String id) {
    try {
      return all.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据类别获取成就列表
  static List<Achievement> getByCategory(AchievementCategory category) {
    return all.where((achievement) => achievement.category == category).toList();
  }
}

