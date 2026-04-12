import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/community_post.dart';
import '../../models/check_in_record.dart';
import '../../models/achievement_unlock.dart';
import '../../models/user_settings.dart';
import '../../models/membership.dart';
import '../../models/push_token_registration.dart';
import 'i_remote_data_repository.dart';
import '../providers/favorites_provider.dart' show FavoritedPostsResult, FavoritedRecordsResult;

/// 测试远程数据仓库
/// 
/// 仅用于开发和测试环境，提供空实现（不执行任何操作）。
/// 遵循依赖倒置原则（DIP），实现 IRemoteDataRepository 接口。
/// 
/// 使用场景：
/// - 开发环境：无需真实后端配置即可测试
/// - 单元测试：避免真实网络请求
/// - 集成测试：提供可预测的行为
class TestRemoteDataRepository implements IRemoteDataRepository {
  @override
  Future<void> uploadRecord(String userId, EncounterRecord record) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<void> updateRecord(String userId, EncounterRecord record) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<void> uploadRecords(String userId, List<EncounterRecord> records) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<List<EncounterRecord>> downloadRecords(String userId) async {
    // 测试模式：返回空列表
    return [];
  }
  
  @override
  Future<List<EncounterRecord>> downloadRecordsSince(String userId, DateTime lastSyncTime) async {
    // 测试模式：返回空列表
    return [];
  }

  @override
  Future<void> deleteRecord(String userId, String recordId) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<List<EncounterRecord>> filterRecords({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? province,
    String? city,
    String? area,
    List<String>? placeNameKeywords,
    List<String>? descriptionKeywords,
    List<String>? ifReencounterKeywords,
    List<String>? conversationStarterKeywords,
    List<String>? backgroundMusicKeywords,
    List<String>? placeTypes,
    List<String>? tags,
    List<String>? statuses,
    List<String>? emotionIntensities,
    List<String>? weathers,
    String tagMatchMode = 'contains',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    int limit = 20,
    int offset = 0,
  }) async {
    // 测试模式：返回空列表
    return [];
  }

  @override
  Future<void> uploadStoryLine(String userId, StoryLine storyLine) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<void> updateStoryLine(String userId, StoryLine storyLine) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<void> uploadStoryLines(String userId, List<StoryLine> storyLines) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<List<StoryLine>> downloadStoryLines(String userId) async {
    // 测试模式：返回空列表
    return [];
  }
  
  @override
  Future<List<StoryLine>> downloadStoryLinesSince(String userId, DateTime lastSyncTime) async {
    // 测试模式：返回空列表
    return [];
  }

  @override
  Future<void> deleteStoryLine(String userId, String storyLineId) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<bool> saveCommunityPost(CommunityPost post, {bool forceReplace = false}) async {
    // 测试模式：不执行任何操作，返回未替换
    return false;
  }

  @override
  Future<Map<String, String>> checkPublishStatus(List<EncounterRecord> records) async {
    // 测试模式：所有记录都可以发布
    return {
      for (var record in records) record.id: 'can_publish',
    };
  }

  @override
  Future<List<CommunityPost>> getCommunityPosts({
    int limit = 20,
    DateTime? lastTimestamp,
  }) async {
    // 测试模式：返回空列表
    return [];
  }

  @override
  Future<List<CommunityPost>> getMyCommunityPosts(String userId) async {
    // 测试模式：返回空列表
    return [];
  }

  @override
  Future<void> deleteCommunityPost(String postId, String userId) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<void> deleteCommunityPostByRecordId(String recordId) async {
    // 测试模式：不执行任何操作（幂等）
  }

  @override
  Future<List<CommunityPost>> filterCommunityPosts({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? publishStartDate,
    DateTime? publishEndDate,
    String? province,
    String? city,
    String? area,
    List<String>? placeTypes,
    List<String>? tags,
    List<String>? statuses,
    String tagMatchMode = 'contains',
    int limit = 20,
  }) async {
    // 测试模式：返回空列表
    return [];
  }
  
  @override
  Future<CheckInRecord> createTodayCheckIn(String userId) async {
    // 测试模式：直接返回服务端创建结果
    return CheckInRecord.create(userId: userId);
  }

  @override
  Future<Map<String, dynamic>> getCheckInStatus(
    String userId,
    int year,
    int month,
  ) async {
    final recentCheckIn = CheckInRecord.create(userId: userId);
    return {
      'hasCheckedInToday': true,
      'consecutiveDays': 1,
      'totalDays': 1,
      'currentMonthDays': 1,
      'recentCheckIns': [recentCheckIn.toJson()],
      'checkedInDatesInMonth': [DateTime(year, month, 1).toIso8601String()],
    };
  }
  
  @override
  Future<List<CheckInRecord>> downloadCheckIns(String userId) async {
    // 测试模式：返回空列表
    return [];
  }
  
  @override
  Future<List<CheckInRecord>> downloadCheckInsSince(String userId, DateTime lastSyncTime) async {
    // 测试模式：返回空列表
    return [];
  }
  
  @override
  Future<void> deleteCheckIn(String userId, String checkInId) async {
    // 测试模式：不执行任何操作
  }
  
  @override
  Future<void> uploadAchievementUnlock(AchievementUnlock unlock) async {
    // 测试模式：不执行任何操作
  }
  
  @override
  Future<List<AchievementUnlock>> downloadAchievementUnlocks(String userId) async {
    // 测试模式：返回空列表
    return [];
  }
  
  @override
  Future<UserSettings> uploadSettings(String userId, UserSettings settings) async {
    // 测试模式：参数一致性校验后直接返回
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (settings.userId != userId) {
      throw ArgumentError('用户设置中的用户 ID 与参数不一致');
    }
    return settings;
  }
  
  @override
  Future<UserSettings?> downloadSettings(String userId) async {
    // 测试模式：返回 null（用户没有设置）
    return null;
  }

  @override
  Future<Membership?> downloadMembership(String userId) async {
    return null;
  }

  @override
  Future<void> registerPushToken(PushTokenRegistration registration) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<void> unregisterPushToken(String token) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<RepositoryPushTokenStatus> listPushTokens() async {
    return const RepositoryPushTokenStatus(pushTokens: []);
  }

  @override
  Future<RepositoryServerTestPushSummary> sendCheckInReminderTest() async {
    return const RepositoryServerTestPushSummary(
      dispatchSource: 'manual_test',
      scannedCandidates: 0,
      sentCount: 0,
      failedCount: 0,
    );
  }

  @override
  Future<RepositoryServerTestPushSummary> sendAnniversaryReminderTest() async {
    return const RepositoryServerTestPushSummary(
      dispatchSource: 'manual_test',
      scannedCandidates: 0,
      sentCount: 0,
      failedCount: 0,
    );
  }

  // ==================== 收藏相关操作 ====================

  @override
  Future<void> favoritePost(String userId, String postId) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<void> unfavoritePost(String userId, String postId) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<FavoritedPostsResult> getFavoritedPostsResult(String userId) async {
    // 测试模式：返回空结果
    return const FavoritedPostsResult(posts: [], deletedPostIds: {});
  }

  @override
  Future<void> favoriteRecord(String userId, String recordId) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<void> unfavoriteRecord(String userId, String recordId) async {
    // 测试模式：不执行任何操作
  }

  @override
  Future<FavoritedRecordsResult> getFavoritedRecordsResult(String userId) async {
    // 测试模式：返回空结果
    return const FavoritedRecordsResult(recordIds: {}, deletedRecordIds: {});
  }
}

