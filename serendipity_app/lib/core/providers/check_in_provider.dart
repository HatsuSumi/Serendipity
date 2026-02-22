import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/check_in_record.dart';
import '../repositories/check_in_repository.dart';
import '../services/i_storage_service.dart';
import '../services/storage_service.dart';

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

  CheckInNotifier(this._repository) : super(_initialState(_repository));

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
  Future<void> checkIn() async {
    if (state.hasCheckedInToday) {
      throw StateError('Already checked in today');
    }

    await _repository.checkIn();
    _refresh();
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
}

/// 签到状态 Provider
final checkInProvider = StateNotifierProvider<CheckInNotifier, CheckInState>((ref) {
  final repository = ref.read(checkInRepositoryProvider);
  return CheckInNotifier(repository);
});

/// 存储服务 Provider（如果还没有定义）
final storageServiceProvider = Provider<IStorageService>((ref) {
  return StorageService();
});

