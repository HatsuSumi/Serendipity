import '../../models/membership.dart';
import '../../models/enums.dart';
import '../services/i_storage_service.dart';

/// 会员仓储
/// 
/// 职责：
/// - 管理会员数据的持久化和查询
/// - 支持会员信息的保存、更新、查询
/// 
/// 调用者：
/// - MembershipProvider：状态管理层
/// 
/// 设计原则：
/// - 单一职责：只负责会员数据的存取
/// - Fail Fast：参数校验，立即抛出异常
/// - 不涉及业务逻辑：只做数据操作
class MembershipRepository {
  final IStorageService _storageService;

  MembershipRepository(this._storageService);

  /// 获取用户的会员信息
  /// 
  /// 参数：
  /// - userId：用户ID
  /// 
  /// 返回：
  /// - Membership：会员信息，如果用户未开通会员返回 null
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出异常
  Future<Membership?> getMembership(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    
    return _storageService.getMembership(userId);
  }

  /// 保存会员信息
  /// 
  /// 参数：
  /// - membership：会员信息
  /// 
  /// 设计说明：
  /// - 如果会员已存在，覆盖旧数据
  /// - 自动更新 updatedAt 时间戳
  /// 
  /// Fail Fast：
  /// - membership 为 null：抛出异常
  /// - membership.userId 为空：抛出异常
  Future<void> saveMembership(Membership membership) async {
    if (membership.userId.isEmpty) {
      throw ArgumentError('membership.userId cannot be empty');
    }
    
    return _storageService.saveMembership(membership);
  }

  /// 更新会员信息
  /// 
  /// 参数：
  /// - membership：会员信息
  /// 
  /// 设计说明：
  /// - 只更新已存在的会员信息
  /// - 如果会员不存在，抛出异常
  /// - 自动更新 updatedAt 时间戳
  /// 
  /// Fail Fast：
  /// - membership 为 null：抛出异常
  /// - membership.userId 为空：抛出异常
  /// - 会员不存在：抛出异常
  Future<void> updateMembership(Membership membership) async {
    if (membership.userId.isEmpty) {
      throw ArgumentError('membership.userId cannot be empty');
    }
    
    final existing = await getMembership(membership.userId);
    if (existing == null) {
      throw StateError('Membership for user ${membership.userId} does not exist');
    }
    
    return _storageService.saveMembership(membership);
  }

  /// 删除会员信息
  /// 
  /// 参数：
  /// - userId：用户ID
  /// 
  /// 设计说明：
  /// - 删除用户的会员记录
  /// - 如果会员不存在，静默成功（幂等）
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出异常
  Future<void> deleteMembership(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    
    return _storageService.deleteMembership(userId);
  }

  /// 检查用户是否为活跃会员
  /// 
  /// 参数：
  /// - userId：用户ID
  /// 
  /// 返回：
  /// - true：用户是活跃会员（已开通且未过期）
  /// - false：用户不是活跃会员
  /// 
  /// 设计说明：
  /// - 检查会员状态是否为 active
  /// - 检查会员是否过期（expiresAt）
  /// - 如果会员不存在，返回 false
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出异常
  Future<bool> isActiveMember(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    
    final membership = await getMembership(userId);
    if (membership == null) {
      return false;
    }
    
    // 检查状态是否为 active
    if (membership.status != MembershipStatus.active) {
      return false;
    }
    
    // 检查是否过期
    if (membership.expiresAt != null && membership.expiresAt!.isBefore(DateTime.now())) {
      return false;
    }
    
    return true;
  }
}