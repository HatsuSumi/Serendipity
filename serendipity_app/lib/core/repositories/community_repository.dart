import '../../models/community_post.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../repositories/i_remote_data_repository.dart';
import '../config/app_config.dart';

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

  CommunityRepository(this._remoteData);

  /// 从 EncounterRecord 创建 CommunityPost
  /// 
  /// 隐私保护：
  /// - 不包含用户身份（完全匿名）
  /// - 不包含精确 GPS 坐标
  /// 
  /// Fail Fast:
  /// - 如果 record 为 null，抛出 ArgumentError
  /// - 如果 userId 为空，抛出 ArgumentError
  CommunityPost _createPostFromRecord(EncounterRecord record, String userId) {
    // Fail Fast: 参数验证
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }

    final now = DateTime.now();
    
    return CommunityPost(
      id: '${record.id}_${now.millisecondsSinceEpoch}', // 使用记录ID + 时间戳作为帖子ID
      userId: userId, // 后台记录，前台不显示
      recordId: record.id,
      timestamp: record.timestamp,
      address: record.location.address, // 标准地址（GPS获取）
      placeName: record.location.placeName, // 用户输入的地点名称
      placeType: record.location.placeType, // 场所类型
      cityName: _extractCityName(record.location.address), // 提取城市名称
      description: record.description ?? '',
      tags: record.tags,
      status: record.status,
      isAnonymous: true, // 始终匿名
      publishedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从地址中提取城市名称
  /// 
  /// 示例：
  /// - "北京市朝阳区建国门外大街1号" → "北京市"
  /// - "上海市浦东新区世纪大道1号" → "上海市"
  /// - null → null
  String? _extractCityName(String? address) {
    if (address == null || address.isEmpty) return null;

    // 简单提取：查找"市"字
    final cityIndex = address.indexOf('市');
    if (cityIndex != -1) {
      return address.substring(0, cityIndex + 1);
    }

    // 如果没有"市"，返回 null
    return null;
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
    if (AppConfig.enableTestMode) {
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
    if (AppConfig.enableTestMode) {
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
    if (AppConfig.enableTestMode) {
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
    if (AppConfig.enableTestMode) {
      return;
    }

    // 从云端删除
    await _remoteData.deleteCommunityPost(postId, userId);
  }

  /// 筛选帖子
  /// 
  /// 参数：
  /// - startDate: 开始日期（可选）
  /// - endDate: 结束日期（可选）
  /// - cityName: 城市名称（可选）
  /// - placeType: 场所类型（可选）
  /// - tag: 标签名称（可选）
  /// - status: 状态（可选）
  /// - limit: 每页数量（默认 20）
  /// 
  /// 返回：符合条件的帖子列表
  /// 
  /// 调用者：CommunityProvider.filterPosts()
  Future<List<CommunityPost>> filterPosts({
    DateTime? startDate,
    DateTime? endDate,
    String? cityName,
    PlaceType? placeType,
    String? tag,
    EncounterStatus? status,
    int limit = 20,
  }) async {
    // Fail Fast: 参数验证
    if (limit <= 0) {
      throw ArgumentError('limit must be positive');
    }
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw ArgumentError('startDate must be before endDate');
    }

    // 测试模式：返回空列表
    if (AppConfig.enableTestMode) {
      return [];
    }

    // 从云端筛选
    return await _remoteData.filterCommunityPosts(
      startDate: startDate,
      endDate: endDate,
      cityName: cityName,
      placeType: placeType?.value,
      tag: tag,
      status: status?.value,
      limit: limit,
    );
  }
}

