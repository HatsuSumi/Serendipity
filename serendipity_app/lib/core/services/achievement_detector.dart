import '../../models/encounter_record.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/record_repository.dart';
import '../repositories/story_line_repository.dart';
import '../repositories/check_in_repository.dart';
import '../repositories/community_repository.dart';
import 'checkers/record_achievement_checker.dart';
import 'checkers/check_in_achievement_checker.dart';
import 'checkers/story_line_achievement_checker.dart';
import 'checkers/community_achievement_checker.dart';

/// 成就检测服务（协调器）
/// 
/// 负责协调各个成就检测器，统一对外提供成就检测接口
/// 
/// 调用者：
/// - RecordsProvider：记录操作后检测成就
/// - StoryLinesProvider：故事线操作后检测成就
/// - CheckInProvider：签到后检测成就
/// - CommunityProvider：发布到社区后检测成就
/// 
/// 设计原则：
/// - 单一职责：只负责协调各个检测器，不包含具体检测逻辑
/// - 依赖注入：通过构造函数注入依赖
/// - 开闭原则：新增成就类型时，只需添加新的检测器，不修改协调器
class AchievementDetector {
  final RecordAchievementChecker _recordChecker;
  final CheckInAchievementChecker _checkInChecker;
  final StoryLineAchievementChecker _storyLineChecker;
  final CommunityAchievementChecker _communityChecker;

  AchievementDetector(
    AchievementRepository achievementRepository,
    RecordRepository recordRepository,
    StoryLineRepository storyLineRepository,
    CheckInRepository checkInRepository,
    CommunityRepository communityRepository,
  )   : _recordChecker = RecordAchievementChecker(
          achievementRepository,
          recordRepository,
        ),
        _checkInChecker = CheckInAchievementChecker(
          achievementRepository,
          checkInRepository,
        ),
        _storyLineChecker = StoryLineAchievementChecker(
          achievementRepository,
          storyLineRepository,
        ),
        _communityChecker = CommunityAchievementChecker(
          achievementRepository,
          communityRepository,
        );

  /// 检测记录相关成就
  /// 
  /// 在创建或更新记录后调用
  /// 返回新解锁的成就ID列表
  /// 
  /// 参数：
  /// - record: 当前创建或更新的记录
  /// - userId: 当前用户ID（用于数据隔离）
  /// 
  /// Fail Fast：
  /// - userId 为空：由 RecordAchievementChecker 抛出异常
  Future<List<String>> checkRecordAchievements(EncounterRecord record, String userId) async {
    return await _recordChecker.check(record, userId);
  }

  /// 检测签到相关成就
  /// 
  /// 在签到后调用
  /// 返回新解锁的成就ID列表
  Future<List<String>> checkCheckInAchievements() async {
    return await _checkInChecker.check();
  }

  /// 检测故事线相关成就
  /// 
  /// 在创建或更新故事线后调用
  /// 返回新解锁的成就ID列表
  Future<List<String>> checkStoryLineAchievements() async {
    return await _storyLineChecker.check();
  }

  /// 检测社区相关成就
  /// 
  /// 在发布到社区后调用
  /// 
  /// 参数：
  /// - userId: 当前用户ID
  /// 
  /// 返回：新解锁的成就ID列表
  /// 
  /// Fail Fast：
  /// - 如果 userId 为空，由 CommunityAchievementChecker 抛出异常
  Future<List<String>> checkCommunityAchievements(String userId) async {
    return await _communityChecker.check(userId);
  }
}
