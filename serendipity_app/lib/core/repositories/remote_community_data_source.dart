import '../../models/community_post.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import 'i_community_data_source.dart';
import 'i_remote_data_repository.dart';

/// 远程社区数据源
/// 
/// 实现 ICommunityDataSource 接口，使用真实的远程服务器
/// 
/// 职责：
/// - 委托给 IRemoteDataRepository 执行实际的网络请求
/// - 适配接口，将 Repository 的调用转换为 RemoteData 的调用
/// 
/// 设计原则：
/// - 适配器模式：适配 IRemoteDataRepository 到 ICommunityDataSource
/// - 单一职责（SRP）：只负责远程数据访问
class RemoteCommunityDataSource implements ICommunityDataSource {
  final IRemoteDataRepository _remoteData;

  RemoteCommunityDataSource(this._remoteData);

  @override
  Future<bool> publishPost(CommunityPost post, {bool forceReplace = false}) async {
    return await _remoteData.saveCommunityPost(post, forceReplace: forceReplace);
  }

  @override
  Future<Map<String, String>> checkPublishStatus(List<EncounterRecord> records) async {
    return await _remoteData.checkPublishStatus(records);
  }

  @override
  Future<List<CommunityPost>> getPosts({
    int limit = 20,
    DateTime? lastTimestamp,
  }) async {
    return await _remoteData.getCommunityPosts(
      limit: limit,
      lastTimestamp: lastTimestamp,
    );
  }

  @override
  Future<List<CommunityPost>> getMyPosts(String userId) async {
    return await _remoteData.getMyCommunityPosts(userId);
  }

  @override
  Future<void> deletePost(String postId, String userId) async {
    await _remoteData.deleteCommunityPost(postId, userId);
  }

  @override
  Future<void> deletePostByRecordId(String recordId) async {
    await _remoteData.deleteCommunityPostByRecordId(recordId);
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
    return await _remoteData.filterCommunityPosts(
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
      tagMatchMode: tagMatchMode.value,
      limit: limit,
    );
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
    String tagMatchMode = 'contains',
    int limit = 20,
  }) async {
    return await _remoteData.filterCommunityPosts(
      startDate: startDate,
      endDate: endDate,
      publishStartDate: publishStartDate,
      publishEndDate: publishEndDate,
      province: province,
      city: city,
      area: area,
      placeTypes: placeTypes,
      tags: tags,
      tagMatchMode: tagMatchMode,
      limit: limit,
    );
  }
}

