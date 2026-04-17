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
import '../services/http_client_service.dart';
import 'custom_server_remote_achievement_repository.dart';
import 'custom_server_remote_check_in_repository.dart';
import 'custom_server_remote_community_repository.dart';
import 'custom_server_remote_membership_repository.dart';
import 'custom_server_remote_push_repository.dart';
import 'custom_server_remote_records_repository.dart';
import 'custom_server_remote_story_lines_repository.dart';
import 'custom_server_remote_user_settings_repository.dart';

/// 自建服务器远程数据仓库实现
/// 
/// 使用自建 Node.js 后端，支持记录、故事线、社区帖子的 CRUD 操作。
class CustomServerRemoteDataRepository implements IRemoteDataRepository {
  final CustomServerRemoteRecordsRepository _recordsRepository;
  final CustomServerRemoteStoryLinesRepository _storyLinesRepository;
  final CustomServerRemoteCommunityRepository _communityRepository;
  final CustomServerRemoteCheckInRepository _checkInRepository;
  final CustomServerRemoteAchievementRepository _achievementRepository;
  final CustomServerRemoteUserSettingsRepository _userSettingsRepository;
  final CustomServerRemoteMembershipRepository _membershipRepository;
  final CustomServerRemotePushRepository _pushRepository;
  
  CustomServerRemoteDataRepository({required HttpClientService httpClient})
      : _recordsRepository = CustomServerRemoteRecordsRepository(httpClient: httpClient),
        _storyLinesRepository = CustomServerRemoteStoryLinesRepository(httpClient: httpClient),
        _communityRepository = CustomServerRemoteCommunityRepository(httpClient: httpClient),
        _checkInRepository = CustomServerRemoteCheckInRepository(httpClient: httpClient),
        _achievementRepository = CustomServerRemoteAchievementRepository(httpClient: httpClient),
        _userSettingsRepository = CustomServerRemoteUserSettingsRepository(httpClient: httpClient),
        _membershipRepository = CustomServerRemoteMembershipRepository(httpClient: httpClient),
        _pushRepository = CustomServerRemotePushRepository(httpClient: httpClient);
  
  // ==================== 记录相关操作 ====================
  
  @override
  Future<void> uploadRecord(String userId, EncounterRecord record) {
    return _recordsRepository.uploadRecord(userId, record);
  }
  
  @override
  Future<void> updateRecord(String userId, EncounterRecord record) {
    return _recordsRepository.updateRecord(userId, record);
  }
  
  @override
  Future<void> uploadRecords(String userId, List<EncounterRecord> records) {
    return _recordsRepository.uploadRecords(userId, records);
  }
  
  @override
  Future<List<EncounterRecord>> downloadRecords(String userId) {
    return _recordsRepository.downloadRecords(userId);
  }
  
  @override
  Future<List<EncounterRecord>> downloadRecordsSince(String userId, DateTime lastSyncTime) {
    return _recordsRepository.downloadRecordsSince(userId, lastSyncTime);
  }
  
  @override
  Future<void> deleteRecord(String userId, String recordId) {
    return _recordsRepository.deleteRecord(userId, recordId);
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
  }) {
    return _recordsRepository.filterRecords(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      province: province,
      city: city,
      area: area,
      placeNameKeywords: placeNameKeywords,
      descriptionKeywords: descriptionKeywords,
      ifReencounterKeywords: ifReencounterKeywords,
      conversationStarterKeywords: conversationStarterKeywords,
      backgroundMusicKeywords: backgroundMusicKeywords,
      placeTypes: placeTypes,
      tags: tags,
      statuses: statuses,
      emotionIntensities: emotionIntensities,
      weathers: weathers,
      tagMatchMode: tagMatchMode,
      sortBy: sortBy,
      sortOrder: sortOrder,
      limit: limit,
      offset: offset,
    );
  }
  
  // ==================== 故事线相关操作 ====================
  
  @override
  Future<void> uploadStoryLine(String userId, StoryLine storyLine) {
    return _storyLinesRepository.uploadStoryLine(userId, storyLine);
  }
  
  @override
  Future<void> updateStoryLine(String userId, StoryLine storyLine) {
    return _storyLinesRepository.updateStoryLine(userId, storyLine);
  }
  
  @override
  Future<void> uploadStoryLines(String userId, List<StoryLine> storyLines) {
    return _storyLinesRepository.uploadStoryLines(userId, storyLines);
  }
  
  @override
  Future<List<StoryLine>> downloadStoryLines(String userId) {
    return _storyLinesRepository.downloadStoryLines(userId);
  }
  
  @override
  Future<List<StoryLine>> downloadStoryLinesSince(String userId, DateTime lastSyncTime) {
    return _storyLinesRepository.downloadStoryLinesSince(userId, lastSyncTime);
  }
  
  @override
  Future<void> deleteStoryLine(String userId, String storyLineId) {
    return _storyLinesRepository.deleteStoryLine(userId, storyLineId);
  }
  
  // ==================== 社区相关操作 ====================
  
  @override
  Future<bool> saveCommunityPost(CommunityPost post, {bool forceReplace = false}) {
    return _communityRepository.saveCommunityPost(post, forceReplace: forceReplace);
  }

  @override
  Future<Map<String, String>> checkPublishStatus(List<EncounterRecord> records) {
    return _communityRepository.checkPublishStatus(records);
  }
  
  @override
  Future<List<CommunityPost>> getCommunityPosts({
    int limit = 20,
    DateTime? lastTimestamp,
  }) {
    return _communityRepository.getCommunityPosts(
      limit: limit,
      lastTimestamp: lastTimestamp,
    );
  }
  
  @override
  Future<List<CommunityPost>> getMyCommunityPosts(String userId) {
    return _communityRepository.getMyCommunityPosts(userId);
  }
  
  @override
  Future<void> deleteCommunityPost(String postId, String userId) {
    return _communityRepository.deleteCommunityPost(postId, userId);
  }

  @override
  Future<void> deleteCommunityPostByRecordId(String recordId) {
    return _communityRepository.deleteCommunityPostByRecordId(recordId);
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
  }) {
    return _communityRepository.filterCommunityPosts(
      startDate: startDate,
      endDate: endDate,
      publishStartDate: publishStartDate,
      publishEndDate: publishEndDate,
      province: province,
      city: city,
      area: area,
      placeTypes: placeTypes,
      tags: tags,
      statuses: statuses,
      tagMatchMode: tagMatchMode,
      limit: limit,
    );
  }
  
  // ==================== 签到相关操作 ====================
  
  @override
  Future<CheckInRecord> createTodayCheckIn(String userId) {
    return _checkInRepository.createTodayCheckIn(userId);
  }

  @override
  Future<Map<String, dynamic>> getCheckInStatus(
    String userId,
    int year,
    int month,
  ) {
    return _checkInRepository.getCheckInStatus(userId, year, month);
  }
  
  @override
  Future<List<CheckInRecord>> downloadCheckIns(String userId) {
    return _checkInRepository.downloadCheckIns(userId);
  }
  
  @override
  Future<List<CheckInRecord>> downloadCheckInsSince(String userId, DateTime lastSyncTime) {
    return _checkInRepository.downloadCheckInsSince(userId, lastSyncTime);
  }
  
  @override
  Future<void> deleteCheckIn(String userId, String checkInId) {
    return _checkInRepository.deleteCheckIn(userId, checkInId);
  }
  
  // ==================== 成就相关操作 ====================
  
  @override
  Future<void> uploadAchievementUnlock(AchievementUnlock unlock) {
    return _achievementRepository.uploadAchievementUnlock(unlock);
  }
  
  @override
  Future<List<AchievementUnlock>> downloadAchievementUnlocks(String userId) {
    return _achievementRepository.downloadAchievementUnlocks(userId);
  }
  
  // ==================== 用户设置相关操作 ====================
  
  @override
  Future<UserSettings> uploadSettings(String userId, UserSettings settings) {
    return _userSettingsRepository.uploadSettings(userId, settings);
  }
  
  @override
  Future<UserSettings?> downloadSettings(String userId) {
    return _userSettingsRepository.downloadSettings(userId);
  }

  @override
  Future<Membership?> downloadMembership(String userId) {
    return _membershipRepository.downloadMembership(userId);
  }

  @override
  Future<Membership> activateMembership(String userId, double monthlyAmount) {
    return _membershipRepository.activateMembership(userId, monthlyAmount);
  }

  @override
  Future<void> registerPushToken(PushTokenRegistration registration) {
    return _pushRepository.registerPushToken(registration);
  }

  @override
  Future<void> unregisterPushToken(String token) {
    return _pushRepository.unregisterPushToken(token);
  }

  @override
  Future<RepositoryPushTokenStatus> listPushTokens() {
    return _pushRepository.listPushTokens();
  }

  @override
  Future<RepositoryServerTestPushSummary> sendCheckInReminderTest() {
    return _pushRepository.sendCheckInReminderTest();
  }

  @override
  Future<RepositoryServerTestPushSummary> sendAnniversaryReminderTest() {
    return _pushRepository.sendAnniversaryReminderTest();
  }

  // ==================== 收藏相关操作 ====================

  @override
  Future<void> favoritePost(String userId, String postId) {
    return _communityRepository.favoritePost(userId, postId);
  }

  @override
  Future<void> unfavoritePost(String userId, String postId) {
    return _communityRepository.unfavoritePost(userId, postId);
  }

  @override
  Future<FavoritedPostsResult> getFavoritedPostsResult(String userId) {
    return _communityRepository.getFavoritedPostsResult(userId);
  }

  @override
  Future<void> favoriteRecord(String userId, String recordId) {
    return _communityRepository.favoriteRecord(userId, recordId);
  }

  @override
  Future<void> unfavoriteRecord(String userId, String recordId) {
    return _communityRepository.unfavoriteRecord(userId, recordId);
  }

  @override
  Future<FavoritedRecordsResult> getFavoritedRecordsResult(String userId) {
    return _communityRepository.getFavoritedRecordsResult(userId);
  }
}

