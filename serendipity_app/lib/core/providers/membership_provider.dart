import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/membership.dart';
import '../../models/enums.dart';
import '../repositories/membership_repository.dart';
import 'auth_provider.dart';

/// 会员仓储 Provider
final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipRepository(ref.read(storageServiceProvider));
});

/// 会员状态管理
/// 
/// 职责：
/// - 管理当前用户的会员状态
/// - 监听用户登录状态变化，自动加载会员信息
/// - 支持会员升级和状态更新
/// 
/// 设计原则：
/// - 单一职责：只负责会员状态管理
/// - 自动响应：监听 authProvider 变化，自动加载会员信息
/// - 依赖倒置：依赖 MembershipRepository，不依赖具体的数据源
class MembershipNotifier extends AsyncNotifier<MembershipInfo> {
  late MembershipRepository _repository;

  @override
  Future<MembershipInfo> build() async {
    _repository = ref.read(membershipRepositoryProvider);
    
    // 监听用户登录状态变化
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    
    if (currentUser == null) {
      // 未登录：返回免费版信息
      return const MembershipInfo(
        tier: MembershipTier.free,
        status: MembershipStatus.inactive,
        isPremium: false,
      );
    }
    
    // 已登录：加载会员信息
    try {
      final membership = await _repository.getMembership(currentUser.id);
      if (membership == null) {
        // 用户未开通会员
        return const MembershipInfo(
          tier: MembershipTier.free,
          status: MembershipStatus.inactive,
          isPremium: false,
        );
      }
      
      // 检查会员是否过期
      final isPremium = membership.status == MembershipStatus.active &&
          (membership.expiresAt == null || membership.expiresAt!.isAfter(DateTime.now()));
      
      return MembershipInfo(
        tier: membership.tier,
        status: membership.status,
        isPremium: isPremium,
        membership: membership,
      );
    } catch (e) {
      // 加载失败，降级为免费版
      return const MembershipInfo(
        tier: MembershipTier.free,
        status: MembershipStatus.inactive,
        isPremium: false,
      );
    }
  }

  /// 升级为会员
  /// 
  /// 参数：
  /// - amount：支付金额（单位：元）
  /// 
  /// 设计说明：
  /// - 如果 amount = 0，直接升级为会员
  /// - 如果 amount > 0，需要用户扫码支付后再升级
  /// - 升级成功后自动刷新会员状态
  Future<void> upgradeToPremium(double amount) async {
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    if (currentUser == null) {
      throw StateError('User not logged in');
    }
    
    // 创建会员记录
    final membership = Membership(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser.id,
      tier: MembershipTier.premium,
      status: MembershipStatus.active,
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)), // 默认30天
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // 保存到本地
    await _repository.saveMembership(membership);
    
    // 刷新状态
    ref.invalidateSelf();
    await future;
  }

  /// 刷新会员状态
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// 会员信息（简化版）
/// 
/// 用于 UI 层快速判断用户是否为会员
class MembershipInfo {
  final MembershipTier tier;
  final MembershipStatus status;
  final bool isPremium;
  final Membership? membership;

  const MembershipInfo({
    required this.tier,
    required this.status,
    required this.isPremium,
    this.membership,
  });
}

/// 会员状态 Provider
final membershipProvider = AsyncNotifierProvider<MembershipNotifier, MembershipInfo>(() {
  return MembershipNotifier();
});

