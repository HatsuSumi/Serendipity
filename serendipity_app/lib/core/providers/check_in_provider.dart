import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/check_in_record.dart';
import '../../models/achievement_unlock.dart';
import '../repositories/check_in_repository.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';
import 'achievement_provider.dart';
import 'records_provider.dart';

/// 签到仓储 Provider
final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.read(storageServiceProvider));
});

/// 签到状态
class CheckInState {
  final bool hasCheckedInToday;
  final int consecutiveDays;
  final int totalDays;
  final int currentMonthDays;
  final List<CheckInRecord> recentCheckIns;

  CheckInState({
    required this.hasCheckedInToday,
    required this.consecutiveDays,
    required this.totalDays,
    required this.currentMonthDays,
    required this.recentCheckIns,
  });

  CheckInState copyWith({
    bool? hasCheckedInToday,
    int? consecutiveDays,
    int? totalDays,
    int? currentMonthDays,
    List<CheckInRecord>? recentCheckIns,
  }) {
    return CheckInState(
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      totalDays: totalDays ?? this.totalDays,
      currentMonthDays: currentMonthDays ?? this.currentMonthDays,
      recentCheckIns: recentCheckIns ?? this.recentCheckIns,
    );
  }
}

/// 签到状态管理
class CheckInNotifier extends AsyncNotifier<CheckInState> {
  late CheckInRepository _repository;

  @override
  Future<CheckInState> build() async {
    _repository = ref.read(checkInRepositoryProvider);
    
    // 监听自动同步完成信号，与 recordsProvider 保持一致
    // 同步完成后自动重建，以新 userId 加载数据
    ref.watch(syncCompletedProvider);
    
    // 获取当前登录用户
    final currentUser = await ref.read(authProvider.notifier).currentUser;
    final userId = currentUser?.id;
    
    return CheckInState(
      hasCheckedInToday: _repository.hasCheckedInToday(userId: userId),
      consecutiveDays: _repository.calculateConsecutiveDays(userId: userId),
      totalDays: _repository.getTotalCheckInDays(userId: userId),
      currentMonthDays: _repository.getCurrentMonthCheckInDays(userId: userId),
      recentCheckIns: _repository
          .getCheckInsSortedByDate(userId: userId)
          .take(7)
          .toList(),
    );
  }

  /// 刷新签到状态
  /// 
  /// 调用者：
  /// - checkIn() 签到后
  /// - resetAllCheckIns() 重置后
  /// - 用户切换时（通过 syncCompletedProvider 信号自动触发）
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentUser = await ref.read(authProvider.notifier).currentUser;
      final userId = currentUser?.id;
      
      return CheckInState(
        hasCheckedInToday: _repository.hasCheckedInToday(userId: userId),
        consecutiveDays: _repository.calculateConsecutiveDays(userId: userId),
        totalDays: _repository.getTotalCheckInDays(userId: userId),
        currentMonthDays: _repository.getCurrentMonthCheckInDays(userId: userId),
        recentCheckIns: _repository
            .getCheckInsSortedByDate(userId: userId)
            .take(7)
            .toList(),
      );
    });
  }

  /// 签到
  /// 
  /// 调用者：UI 层（CheckInButton、CheckInCard 等）
  Future<void> checkIn() async {
    // 获取当前用户
    final authState = ref.read(authProvider);
    final currentUser = authState.value;

    // 检查是否已签到
    final currentState = state.value;
    if (currentState?.hasCheckedInToday ?? false) {
      throw StateError('Already checked in today');
    }
    
    // 签到（传入 userId，未登录时为 null）
    final checkIn = await _repository.checkIn(userId: currentUser?.id);
    
    // 检测成就
    try {
      final detector = ref.read(achievementDetectorProvider);
      // 如果用户已登录，检测成就
      if (currentUser != null) {
        final unlockedAchievements = await detector.checkCheckInAchievements(currentUser.id);
        if (unlockedAchievements.isNotEmpty) {
          // 通知UI层显示成就解锁通知
          ref
              .read(newlyUnlockedAchievementsProvider.notifier)
              .add(unlockedAchievements);
          // 刷新成就列表
          ref.invalidate(achievementsProvider);
          
          // 上传成就解锁记录到云端
          await _uploadAchievementUnlocks(unlockedAchievements);
        }
      }
    } catch (e) {
      // 成就检测失败不影响签到
    }
    
    // 如果用户已登录，上传到云端
    if (currentUser != null) {
      try {
        final syncService = ref.read(syncServiceProvider);
        await syncService.uploadCheckIn(currentUser, checkIn);
      } catch (e) {
        // 云端同步失败不影响本地签到
        // 用户可以稍后手动触发全量同步
      }
    }
    
    // 刷新签到状态
    await refresh();
  }

  /// 获取指定月份的签到日期
  List<DateTime> getCheckInDatesInMonth(int year, int month) {
    final userId = ref.read(authProvider).value?.id;
    return _repository.getCheckInDatesInMonth(year, month, userId: userId);
  }

  /// 重置所有签到记录（开发者功能）
  Future<void> resetAllCheckIns() async {
    final userId = ref.read(authProvider).value?.id;
    await _repository.resetAllCheckIns(userId: userId);
    await refresh();
  }
  
  /// 上传成就解锁记录到云端
  /// 
  /// 调用者：checkIn()
  /// 
  /// 设计原则：
  /// - 单一职责：只负责上传成就解锁记录
  /// - Fail Fast：用户未登录时直接返回，不抛异常
  /// - 容错处理：上传失败不影响成就解锁（已保存到本地）
  Future<void> _uploadAchievementUnlocks(List<String> achievementIds) async {
    final authState = ref.read(authProvider);
    final currentUser = authState.value;
    if (currentUser == null) return;
    
    final achievementRepo = ref.read(achievementRepositoryProvider);
    final syncService = ref.read(syncServiceProvider);
    
    for (final achievementId in achievementIds) {
      try {
        final achievement = await achievementRepo.getAchievement(achievementId);
        if (achievement == null ||
            !achievement.unlocked ||
            achievement.unlockedAt == null) {
          continue;
        }
        
        final unlock = AchievementUnlock(
          userId: currentUser.id,
          achievementId: achievementId,
          unlockedAt: achievement.unlockedAt!,
        );
        
        await syncService.uploadAchievementUnlock(unlock);
      } catch (e) {
        // 单个成就上传失败不影响其他成就
      }
    }
  }
}

/// 签到状态 Provider
final checkInProvider =
    AsyncNotifierProvider<CheckInNotifier, CheckInState>(() {
  return CheckInNotifier();
});
