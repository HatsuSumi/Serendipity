import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/community_post.dart';
import '../../models/check_in_record.dart';
import '../../models/achievement_unlock.dart';
import '../../models/user_settings.dart';
import 'i_remote_data_repository.dart';
import '../services/http_client_service.dart';
import '../config/server_config.dart';
import '../utils/address_helper.dart';

/// 自建服务器远程数据仓库实现
/// 
/// 使用自建 Node.js 后端，支持记录、故事线、社区帖子的 CRUD 操作。
class CustomServerRemoteDataRepository implements IRemoteDataRepository {
  final HttpClientService _httpClient;
  
  CustomServerRemoteDataRepository({required HttpClientService httpClient})
      : _httpClient = httpClient;
  
  // ==================== 记录相关操作 ====================
  
  @override
  Future<void> uploadRecord(String userId, EncounterRecord record) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      await _httpClient.post(
        ServerConfig.records,
        body: record.toJson(),
      );
    } on HttpException catch (e) {
      throw Exception('上传记录失败：${e.message}');
    }
  }
  
  @override
  Future<void> updateRecord(String userId, EncounterRecord record) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      // 使用 PUT API 进行增量更新
      // 只传输完整数据（后端会根据 UpdateRecordDto 只更新传入的字段）
      await _httpClient.put(
        ServerConfig.recordById(record.id),
        body: record.toJson(),
      );
    } on HttpException catch (e) {
      throw Exception('更新记录失败：${e.message}');
    }
  }
  
  @override
  Future<void> uploadRecords(String userId, List<EncounterRecord> records) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    if (records.isEmpty) {
      return; // 允许空列表
    }
    
    try {
      await _httpClient.post(
        ServerConfig.recordsBatch,
        body: {
          'records': records.map((r) => r.toJson()).toList(),
        },
      );
    } on HttpException catch (e) {
      throw Exception('批量上传记录失败：${e.message}');
    }
  }
  
  @override
  Future<List<EncounterRecord>> downloadRecords(String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      final response = await _httpClient.get(ServerConfig.records);
      final data = response['data'] as Map<String, dynamic>;
      final recordsJson = data['records'] as List;
      
      return recordsJson
          .map((json) => EncounterRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载记录失败：${e.message}');
    }
  }
  
  @override
  Future<List<EncounterRecord>> downloadRecordsSince(String userId, DateTime lastSyncTime) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      final response = await _httpClient.get(
        ServerConfig.records,
        queryParams: {
          'lastSyncTime': lastSyncTime.toIso8601String(),
        },
      );
      final data = response['data'] as Map<String, dynamic>;
      final recordsJson = data['records'] as List;
      
      return recordsJson
          .map((json) => EncounterRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载增量记录失败：${e.message}');
    }
  }
  
  @override
  Future<void> deleteRecord(String userId, String recordId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (recordId.isEmpty) {
      throw ArgumentError('记录 ID 不能为空');
    }
    
    try {
      await _httpClient.delete(ServerConfig.recordById(recordId));
    } on HttpException catch (e) {
      throw Exception('删除记录失败：${e.message}');
    }
  }
  
  // ==================== 故事线相关操作 ====================
  
  @override
  Future<void> uploadStoryLine(String userId, StoryLine storyLine) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      await _httpClient.post(
        ServerConfig.storylines,
        body: storyLine.toJson(),
      );
    } on HttpException catch (e) {
      throw Exception('上传故事线失败：${e.message}');
    }
  }
  
  @override
  Future<void> updateStoryLine(String userId, StoryLine storyLine) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      // 使用 PUT API 进行增量更新
      // 只传输完整数据（后端会根据 UpdateStoryLineDto 只更新传入的字段）
      await _httpClient.put(
        ServerConfig.storylineById(storyLine.id),
        body: storyLine.toJson(),
      );
    } on HttpException catch (e) {
      throw Exception('更新故事线失败：${e.message}');
    }
  }
  
  @override
  Future<void> uploadStoryLines(String userId, List<StoryLine> storyLines) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    if (storyLines.isEmpty) {
      return; // 允许空列表
    }
    
    try {
      await _httpClient.post(
        ServerConfig.storylinesBatch,
        body: {
          'storyLines': storyLines.map((s) => s.toJson()).toList(),
        },
      );
    } on HttpException catch (e) {
      throw Exception('批量上传故事线失败：${e.message}');
    }
  }
  
  @override
  Future<List<StoryLine>> downloadStoryLines(String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      final response = await _httpClient.get(ServerConfig.storylines);
      final data = response['data'] as Map<String, dynamic>;
      final storylinesJson = data['storyLines'] as List;
      
      return storylinesJson
          .map((json) => StoryLine.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载故事线失败：${e.message}');
    }
  }
  
  @override
  Future<List<StoryLine>> downloadStoryLinesSince(String userId, DateTime lastSyncTime) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      final response = await _httpClient.get(
        ServerConfig.storylines,
        queryParams: {
          'lastSyncTime': lastSyncTime.toIso8601String(),
        },
      );
      final data = response['data'] as Map<String, dynamic>;
      final storylinesJson = data['storyLines'] as List;
      
      return storylinesJson
          .map((json) => StoryLine.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载增量故事线失败：${e.message}');
    }
  }
  
  @override
  Future<void> deleteStoryLine(String userId, String storyLineId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (storyLineId.isEmpty) {
      throw ArgumentError('故事线 ID 不能为空');
    }
    
    try {
      await _httpClient.delete(ServerConfig.storylineById(storyLineId));
    } on HttpException catch (e) {
      throw Exception('删除故事线失败：${e.message}');
    }
  }
  
  // ==================== 社区相关操作 ====================
  
  @override
  Future<bool> saveCommunityPost(CommunityPost post, {bool forceReplace = false}) async {
    try {
      final body = post.toJson();
      body['forceReplace'] = forceReplace;
      
      final response = await _httpClient.post(
        ServerConfig.communityPosts,
        body: body,
      );
      
      // 从响应中获取 replaced 字段
      final data = response['data'] as Map<String, dynamic>;
      return data['replaced'] as bool? ?? false;
    } on HttpException catch (e) {
      // 如果是 CONFLICT 错误，说明记录内容未变化或需要用户确认
      if (e.errorCode == 'CONFLICT') {
        throw Exception(e.message);
      }
      throw Exception('发布社区帖子失败：${e.message}');
    }
  }

  @override
  Future<Map<String, String>> checkPublishStatus(List<EncounterRecord> records) async {
    // Fail Fast：参数验证
    if (records.isEmpty) {
      throw ArgumentError('records 不能为空');
    }
    
    try {
      final body = {
        'records': records.map((record) {
          return {
            'recordId': record.id,
            'timestamp': record.timestamp.toIso8601String(),
            'address': record.location.address,
            'placeName': record.location.placeName,
            'placeType': record.location.placeType?.value,
            'province': AddressHelper.extractRegion(record.location.address ?? '').province,
            'city': AddressHelper.extractRegion(record.location.address ?? '').city,
            'area': AddressHelper.extractRegion(record.location.address ?? '').area,
            'description': record.description,
            'tags': record.tags.map((t) => {'tag': t.tag, 'note': t.note}).toList(),
            'status': record.status.name,
          };
        }).toList(),
      };
      
      final response = await _httpClient.post(
        '${ServerConfig.communityPosts}/check-status',
        body: body,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      final statuses = data['statuses'] as List;
      
      final result = <String, String>{};
      for (final item in statuses) {
        final recordId = item['recordId'] as String;
        final status = item['status'] as String;
        result[recordId] = status;
      }
      
      return result;
    } on HttpException catch (e) {
      throw Exception('检查发布状态失败：${e.message}');
    }
  }
  
  @override
  Future<List<CommunityPost>> getCommunityPosts({
    int limit = 20,
    DateTime? lastTimestamp,
  }) async {
    // Fail Fast：参数验证
    if (limit <= 0) {
      throw ArgumentError('limit 必须大于 0');
    }
    
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (lastTimestamp != null) {
        queryParams['lastTimestamp'] = lastTimestamp.toIso8601String();
      }
      
      final response = await _httpClient.get(
        ServerConfig.communityPosts,
        queryParams: queryParams,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      final postsJson = data['posts'] as List;
      
      return postsJson
          .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('获取社区帖子失败：${e.message}');
    }
  }
  
  @override
  Future<List<CommunityPost>> getMyCommunityPosts(String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      final response = await _httpClient.get(ServerConfig.communityMyPosts);
      final data = response['data'] as Map<String, dynamic>;
      final postsJson = data['posts'] as List;
      
      return postsJson
          .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('获取我的社区帖子失败：${e.message}');
    }
  }
  
  @override
  Future<void> deleteCommunityPost(String postId, String userId) async {
    // Fail Fast：参数验证
    if (postId.isEmpty) {
      throw ArgumentError('帖子 ID 不能为空');
    }
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      await _httpClient.delete(ServerConfig.communityPostById(postId));
    } on HttpException catch (e) {
      throw Exception('删除社区帖子失败：${e.message}');
    }
  }

  @override
  Future<void> deleteCommunityPostByRecordId(String recordId) async {
    // Fail Fast：参数验证
    if (recordId.isEmpty) {
      throw ArgumentError('记录 ID 不能为空');
    }
    
    try {
      await _httpClient.delete(ServerConfig.communityPostByRecordId(recordId));
    } on HttpException catch (e) {
      throw Exception('按记录删除社区帖子失败：${e.message}');
    }
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
    int limit = 20,
  }) async {
    // Fail Fast：参数验证
    if (limit <= 0) {
      throw ArgumentError('limit 必须大于 0');
    }
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw ArgumentError('错过时间开始日期不能晚于结束日期');
    }
    if (publishStartDate != null && publishEndDate != null && publishStartDate.isAfter(publishEndDate)) {
      throw ArgumentError('发布时间开始日期不能晚于结束日期');
    }
    
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (publishStartDate != null) {
        queryParams['publishStartDate'] = publishStartDate.toIso8601String();
      }
      if (publishEndDate != null) {
        queryParams['publishEndDate'] = publishEndDate.toIso8601String();
      }
      if (province != null && province.isNotEmpty) {
        queryParams['province'] = province;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }
      if (placeTypes != null && placeTypes.isNotEmpty) {
        queryParams['placeTypes'] = placeTypes.join(',');
      }
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }
      if (statuses != null && statuses.isNotEmpty) {
        queryParams['statuses'] = statuses.join(',');
      }
      
      final response = await _httpClient.get(
        ServerConfig.communityPosts,
        queryParams: queryParams,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      final postsJson = data['posts'] as List;
      
      return postsJson
          .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('筛选社区帖子失败：${e.message}');
    }
  }
  
  // ==================== 签到相关操作 ====================
  
  @override
  Future<void> uploadCheckIn(String userId, CheckInRecord checkIn) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      await _httpClient.post(
        ServerConfig.checkIns,
        body: checkIn.toJson(),
      );
    } on HttpException catch (e) {
      throw Exception('上传签到记录失败：${e.message}');
    }
  }
  
  @override
  Future<void> uploadCheckIns(String userId, List<CheckInRecord> checkIns) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    if (checkIns.isEmpty) {
      return; // 允许空列表
    }
    
    try {
      await _httpClient.post(
        ServerConfig.checkInsBatch,
        body: {
          'checkIns': checkIns.map((c) => c.toJson()).toList(),
        },
      );
    } on HttpException catch (e) {
      throw Exception('批量上传签到记录失败：${e.message}');
    }
  }
  
  @override
  Future<List<CheckInRecord>> downloadCheckIns(String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      final response = await _httpClient.get(ServerConfig.checkIns);
      final data = response['data'] as Map<String, dynamic>;
      final checkInsJson = data['checkIns'] as List;
      
      return checkInsJson
          .map((json) => CheckInRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载签到记录失败：${e.message}');
    }
  }
  
  @override
  Future<List<CheckInRecord>> downloadCheckInsSince(String userId, DateTime lastSyncTime) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      final response = await _httpClient.get(
        ServerConfig.checkIns,
        queryParams: {
          'lastSyncTime': lastSyncTime.toIso8601String(),
        },
      );
      final data = response['data'] as Map<String, dynamic>;
      final checkInsJson = data['checkIns'] as List;
      
      return checkInsJson
          .map((json) => CheckInRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载增量签到记录失败：${e.message}');
    }
  }
  
  @override
  Future<void> deleteCheckIn(String userId, String checkInId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (checkInId.isEmpty) {
      throw ArgumentError('签到记录 ID 不能为空');
    }
    
    try {
      await _httpClient.delete(ServerConfig.checkInById(checkInId));
    } on HttpException catch (e) {
      throw Exception('删除签到记录失败：${e.message}');
    }
  }
  
  // ==================== 成就相关操作 ====================
  
  @override
  Future<void> uploadAchievementUnlock(AchievementUnlock unlock) async {
    // Fail Fast：参数验证
    if (unlock.userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (unlock.achievementId.isEmpty) {
      throw ArgumentError('成就 ID 不能为空');
    }
    
    try {
      await _httpClient.post(
        ServerConfig.achievementUnlocks,
        body: unlock.toJson(),
      );
    } on HttpException catch (e) {
      throw Exception('上传成就解锁记录失败：${e.message}');
    }
  }
  
  @override
  Future<List<AchievementUnlock>> downloadAchievementUnlocks(String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      final response = await _httpClient.get(
        ServerConfig.achievementUnlocks,
        queryParams: {'userId': userId},
      );
      final data = response['data'] as Map<String, dynamic>;
      final unlocksJson = data['unlocks'] as List;
      
      return unlocksJson
          .map((json) => AchievementUnlock.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载成就解锁记录失败：${e.message}');
    }
  }
  
  // ==================== 用户设置相关操作 ====================
  
  @override
  Future<UserSettings> uploadSettings(UserSettings settings) async {
    // Fail Fast：参数验证
    if (settings.userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      final response = await _httpClient.put(
        ServerConfig.usersSettings,
        body: settings.toServerDto(),
      );
      // 用服务端返回的最新设置（含服务端生成的 updatedAt）更新本地
      final data = response['data'] as Map<String, dynamic>;
      return UserSettings.fromServerDto(data, settings.userId);
    } on HttpException catch (e) {
      throw Exception('上传用户设置失败：${e.message}');
    }
  }
  
  @override
  Future<UserSettings?> downloadSettings(String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    try {
      final response = await _httpClient.get(ServerConfig.usersSettings);
      final data = response['data'] as Map<String, dynamic>;
      
      // 使用模型的转换方法（单一职责原则）
      return UserSettings.fromServerDto(data, userId);
    } on HttpException catch (e) {
      // 如果是 404，说明用户还没有设置，返回 null
      if (e.statusCode == 404) {
        return null;
      }
      throw Exception('下载用户设置失败：${e.message}');
    }
  }
}

