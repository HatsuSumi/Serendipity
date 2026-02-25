import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/community_post.dart';
import 'i_remote_data_repository.dart';

/// Supabase 远程数据仓库实现
/// 
/// 使用 PostgreSQL 数据库，不需要预创建复合索引。
/// 支持任意组合的筛选条件，查询灵活。
class SupabaseRemoteDataRepository implements IRemoteDataRepository {
  final SupabaseClient _client;
  
  SupabaseRemoteDataRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  
  // ==================== 记录相关操作 ====================
  
  @override
  Future<void> uploadRecord(String userId, EncounterRecord record) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    await _client
        .from('encounter_records')
        .upsert(record.toJson()..['user_id'] = userId);
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
    
    final data = records
        .map((record) => record.toJson()..['user_id'] = userId)
        .toList();
    
    await _client.from('encounter_records').upsert(data);
  }
  
  @override
  Future<List<EncounterRecord>> downloadRecords(String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    final response = await _client
        .from('encounter_records')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);
    
    return (response as List)
        .map((json) => EncounterRecord.fromJson(json))
        .toList();
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
    
    await _client
        .from('encounter_records')
        .delete()
        .eq('id', recordId)
        .eq('user_id', userId); // 确保只能删除自己的记录
  }
  
  // ==================== 故事线相关操作 ====================
  
  @override
  Future<void> uploadStoryLine(String userId, StoryLine storyLine) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    await _client
        .from('story_lines')
        .upsert(storyLine.toJson()..['user_id'] = userId);
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
    
    final data = storyLines
        .map((storyLine) => storyLine.toJson()..['user_id'] = userId)
        .toList();
    
    await _client.from('story_lines').upsert(data);
  }
  
  @override
  Future<List<StoryLine>> downloadStoryLines(String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    final response = await _client
        .from('story_lines')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => StoryLine.fromJson(json))
        .toList();
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
    
    await _client
        .from('story_lines')
        .delete()
        .eq('id', storyLineId)
        .eq('user_id', userId); // 确保只能删除自己的故事线
  }
  
  // ==================== 社区相关操作 ====================
  
  @override
  Future<void> saveCommunityPost(CommunityPost post) async {
    await _client
        .from('community_posts')
        .upsert(post.toJson());
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
    
    var query = _client
        .from('community_posts')
        .select();
    
    // 分页：获取比 lastTimestamp 更早的帖子
    if (lastTimestamp != null) {
      query = query.lt('published_at', lastTimestamp.toIso8601String());
    }
    
    final response = await query
        .order('published_at', ascending: false)
        .limit(limit);
    
    return (response as List)
        .map((json) => CommunityPost.fromJson(json))
        .toList();
  }
  
  @override
  Future<List<CommunityPost>> getMyCommunityPosts(String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    final response = await _client
        .from('community_posts')
        .select()
        .eq('user_id', userId)
        .order('published_at', ascending: false);
    
    return (response as List)
        .map((json) => CommunityPost.fromJson(json))
        .toList();
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
    
    await _client
        .from('community_posts')
        .delete()
        .eq('id', postId)
        .eq('user_id', userId); // 确保只能删除自己的帖子
  }
  
  @override
  Future<List<CommunityPost>> filterCommunityPosts({
    DateTime? startDate,
    DateTime? endDate,
    String? cityName,
    String? placeType,
    String? tag,
    int? status,
    int limit = 20,
  }) async {
    // Fail Fast：参数验证
    if (limit <= 0) {
      throw ArgumentError('limit 必须大于 0');
    }
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw ArgumentError('开始日期不能晚于结束日期');
    }
    
    // 🎉 重点：Supabase 支持任意组合的筛选条件，不需要预创建索引！
    var query = _client
        .from('community_posts')
        .select();
    
    // 动态添加筛选条件
    if (startDate != null) {
      query = query.gte('timestamp', startDate.toIso8601String());
    }
    
    if (endDate != null) {
      query = query.lte('timestamp', endDate.toIso8601String());
    }
    
    if (cityName != null && cityName.isNotEmpty) {
      query = query.eq('city_name', cityName);
    }
    
    if (placeType != null && placeType.isNotEmpty) {
      query = query.eq('place_type', placeType);
    }
    
    if (tag != null && tag.isNotEmpty) {
      // PostgreSQL 数组查询：检查 tags 数组是否包含指定标签
      query = query.contains('tags', [tag]);
    }
    
    if (status != null) {
      query = query.eq('status', status);
    }
    
    final response = await query
        .order('published_at', ascending: false)
        .limit(limit);
    
    return (response as List)
        .map((json) => CommunityPost.fromJson(json))
        .toList();
  }
}

