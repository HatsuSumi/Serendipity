import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/check_in_record.dart';
import '../../models/achievement_unlock.dart';
import '../repositories/check_in_repository.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';
import 'achievement_provider.dart';

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
class CheckInNotifier extends StateNotifier<CheckInState> {
  final CheckInRepository _repository;
  final Ref _ref;

  CheckInNotifier(this._repository, this._ref) : super(_initialState(_repository));

  static CheckInState _initialState(CheckInRepository repository) {
    return CheckInState(
      hasCheckedInToday: repository.hasCheckedInToday(),
      consecutiveDays: repository.calculateConsecutiveDays(),
      totalDays: repository.getTotalCheckInDays(),
      currentMonthDays: repository.getCurrentMonthCheckInDays(),
      recentCheckIns: repository.getCheckInsSortedByDate().take(7).toList(),
    );
  }

  /// 签到
  /// 
  /// 调用者：UI 层（CheckInButton、CheckInCard 等）
  Future<void> checkIn() async {
    if (state.hasCheckedInToday) {
      throw StateError('Already checked in today');
    }

    // 获取当前用户（可选）
    final authState = _ref.read(authProvider);
    final currentUser = authState.value;
    
    // 签到（传入 userId，未登录时为 null）
    final checkIn = await _repository.checkIn(userId: currentUser?.id);
    _refresh();
    
    // 检测成就
    try {
      final detector = _ref.read(achievementDetectorProvider);
      final unlockedAchievements = await detector.checkCheckInAchievements();
      if (unlockedAchievements.isNotEmpty) {
        // 通知UI层显示成就解锁通知
        _ref.read(newlyUnlockedAchievementsProvider.notifier).add(unlockedAchievements);
        // 刷新成就列表
        _ref.invalidate(achievementsProvider);
        
        // 上传成就解锁记录到云端
        await _uploadAchievementUnlocks(unlockedAchievements);
      }
    } catch (e) {
      // 成就检测失败不影响签到
      // 但需要记录错误日志（生产环境）
    }
    
    // 如果用户已登录，上传到云端
    if (currentUser != null) {
      try {
        final syncService = _ref.read(syncServiceProvider);
        await syncService.uploadCheckIn(currentUser, checkIn);
      } catch (e) {
        // 云端同步失败不影响本地签到
        // 用户可以稍后手动触发全量同步
      }
    }
  }

  /// 刷新状态
  void _refresh() {
    state = CheckInState(
      hasCheckedInToday: _repository.hasCheckedInToday(),
      consecutiveDays: _repository.calculateConsecutiveDays(),
      totalDays: _repository.getTotalCheckInDays(),
      currentMonthDays: _repository.getCurrentMonthCheckInDays(),
      recentCheckIns: _repository.getCheckInsSortedByDate().take(7).toList(),
    );
  }

  /// 获取指定月份的签到日期
  List<DateTime> getCheckInDatesInMonth(int year, int month) {
    return _repository.getCheckInDatesInMonth(year, month);
  }

  /// 重置所有签到记录（开发者功能）
  Future<void> resetAllCheckIns() async {
    await _repository.resetAllCheckIns();
    _refresh();
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
    // 获取当前用户
    final authState = _ref.read(authProvider);
    final currentUser = authState.value;
    if (currentUser == null) {
      // 用户未登录，跳过上传
      return;
    }
    
    // 获取成就仓储
    final achievementRepo = _ref.read(achievementRepositoryProvider);
    
    // 获取同步服务
    final syncService = _ref.read(syncServiceProvider);
    
    // 遍历每个成就ID，上传解锁记录
    for (final achievementId in achievementIds) {
      try {
        // 获取成就详情（包含解锁时间）
        final achievement = await achievementRepo.getAchievement(achievementId);
        if (achievement == null || !achievement.unlocked || achievement.unlockedAt == null) {
          // 成就不存在或未解锁，跳过
          continue;
        }
        
        // 创建成就解锁记录
        final unlock = AchievementUnlock(
          userId: currentUser.id,
          achievementId: achievementId,
          unlockedAt: achievement.unlockedAt!,
        );
        
        // 上传到云端
        await syncService.uploadAchievementUnlock(unlock);
      } catch (e) {
        // 单个成就上传失败不影响其他成就
        // 用户可以稍后通过全量同步补齐
        // 生产环境应记录错误日志
      }
    }
  }
}

/// 签到状态 Provider
final checkInProvider = StateNotifierProvider<CheckInNotifier, CheckInState>((ref) {
  final repository = ref.read(checkInRepositoryProvider);
  return CheckInNotifier(repository, ref);
});

