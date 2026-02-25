import '../../repositories/community_repository.dart';
import 'base_achievement_checker.dart';

/// 社区成就检测器
/// 
/// 职责：
/// - 检测社区相关成就（发布到树洞）
/// 
/// 成就列表：
/// - first_community_post：第一次发布到社区
/// - community_regular：发布10条到社区
/// 
/// 调用者：
/// - AchievementDetector.checkCommunityAchievements()
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责社区成就检测
/// - 依赖注入（DIP）：通过构造函数注入依赖
/// - DRY：继承基类的通用进度检测逻辑
/// - Fail Fast：依赖 Repository 层的参数校验
class CommunityAchievementChecker extends BaseAchievementChecker {
  final CommunityRepository _communityRepository;

  CommunityAchievementChecker(
    super.achievementRepository,
    this._communityRepository,
  );

  /// 检测社区成就
  /// 
  /// 参数：
  /// - userId: 当前用户ID（用于查询用户发布的帖子数量）
  /// 
  /// 返回：新解锁的成就ID列表
  /// 
  /// Fail Fast：
  /// - 如果 userId 为空，由 CommunityRepository 抛出异常
  Future<List<String>> check(String userId) async {
    final unlockedAchievements = <String>[];

    // 获取用户发布的所有帖子
    final myPosts = await _communityRepository.getMyPosts(userId);
    final postCount = myPosts.length;

    // 检测：第一次发布到社区（无进度条的成就）
    if (postCount >= 1) {
      final justUnlocked = await achievementRepository.unlockAchievement('first_community_post');
      if (justUnlocked) {
        unlockedAchievements.add('first_community_post');
      }
    }

    // 检测：树洞常客（发布10条）
    // 使用基类的通用方法，消除重复代码
    unlockedAchievements.addAll(
      await checkProgressAchievements(
        postCount,
        ['community_regular'], // 目标：10条
      ),
    );

    return unlockedAchievements;
  }
}

