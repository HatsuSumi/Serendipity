import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/achievement_unlock.dart';
import '../../models/check_in_record.dart';
import '../../models/remote_check_in_status.dart';
import '../../models/user.dart';
import '../repositories/check_in_repository.dart';
import '../services/sync_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'records_provider.dart';
import 'user_settings_provider.dart';

/// 签到仓储 Provider
final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.read(storageServiceProvider));
});

/// 签到状态
class CheckInState {
  final bool hasCheckedInToday;
  final int consecutiveDays;
  final int displayConsecutiveDays;
  final int totalDays;
  final int currentMonthDays;
  final List<CheckInRecord> recentCheckIns;
  final bool isRemoteAuthoritative;
  final List<DateTime> checkedInDatesInCurrentMonth;
  final DateTime currentCalendarMonth;

  CheckInState({
    required this.hasCheckedInToday,
    required this.consecutiveDays,
    required this.displayConsecutiveDays,
    required this.totalDays,
    required this.currentMonthDays,
    required this.recentCheckIns,
    required this.isRemoteAuthoritative,
    required this.checkedInDatesInCurrentMonth,
    required this.currentCalendarMonth,
  });

  CheckInState copyWith({
    bool? hasCheckedInToday,
    int? consecutiveDays,
    int? displayConsecutiveDays,
    int? totalDays,
    int? currentMonthDays,
    List<CheckInRecord>? recentCheckIns,
    bool? isRemoteAuthoritative,
    List<DateTime>? checkedInDatesInCurrentMonth,
    DateTime? currentCalendarMonth,
  }) {
    return CheckInState(
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      displayConsecutiveDays:
          displayConsecutiveDays ?? this.displayConsecutiveDays,
      totalDays: totalDays ?? this.totalDays,
      currentMonthDays: currentMonthDays ?? this.currentMonthDays,
      recentCheckIns: recentCheckIns ?? this.recentCheckIns,
      isRemoteAuthoritative:
          isRemoteAuthoritative ?? this.isRemoteAuthoritative,
      checkedInDatesInCurrentMonth:
          checkedInDatesInCurrentMonth ?? this.checkedInDatesInCurrentMonth,
      currentCalendarMonth: currentCalendarMonth ?? this.currentCalendarMonth,
    );
  }
}

/// 签到状态管理
class CheckInNotifier extends AsyncNotifier<CheckInState> {
  late CheckInRepository _repository;

  @override
  Future<CheckInState> build() async {
    _repository = ref.read(checkInRepositoryProvider);

    ref.watch(syncCompletedProvider);

    final currentUser = await ref.read(authProvider.notifier).currentUser;
    return _loadState(currentUser, DateTime.now());
  }

  Future<CheckInState> _loadState(User? currentUser, DateTime month) async {
    final userId = currentUser?.id;
    final targetMonth = DateTime(month.year, month.month);

    if (currentUser != null) {
      final remoteStatus = await _loadRemoteStatus(currentUser, targetMonth);
      if (remoteStatus != null) {
        return _buildStateFromRemoteStatus(remoteStatus, targetMonth);
      }

      final cachedRemoteStatus = _repository.getRemoteStatusCache(
        userId: currentUser.id,
        month: targetMonth,
      );
      if (cachedRemoteStatus != null) {
        return _buildStateFromRemoteStatus(cachedRemoteStatus, targetMonth);
      }
    }

    return CheckInState(
      hasCheckedInToday: _repository.hasCheckedInToday(userId: userId),
      consecutiveDays: _repository.calculateConsecutiveDays(userId: userId),
      displayConsecutiveDays:
          _repository.calculateReminderStreakDays(userId: userId),
      totalDays: _repository.getTotalCheckInDays(userId: userId),
      currentMonthDays: _repository.getCurrentMonthCheckInDays(userId: userId),
      recentCheckIns: _repository
          .getCheckInsSortedByDate(userId: userId)
          .take(7)
          .toList(),
      isRemoteAuthoritative: false,
      checkedInDatesInCurrentMonth: _repository.getCheckInDatesInMonth(
        targetMonth.year,
        targetMonth.month,
        userId: userId,
      ),
      currentCalendarMonth: targetMonth,
    );
  }

  Future<RemoteCheckInStatus?> _loadRemoteStatus(
    User currentUser,
    DateTime targetMonth,
  ) async {
    try {
      final syncService = ref.read(syncServiceProvider);
      final status = await syncService.getCheckInStatus(
        currentUser,
        targetMonth.year,
        targetMonth.month,
      );

      for (final checkIn in status.recentCheckIns) {
        await _repository.saveRemoteCheckIn(checkIn);
      }
      await _repository.saveRemoteStatusCache(
        userId: currentUser.id,
        month: targetMonth,
        status: status,
      );

      return status;
    } catch (_) {
      return null;
    }
  }

  CheckInState _buildStateFromRemoteStatus(
    RemoteCheckInStatus remoteStatus,
    DateTime targetMonth,
  ) {
    final displayConsecutiveDays = remoteStatus.displayConsecutiveDays > 0
        ? remoteStatus.displayConsecutiveDays
        : _calculateDisplayConsecutiveDaysFromRecentCheckIns(
            remoteStatus.recentCheckIns,
          );

    return CheckInState(
      hasCheckedInToday: remoteStatus.hasCheckedInToday,
      consecutiveDays: remoteStatus.consecutiveDays,
      displayConsecutiveDays: displayConsecutiveDays,
      totalDays: remoteStatus.totalDays,
      currentMonthDays: remoteStatus.currentMonthDays,
      recentCheckIns: remoteStatus.recentCheckIns,
      isRemoteAuthoritative: true,
      checkedInDatesInCurrentMonth: remoteStatus.checkedInDatesInMonth,
      currentCalendarMonth: targetMonth,
    );
  }

  int _calculateDisplayConsecutiveDaysFromRecentCheckIns(
    List<CheckInRecord> recentCheckIns,
  ) {
    if (recentCheckIns.isEmpty) {
      return 0;
    }

    final normalizedDates = recentCheckIns
        .map((record) => DateTime(record.date.year, record.date.month, record.date.day))
        .toSet();
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    DateTime? streakEndDate;
    if (normalizedDates.contains(todayDate)) {
      streakEndDate = todayDate;
    } else if (normalizedDates.contains(yesterdayDate)) {
      streakEndDate = yesterdayDate;
    } else {
      return 0;
    }

    var streakDays = 1;
    var currentDate = streakEndDate;
    while (true) {
      final previousDate = currentDate.subtract(const Duration(days: 1));
      if (!normalizedDates.contains(previousDate)) {
        break;
      }
      streakDays++;
      currentDate = previousDate;
    }

    return streakDays;
  }

  /// 刷新签到状态
  Future<void> refresh({DateTime? month}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentUser = await ref.read(authProvider.notifier).currentUser;
      return _loadState(currentUser, month ?? DateTime.now());
    });
  }

  /// 签到（登录用户走服务端权威，未登录用户走本地）
  Future<void> checkIn() async {
    final authState = ref.read(authProvider);
    final currentUser = authState.value;
    final currentState = state.value;

    if (currentState?.hasCheckedInToday ?? false) {
      throw StateError('Already checked in today');
    }

    late final CheckInRecord checkIn;
    if (currentUser == null) {
      checkIn = await _repository.checkIn();
    } else {
      final syncService = ref.read(syncServiceProvider);
      checkIn = await syncService.createTodayCheckIn(currentUser);
      await _repository.saveRemoteCheckIn(checkIn);
    }

    try {
      final detector = ref.read(achievementDetectorProvider);
      if (currentUser != null) {
        final unlockedAchievements =
            await detector.checkCheckInAchievements(currentUser.id);
        if (unlockedAchievements.isNotEmpty) {
          ref
              .read(newlyUnlockedAchievementsProvider.notifier)
              .add(unlockedAchievements);
          ref.invalidate(achievementsProvider);
          await _uploadAchievementUnlocks(unlockedAchievements);
        }
      }
    } catch (_) {}

    await refresh();
    await ref.read(notificationServiceProvider).cancelCheckInReminder();
  }

  /// 获取指定月份的签到日期
  List<DateTime> getCheckInDatesInMonth(int year, int month) {
    final current = state.value;
    if (current != null &&
        current.currentCalendarMonth.year == year &&
        current.currentCalendarMonth.month == month) {
      return current.checkedInDatesInCurrentMonth;
    }

    final userId = ref.read(authProvider).value?.id;
    return _repository.getCheckInDatesInMonth(year, month, userId: userId);
  }

  /// 重置所有签到记录（开发者功能）
  Future<void> resetAllCheckIns() async {
    final userId = ref.read(authProvider).value?.id;
    await _repository.resetAllCheckIns(userId: userId);
    await refresh();
  }

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
      } catch (_) {
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
