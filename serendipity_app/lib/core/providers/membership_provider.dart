import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/membership.dart';
import '../../models/enums.dart';
import '../config/app_config.dart';
import '../repositories/membership_repository.dart';
import 'auth_provider.dart';

const int freeStoryLineLimit = 3;
const Duration membershipDuration = Duration(days: 30);

/// 会员仓储 Provider
final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipRepository(ref.read(storageServiceProvider));
});

MembershipInfo _buildFreeMembershipInfo() {
  return const MembershipInfo(
    tier: MembershipTier.free,
    status: MembershipStatus.inactive,
    isPremium: false,
  );
}

bool _isMembershipActive(Membership membership, DateTime now) {
  return membership.status == MembershipStatus.active &&
      (membership.expiresAt == null || membership.expiresAt!.isAfter(now));
}

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

    final currentUser = await ref.read(authProvider.future);
    if (currentUser == null) {
      return _buildFreeMembershipInfo();
    }

    try {
      final membership = await _repository.getMembership(currentUser.id);
      if (membership == null) {
        return _buildFreeMembershipInfo();
      }

      final now = DateTime.now();
      final isPremium = _isMembershipActive(membership, now);
      final effectiveStatus = isPremium
          ? membership.status
          : membership.expiresAt != null && membership.expiresAt!.isBefore(now)
          ? MembershipStatus.expired
          : membership.status;

      return MembershipInfo(
        tier: isPremium ? membership.tier : MembershipTier.free,
        status: effectiveStatus,
        isPremium: isPremium,
        membership: membership,
      );
    } catch (_) {
      return _buildFreeMembershipInfo();
    }
  }

  /// 升级为会员
  ///
  /// 参数：
  /// - amount：支付金额（单位：元）
  Future<void> upgradeToPremium(double amount) async {
    if (amount < 0 || amount > 648) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Amount must be between 0 and 648',
      );
    }

    final currentUser = await ref.read(authProvider.future);
    if (currentUser == null) {
      throw StateError('User not logged in');
    }

    final existingMembership = await _repository.getMembership(currentUser.id);
    if (existingMembership != null &&
        _isMembershipActive(existingMembership, DateTime.now())) {
      throw StateError('Membership is still active');
    }

    final now = DateTime.now();
    final membership = Membership(
      id: existingMembership?.id ?? now.millisecondsSinceEpoch.toString(),
      userId: currentUser.id,
      tier: MembershipTier.premium,
      status: MembershipStatus.active,
      startedAt: now,
      expiresAt: now.add(membershipDuration),
      createdAt: existingMembership?.createdAt ?? now,
      updatedAt: now,
    );

    await _repository.saveMembership(membership);

    ref.invalidateSelf();
    await future;
  }

  /// 刷新会员状态
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// 重置会员状态（开发测试用）
  ///
  /// 删除当前用户的会员记录，恢复为免费版
  Future<void> resetMembership() async {
    final currentUser = await ref.read(authProvider.future);
    if (currentUser == null) {
      throw StateError('User not logged in');
    }

    await _repository.deleteMembership(currentUser.id);

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

  bool get canManageMultipleDevices => isPremium || AppConfig.isDeveloperMode;

  bool get canUseAdvancedStatistics => isPremium || AppConfig.isDeveloperMode;

  bool get canUseAnniversaryReminder => isPremium || AppConfig.isDeveloperMode;

  bool get canExportStoryLineCard => isPremium || AppConfig.isDeveloperMode;

  bool canUseTheme(ThemeOption theme) {
    return !theme.isPremium || isPremium || AppConfig.isDeveloperMode;
  }

  int? get maxStoryLines {
    if (isPremium || AppConfig.isDeveloperMode) {
      return null;
    }
    return freeStoryLineLimit;
  }
}

/// 会员状态 Provider
final membershipProvider =
    AsyncNotifierProvider<MembershipNotifier, MembershipInfo>(() {
      return MembershipNotifier();
    });
