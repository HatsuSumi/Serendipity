import '../../models/community_post.dart';
import '../../models/encounter_record.dart';
import 'i_community_data_source.dart';

/// 测试社区数据源
/// 
/// 实现 ICommunityDataSource 接口，用于测试模式
/// 
/// 职责：
/// - 提供模拟数据，不访问真实服务器
/// - 用于离线测试和开发
/// 
/// 设计原则：
/// - 策略模式：可替换的数据源实现
/// - 单一职责（SRP）：只负责测试数据访问
class TestCommunityDataSource implements ICommunityDataSource {
  @override
  Future<bool> publishPost(CommunityPost post, {bool forceReplace = false}) async {
    // 测试模式：直接返回成功（未替换）
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
  Future<List<CommunityPost>> getPosts({
    int limit = 20,
    DateTime? lastTimestamp,
  }) async {
    // 测试模式：返回空列表
    return [];
  }

  @override
  Future<List<CommunityPost>> getMyPosts(String userId) async {
    // 测试模式：返回空列表
    return [];
  }

  @override
  Future<void> deletePost(String postId, String userId) async {
    // 测试模式：直接返回成功
  }

  @override
  Future<void> deletePostByRecordId(String recordId) async {
    // 测试模式：直接返回成功（幂等）
  }

  @override
  Future<List<CommunityPost>> filterPosts({
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
    TagMatchMode tagMatchMode = TagMatchMode.contains,
    int limit = 20,
  }) async {
    // 测试模式：返回空列表
    return [];
  }
}

