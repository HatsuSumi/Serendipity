import '../../models/community_post.dart';
import '../../models/encounter_record.dart';
import '../config/server_config.dart';
import '../providers/favorites_provider.dart' show FavoritedPostsResult, FavoritedRecordsResult;
import '../services/http_client_service.dart';
import '../utils/address_helper.dart';

class CustomServerRemoteCommunityRepository {
  final HttpClientService _httpClient;

  const CustomServerRemoteCommunityRepository({required HttpClientService httpClient})
      : _httpClient = httpClient;

  Future<bool> saveCommunityPost(CommunityPost post, {bool forceReplace = false}) async {
    try {
      final body = post.toJson();
      body['forceReplace'] = forceReplace;

      final response = await _httpClient.post(
        ServerConfig.communityPosts,
        body: body,
      );

      final data = response['data'] as Map<String, dynamic>;
      return data['replaced'] as bool? ?? false;
    } on HttpException catch (e) {
      if (e.errorCode == 'CONFLICT') {
        throw Exception(e.message);
      }
      throw Exception('发布社区帖子失败：${e.message}');
    }
  }

  Future<Map<String, String>> checkPublishStatus(List<EncounterRecord> records) async {
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

  Future<List<CommunityPost>> getCommunityPosts({
    int limit = 20,
    DateTime? lastTimestamp,
  }) async {
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
        skipAuth: false,
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

  Future<List<CommunityPost>> getMyCommunityPosts(String userId) async {
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

  Future<void> deleteCommunityPost(String postId, String userId) async {
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

  Future<void> deleteCommunityPostByRecordId(String recordId) async {
    if (recordId.isEmpty) {
      throw ArgumentError('记录 ID 不能为空');
    }

    try {
      await _httpClient.delete(ServerConfig.communityPostByRecordId(recordId));
    } on HttpException catch (e) {
      throw Exception('按记录删除社区帖子失败：${e.message}');
    }
  }

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
      if (tagMatchMode == 'wholeWord') {
        queryParams['tagMatchMode'] = tagMatchMode;
      }
      if (statuses != null && statuses.isNotEmpty) {
        queryParams['statuses'] = statuses.join(',');
      }

      final response = await _httpClient.get(
        ServerConfig.communityPosts,
        queryParams: queryParams,
        skipAuth: false,
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

  Future<void> favoritePost(String userId, String postId) async {
    if (userId.isEmpty) throw ArgumentError('用户 ID 不能为空');
    if (postId.isEmpty) throw ArgumentError('帖子 ID 不能为空');
    try {
      await _httpClient.post(ServerConfig.favoritePosts, body: {'postId': postId});
    } on HttpException catch (e) {
      throw Exception('收藏帖子失败：${e.message}');
    }
  }

  Future<void> unfavoritePost(String userId, String postId) async {
    if (userId.isEmpty) throw ArgumentError('用户 ID 不能为空');
    if (postId.isEmpty) throw ArgumentError('帖子 ID 不能为空');
    try {
      await _httpClient.delete(ServerConfig.favoritePostById(postId));
    } on HttpException catch (e) {
      throw Exception('取消收藏帖子失败：${e.message}');
    }
  }

  Future<FavoritedPostsResult> getFavoritedPostsResult(String userId) async {
    if (userId.isEmpty) throw ArgumentError('用户 ID 不能为空');
    try {
      final response = await _httpClient.get(ServerConfig.favoritePosts);
      final data = response['data'] as Map<String, dynamic>;
      final postsJson = data['posts'] as List;
      final posts = postsJson
          .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
          .toList();
      final deletedPostIds = ((data['deletedPostIds'] as List?) ?? [])
          .map((e) => e as String)
          .toSet();
      final deletedPostsJson = (data['deletedPosts'] as List?) ?? const [];
      final deletedPosts = deletedPostsJson
          .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
          .toList();
      return FavoritedPostsResult(
        posts: posts,
        deletedPostIds: deletedPostIds,
        deletedPosts: deletedPosts,
      );
    } on HttpException catch (e) {
      throw Exception('获取收藏帖子失败：${e.message}');
    }
  }

  Future<void> favoriteRecord(String userId, String recordId) async {
    if (userId.isEmpty) throw ArgumentError('用户 ID 不能为空');
    if (recordId.isEmpty) throw ArgumentError('记录 ID 不能为空');
    try {
      await _httpClient.post(ServerConfig.favoriteRecords, body: {'recordId': recordId});
    } on HttpException catch (e) {
      throw Exception('收藏记录失败：${e.message}');
    }
  }

  Future<void> unfavoriteRecord(String userId, String recordId) async {
    if (userId.isEmpty) throw ArgumentError('用户 ID 不能为空');
    if (recordId.isEmpty) throw ArgumentError('记录 ID 不能为空');
    try {
      await _httpClient.delete(ServerConfig.favoriteRecordById(recordId));
    } on HttpException catch (e) {
      throw Exception('取消收藏记录失败：${e.message}');
    }
  }

  Future<FavoritedRecordsResult> getFavoritedRecordsResult(String userId) async {
    if (userId.isEmpty) throw ArgumentError('用户 ID 不能为空');
    try {
      final response = await _httpClient.get(ServerConfig.favoriteRecords);
      final data = response['data'] as Map<String, dynamic>;
      final recordsJson = data['records'] as List;
      final records = recordsJson
          .map((json) => EncounterRecord.fromJson(json as Map<String, dynamic>))
          .toList();
      final deletedRecordIds = ((data['deletedRecordIds'] as List?) ?? [])
          .map((e) => e as String)
          .toSet();
      final deletedRecordsJson = (data['deletedRecords'] as List?) ?? const [];
      final deletedRecords = deletedRecordsJson
          .map((json) => EncounterRecord.fromJson(json as Map<String, dynamic>))
          .toList();
      return FavoritedRecordsResult(
        records: records,
        deletedRecordIds: deletedRecordIds,
        deletedRecords: deletedRecords,
      );
    } on HttpException catch (e) {
      throw Exception('获取收藏记录失败：${e.message}');
    }
  }
}

