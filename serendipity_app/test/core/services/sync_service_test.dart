import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/core/providers/favorites_provider.dart';
import 'package:serendipity_app/core/repositories/achievement_repository.dart';
import 'package:serendipity_app/core/repositories/i_remote_data_repository.dart';
import 'package:serendipity_app/core/services/i_storage_service.dart';
import 'package:serendipity_app/core/services/sync_service.dart';
import 'package:serendipity_app/models/achievement.dart';
import 'package:serendipity_app/models/achievement_unlock.dart';
import 'package:serendipity_app/models/check_in_record.dart';
import 'package:serendipity_app/models/community_post.dart';
import 'package:serendipity_app/models/encounter_record.dart';
import 'package:serendipity_app/models/enums.dart';
import 'package:serendipity_app/models/membership.dart';
import 'package:serendipity_app/models/push_token_registration.dart';
import 'package:serendipity_app/models/story_line.dart';
import 'package:serendipity_app/models/sync_history.dart';
import 'package:serendipity_app/models/user.dart';
import 'package:serendipity_app/models/user_settings.dart';

void main() {
  group('SyncService membership sync', () {
    late FakeRemoteDataRepository remoteRepository;
    late FakeStorageService storageService;
    late SyncService syncService;

    setUp(() {
      remoteRepository = FakeRemoteDataRepository();
      storageService = FakeStorageService();
      syncService = SyncService(
        remoteRepository: remoteRepository,
        storageService: storageService,
        achievementRepository: AchievementRepository(storageService),
      );
    });

    test('应该在同步时将云端会员写回本地', () async {
      final user = createUser();
      final membership = createMembership(user.id);
      remoteRepository.downloadedMembership = membership;

      await syncService.syncAllData(user, lastSyncTime: DateTime(2026, 4, 1));

      expect(storageService.memberships[user.id], membership);
      expect(remoteRepository.downloadMembershipCallCount, 1);
      expect(storageService.deletedMembershipUserIds, isEmpty);
    });

    test('应该在云端无会员时删除本地残留会员', () async {
      final user = createUser();
      storageService.memberships[user.id] = createMembership(user.id);
      remoteRepository.downloadedMembership = null;

      await syncService.syncAllData(user, lastSyncTime: DateTime(2026, 4, 1));

      expect(storageService.memberships.containsKey(user.id), isFalse);
      expect(storageService.deletedMembershipUserIds, [user.id]);
      expect(remoteRepository.downloadMembershipCallCount, 1);
    });
  });
}

User createUser() {
  return User(
    id: 'user-1',
    email: 'user@example.com',
    authProvider: AuthProvider.email,
    isEmailVerified: true,
    isPhoneVerified: false,
    createdAt: DateTime(2026, 4, 12),
  );
}

Membership createMembership(String userId) {
  return Membership(
    id: 'membership-1',
    userId: userId,
    tier: MembershipTier.premium,
    status: MembershipStatus.active,
    startedAt: DateTime(2026, 4, 1),
    expiresAt: DateTime(2026, 5, 1),
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 12),
  );
}

class FakeRemoteDataRepository implements IRemoteDataRepository {
  Membership? downloadedMembership;
  int downloadMembershipCallCount = 0;

  @override
  Future<Membership?> downloadMembership(String userId) async {
    downloadMembershipCallCount += 1;
    return downloadedMembership;
  }

  @override
  Future<List<EncounterRecord>> downloadRecords(String userId) async => [];

  @override
  Future<List<EncounterRecord>> downloadRecordsSince(String userId, DateTime lastSyncTime) async => [];

  @override
  Future<void> uploadRecord(String userId, EncounterRecord record) async {}

  @override
  Future<void> updateRecord(String userId, EncounterRecord record) async {}

  @override
  Future<void> uploadRecords(String userId, List<EncounterRecord> records) async {}

  @override
  Future<void> deleteRecord(String userId, String recordId) async {}

  @override
  Future<List<EncounterRecord>> filterRecords({required String userId, DateTime? startDate, DateTime? endDate, String? province, String? city, String? area, List<String>? placeNameKeywords, List<String>? descriptionKeywords, List<String>? ifReencounterKeywords, List<String>? conversationStarterKeywords, List<String>? backgroundMusicKeywords, List<String>? placeTypes, List<String>? tags, List<String>? statuses, List<String>? emotionIntensities, List<String>? weathers, String tagMatchMode = 'contains', String sortBy = 'createdAt', String sortOrder = 'desc', int limit = 20, int offset = 0}) async => [];

  @override
  Future<void> uploadStoryLine(String userId, StoryLine storyLine) async {}

  @override
  Future<void> updateStoryLine(String userId, StoryLine storyLine) async {}

  @override
  Future<void> uploadStoryLines(String userId, List<StoryLine> storyLines) async {}

  @override
  Future<List<StoryLine>> downloadStoryLines(String userId) async => [];

  @override
  Future<List<StoryLine>> downloadStoryLinesSince(String userId, DateTime lastSyncTime) async => [];

  @override
  Future<void> deleteStoryLine(String userId, String storyLineId) async {}

  @override
  Future<bool> saveCommunityPost(CommunityPost post, {bool forceReplace = false}) async => false;

  @override
  Future<Map<String, String>> checkPublishStatus(List<EncounterRecord> records) async => {};

  @override
  Future<List<CommunityPost>> getCommunityPosts({int limit = 20, DateTime? lastTimestamp}) async => [];

  @override
  Future<List<CommunityPost>> getMyCommunityPosts(String userId) async => [];

  @override
  Future<void> deleteCommunityPost(String postId, String userId) async {}

  @override
  Future<void> deleteCommunityPostByRecordId(String recordId) async {}

  @override
  Future<List<CommunityPost>> filterCommunityPosts({DateTime? startDate, DateTime? endDate, DateTime? publishStartDate, DateTime? publishEndDate, String? province, String? city, String? area, List<String>? placeTypes, List<String>? tags, List<String>? statuses, String tagMatchMode = 'contains', int limit = 20}) async => [];

  @override
  Future<CheckInRecord> createTodayCheckIn(String userId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getCheckInStatus(String userId, int year, int month) async => throw UnimplementedError();

  @override
  Future<List<CheckInRecord>> downloadCheckIns(String userId) async => [];

  @override
  Future<List<CheckInRecord>> downloadCheckInsSince(String userId, DateTime lastSyncTime) async => [];

  @override
  Future<void> deleteCheckIn(String userId, String checkInId) async {}

  @override
  Future<void> uploadAchievementUnlock(AchievementUnlock unlock) async {}

  @override
  Future<List<AchievementUnlock>> downloadAchievementUnlocks(String userId) async => [];

  @override
  Future<UserSettings> uploadSettings(String userId, UserSettings settings) async => settings;

  @override
  Future<UserSettings?> downloadSettings(String userId) async => null;

  @override
  Future<void> registerPushToken(PushTokenRegistration registration) async {}

  @override
  Future<void> unregisterPushToken(String token) async {}

  @override
  Future<RepositoryPushTokenStatus> listPushTokens() async => const RepositoryPushTokenStatus(pushTokens: []);

  @override
  Future<RepositoryServerTestPushSummary> sendCheckInReminderTest() async => const RepositoryServerTestPushSummary(dispatchSource: 'manual_test', scannedCandidates: 0, sentCount: 0, failedCount: 0);

  @override
  Future<RepositoryServerTestPushSummary> sendAnniversaryReminderTest() async => const RepositoryServerTestPushSummary(dispatchSource: 'manual_test', scannedCandidates: 0, sentCount: 0, failedCount: 0);

  @override
  Future<void> favoritePost(String userId, String postId) async {}

  @override
  Future<void> unfavoritePost(String userId, String postId) async {}

  @override
  Future<FavoritedPostsResult> getFavoritedPostsResult(String userId) async => const FavoritedPostsResult(posts: [], deletedPostIds: {});

  @override
  Future<void> favoriteRecord(String userId, String recordId) async {}

  @override
  Future<void> unfavoriteRecord(String userId, String recordId) async {}

  @override
  Future<FavoritedRecordsResult> getFavoritedRecordsResult(String userId) async => const FavoritedRecordsResult(recordIds: {}, deletedRecordIds: {});
}

class FakeStorageService implements IStorageService {
  final Map<String, Membership> memberships = {};
  final List<String> deletedMembershipUserIds = [];
  final List<SyncHistory> syncHistories = [];
  final Map<String, DateTime> lastSyncTimes = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> saveMembership(Membership membership) async {
    memberships[membership.userId] = membership;
  }

  @override
  Future<Membership?> getMembership(String userId) async => memberships[userId];

  @override
  Future<void> deleteMembership(String userId) async {
    deletedMembershipUserIds.add(userId);
    memberships.remove(userId);
  }

  @override
  Future<void> saveSyncHistory(SyncHistory history) async {
    syncHistories.add(history);
  }

  @override
  List<SyncHistory> getSyncHistoriesByUser(String userId) => syncHistories.where((h) => h.userId == userId).toList();

  @override
  DateTime? getLastSyncTime(String userId) => lastSyncTimes[userId];

  @override
  Future<void> setLastSyncTime(String userId, DateTime syncStartTime) async {
    lastSyncTimes[userId] = syncStartTime;
  }

  @override
  List<EncounterRecord> getRecordsByUser(String? userId) => [];

  @override
  List<StoryLine> getStoryLinesByUser(String? userId) => [];

  @override
  List<CheckInRecord> getCheckInsByUser(String? userId) => [];

  @override
  EncounterRecord? getRecord(String id) => null;

  @override
  Future<void> saveRecord(EncounterRecord record) async {}

  @override
  List<EncounterRecord> getAllRecords() => [];

  @override
  List<EncounterRecord> getRecordsSortedByTime() => [];

  @override
  Future<void> deleteRecord(String id) async {}

  @override
  Future<void> updateRecord(EncounterRecord record) async {}

  @override
  List<EncounterRecord> getRecordsByStoryLine(String storyLineId) => [];

  @override
  List<EncounterRecord> getRecordsWithoutStoryLine() => [];

  @override
  Future<void> saveStoryLine(StoryLine storyLine) async {}

  @override
  StoryLine? getStoryLine(String id) => null;

  @override
  List<StoryLine> getAllStoryLines() => [];

  @override
  List<StoryLine> getStoryLinesSortedByTime() => [];

  @override
  Future<void> deleteStoryLine(String id) async {}

  @override
  Future<void> updateStoryLine(StoryLine storyLine) async {}

  @override
  Future<void> saveAchievement(Achievement achievement) async {}

  @override
  Achievement? getAchievement(String id) => null;

  @override
  List<Achievement> getAllAchievements() => [];

  @override
  Future<void> updateAchievement(Achievement achievement) async {}

  @override
  Future<void> saveCheckIn(CheckInRecord checkIn) async {}

  @override
  CheckInRecord? getCheckIn(String id) => null;

  @override
  List<CheckInRecord> getAllCheckIns() => [];

  @override
  List<CheckInRecord> getCheckInsSortedByDate() => [];

  @override
  Future<void> deleteCheckIn(String id) async {}

  @override
  UserSettings? getUserSettings() => null;

  @override
  Future<void> saveUserSettings(UserSettings settings) async {}

  @override
  List<SyncHistory> getAllSyncHistories() => syncHistories;

  @override
  List<SyncHistory> getRecentSyncHistories(int limit) => syncHistories.take(limit).toList();

  @override
  Future<void> deleteSyncHistory(String id) async {}

  @override
  Future<void> clearAllSyncHistories() async {
    syncHistories.clear();
  }

  @override
  Future<void> saveFavoritedRecordSnapshot(EncounterRecord record) async {}

  @override
  EncounterRecord? getFavoritedRecordSnapshot(String recordId) => null;

  @override
  Future<void> deleteFavoritedRecordSnapshot(String recordId) async {}

  @override
  Future<void> saveFavoritedPostSnapshot(String postId, Map<String, dynamic> postJson) async {}

  @override
  Map<String, dynamic>? getFavoritedPostSnapshot(String postId) => null;

  @override
  Future<void> deleteFavoritedPostSnapshot(String postId) async {}

  @override
  Future<void> set<T>(String key, T value) async {}

  @override
  T? get<T>(String key) => null;

  @override
  Future<void> saveString(String key, String value) async {}

  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> bindOfflineDataToUser(String userId) async {}

  @override
  Future<void> deleteOfflineData() async {}

  @override
  Future<void> clearAuthData() async {}

  @override
  Future<void> deleteUserData(String userId) async {}
}
