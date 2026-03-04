import 'package:uuid/uuid.dart';
import '../../models/community_post.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../repositories/i_remote_data_repository.dart';
import '../config/app_config.dart';
import '../utils/address_helper.dart';

/// 社区仓储
/// 
/// 封装社区帖子相关的业务逻辑和数据访问
/// 
/// 职责：
/// - 发布记录到社区
/// - 获取社区帖子列表
/// - 删除自己的帖子
/// - 筛选帖子
/// 
/// 调用者：
/// - CommunityProvider（状态管理层）
class CommunityRepository {
  final IRemoteDataRepository _remoteData;
  final _uuid = const Uuid();

  CommunityRepository(this._remoteData);

  /// 从 EncounterRecord 创建 CommunityPost
  /// 
  /// 隐私保护：
  /// - 不包含用户身份（完全匿名）
  /// - 不包含精确 GPS 坐标
  /// 
  /// 注意：CommunityPost 模型不包含 userId 字段
  /// - 后端不返回 userId（隐私保护）
  /// - 使用 isOwner 字段判断是否可以删除
  /// 
  /// 调用者：publishPost()
  CommunityPost _createPostFromRecord(EncounterRecord record, String userId) {
    final now = DateTime.now();
    
    // 使用 AddressHelper 提取省市区信息
    final region = AddressHelper.extractRegion(record.location.address);
    
    return CommunityPost(
      id: _uuid.v5(Uuid.NAMESPACE_URL, '${record.id}_${now.millisecondsSinceEpoch}'), // 基于 recordId 和时间戳生成确定性 UUID
      recordId: record.id,
      timestamp: record.timestamp,
      address: record.location.address, // 标准地址（GPS获取）
      placeName: record.location.placeName, // 用户输入的地点名称
      placeType: record.location.placeType, // 场所类型
      province: region.province, // 省份
      city: region.city, // 城市
      area: region.area, // 区县
      description: record.description,
      tags: record.tags,
      status: record.status,
      isOwner: true, // 自己创建的帖子
      publishedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 发布记录到社区
  /// 
  /// Fail Fast:
  /// - 如果 record 为 null，抛出 ArgumentError
  /// - 如果 userId 为空，抛出 ArgumentError
  /// - 如果网络请求失败，抛出异常
  /// 
  /// 调用者：CommunityProvider.publishPost()
  Future<void> publishPost(EncounterRecord record, String userId) async {
    // Fail Fast: 参数验证
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }

    // 创建社区帖子
    final post = _createPostFromRecord(record, userId);

    // 测试模式：不上传到云端
    if (AppConfig.serverType == ServerType.test) {
      // 测试模式下，直接返回成功
      return;
    }

    // 上传到云端
    await _remoteData.saveCommunityPost(post);
  }

  /// 获取社区帖子列表（分页）
  /// 
  /// 参数：
  /// - limit: 每页数量（默认 20）
  /// - lastTimestamp: 上一页最后一条帖子的时间戳（用于分页）
  /// 
  /// 返回：按发布时间倒序排列的帖子列表
  /// 
  /// 调用者：CommunityProvider.loadPosts()
  Future<List<CommunityPost>> getPosts({
    int limit = 20,
    DateTime? lastTimestamp,
  }) async {
    // Fail Fast: 参数验证
    if (limit <= 0) {
      throw ArgumentError('limit must be positive');
    }

    // 测试模式：返回空列表
    if (AppConfig.serverType == ServerType.test) {
      return [];
    }

    // 从云端获取
    return await _remoteData.getCommunityPosts(
      limit: limit,
      lastTimestamp: lastTimestamp,
    );
  }

  /// 获取用户自己的帖子
  /// 
  /// Fail Fast:
  /// - 如果 userId 为空，抛出 ArgumentError
  /// 
  /// 调用者：CommunityProvider.getMyPosts()
  Future<List<CommunityPost>> getMyPosts(String userId) async {
    // Fail Fast: 参数验证
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }

    // 测试模式：返回空列表
    if (AppConfig.serverType == ServerType.test) {
      return [];
    }

    // 从云端获取
    return await _remoteData.getMyCommunityPosts(userId);
  }

  /// 删除帖子
  /// 
  /// Fail Fast:
  /// - 如果 postId 为空，抛出 ArgumentError
  /// - 如果帖子不存在，抛出 StateError
  /// - 如果不是帖子作者，抛出 StateError
  /// 
  /// 调用者：CommunityProvider.deletePost()
  Future<void> deletePost(String postId, String userId) async {
    // Fail Fast: 参数验证
    if (postId.isEmpty) {
      throw ArgumentError('postId cannot be empty');
    }
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }

    // 测试模式：直接返回成功
    if (AppConfig.serverType == ServerType.test) {
      return;
    }

    // 从云端删除
    await _remoteData.deleteCommunityPost(postId, userId);
  }

  /// 筛选帖子
  /// 
  /// 参数：
  /// - startDate: 错过时间开始日期（可选）
  /// - endDate: 错过时间结束日期（可选）
  /// - publishStartDate: 发布时间开始日期（可选）
  /// - publishEndDate: 发布时间结束日期（可选）
  /// - province: 省份（可选）
  /// - city: 城市（可选）
  /// - area: 区县（可选）
  /// - placeTypes: 场所类型列表（可选，多选OR逻辑）
  /// - tags: 标签名称列表（可选，多选OR逻辑）
  /// - statuses: 状态列表（可选，多选OR逻辑）
  /// - limit: 每页数量（默认 20）
  /// 
  /// 返回：符合条件的帖子列表
  /// 
  /// 调用者：CommunityProvider.filterPosts()
  Future<List<CommunityPost>> filterPosts({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? publishStartDate,
    DateTime? publishEndDate,
    String? province,
    String? city,
    String? area,
    List<PlaceType>? placeTypes,
    List<String>? tags,
    List<EncounterStatus>? statuses,
    int limit = 20,
  }) async {
    // Fail Fast: 参数验证
    if (limit <= 0) {
      throw ArgumentError('limit must be positive');
    }
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw ArgumentError('startDate must be before endDate');
    }
    if (publishStartDate != null && publishEndDate != null && publishStartDate.isAfter(publishEndDate)) {
      throw ArgumentError('publishStartDate must be before publishEndDate');
    }

    // 测试模式：返回空列表
    if (AppConfig.serverType == ServerType.test) {
      return [];
    }

    // 从云端筛选
    return await _remoteData.filterCommunityPosts(
      startDate: startDate,
      endDate: endDate,
      publishStartDate: publishStartDate,
      publishEndDate: publishEndDate,
      province: province,
      city: city,
      area: area,
      placeTypes: placeTypes?.map((t) => t.value).toList(),
      tags: tags,
      statuses: statuses?.map((s) => s.name).toList(),
      limit: limit,
    );
  }
}

