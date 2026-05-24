import '../../../models/encounter_record.dart';
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
/// 负责协调各个成就检测器，统一对外提供成就检测接口。
///
/// 设计说明：
/// - 成就定义初始化属于成就域前置条件，应由成就域自身保证
/// - 调用方只负责表达“此刻需要检测哪类成就”，不需要关心初始化细节
class AchievementDetector {
  final AchievementRepository _achievementRepository;
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
  )   : _achievementRepository = achievementRepository,
        _recordChecker = RecordAchievementChecker(
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

  Future<void> _ensureInitialized() async {
    await _achievementRepository.initialize();
  }

  Future<List<String>> checkRecordAchievements(
    EncounterRecord record,
    String userId,
  ) async {
    await _ensureInitialized();
    return await _recordChecker.check(record, userId);
  }

  Future<List<String>> checkRecordAchievementsForUser(String userId) async {
    await _ensureInitialized();
    return await _recordChecker.checkAll(userId);
  }

  Future<List<String>> checkCheckInAchievements(String userId) async {
    await _ensureInitialized();
    return await _checkInChecker.check(userId);
  }

  Future<List<String>> checkStoryLineAchievements(String userId) async {
    await _ensureInitialized();
    return await _storyLineChecker.check(userId);
  }

  Future<List<String>> checkCommunityAchievements(String userId) async {
    await _ensureInitialized();
    return await _communityChecker.check(userId);
  }
}
