import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/community_post.dart';
import 'i_remote_data_repository.dart';
import '../services/http_client_service.dart';
import '../config/server_config.dart';

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
  Future<void> saveCommunityPost(CommunityPost post) async {
    try {
      await _httpClient.post(
        ServerConfig.communityPosts,
        body: post.toJson(),
      );
    } on HttpException catch (e) {
      throw Exception('发布社区帖子失败：${e.message}');
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
  Future<List<CommunityPost>> filterCommunityPosts({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? publishStartDate,
    DateTime? publishEndDate,
    String? province,
    String? city,
    String? area,
    List<String>? placeTypes,
    String? tag,
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
      if (tag != null && tag.isNotEmpty) {
        queryParams['tag'] = tag;
      }
      if (statuses != null && statuses.isNotEmpty) {
        queryParams['statuses'] = statuses.join(',');
      }
      
      final response = await _httpClient.get(
        ServerConfig.communityPostsFilter,
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
}

