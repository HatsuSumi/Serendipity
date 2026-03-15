import '../../../models/encounter_record.dart';
import '../../../models/enums.dart';
import '../../repositories/record_repository.dart';
import '../../utils/geo_helper.dart';
import '../../utils/address_helper.dart';
import '../../utils/holiday_helper.dart';
import 'base_achievement_checker.dart';

/// 记录成就检测器
/// 
/// 负责检测与记录相关的成就：
/// - 记录数量成就（第一次错过、记录10次、50次、100次）
/// - 状态成就（再遇、邂逅、重逢、失联、别离）
/// - 时间成就（深夜、清晨）
/// - 天气成就（雨天）
/// - 地点成就（同一地点、地铁、咖啡馆、城市）
/// - 节日成就
/// - 成功率成就
/// 
/// 调用者：
/// - AchievementDetector：协调器
/// 
/// 设计原则：
/// - 单一职责：只负责记录相关成就检测
/// - 依赖注入：通过构造函数注入依赖
/// - DRY：继承基类的通用进度检测逻辑
class RecordAchievementChecker extends BaseAchievementChecker {
  final RecordRepository _recordRepository;

  RecordAchievementChecker(
    super.achievementRepository,
    this._recordRepository,
  );

  /// 检测记录相关成就
  /// 
  /// 参数：
  /// - record: 当前创建或更新的记录
  /// - userId: 当前用户ID（用于数据隔离）
  /// 
  /// 返回：新解锁的成就ID列表
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  Future<List<String>> check(EncounterRecord record, String userId) async {
    // Fail Fast：参数验证
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    final unlockedAchievements = <String>[];

    // 获取当前用户的所有记录（数据隔离）
    final allRecords = _recordRepository.getRecordsByUser(userId);

    // 检测记录数量成就
    unlockedAchievements.addAll(
      await _checkRecordCountAchievements(allRecords),
    );

    // 检测状态成就
    unlockedAchievements.addAll(
      await _checkStatusAchievements(record),
    );

    // 检测时间成就
    unlockedAchievements.addAll(
      await _checkTimeAchievements(record),
    );

    // 检测天气成就
    unlockedAchievements.addAll(
      await _checkWeatherAchievements(record),
    );

    // 检测地点成就
    unlockedAchievements.addAll(
      await _checkLocationAchievements(record, allRecords),
    );

    // 检测节日成就
    unlockedAchievements.addAll(
      await _checkHolidayAchievements(record),
    );

    // 检测成功率成就
    unlockedAchievements.addAll(
      await _checkSuccessRateAchievements(allRecords),
    );

    return unlockedAchievements;
  }

  /// 检测记录数量成就
  /// 
  /// 使用通用方法检测多个记录数量成就，消除重复代码
  Future<List<String>> _checkRecordCountAchievements(
    List<EncounterRecord> allRecords,
  ) async {
    final unlockedAchievements = <String>[];
    final recordCount = allRecords.length;

    // 检测：第一次错过（无进度条的成就）
    if (recordCount >= 1) {
      final justUnlocked = await achievementRepository.unlockAchievement('first_missed');
      if (justUnlocked) {
        unlockedAchievements.add('first_missed');
      }
    }

    // 检测：记录数量进度成就（有进度条的成就）
    unlockedAchievements.addAll(
      await checkProgressAchievements(
        recordCount,
        [
          'record_10',
          'record_50',
          'record_100',
        ],
      ),
    );

    return unlockedAchievements;
  }

  /// 检测状态成就
  /// 
  /// 使用通用方法检测多个状态成就，消除重复代码
  Future<List<String>> _checkStatusAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    // 状态到成就ID的映射
    const statusAchievementMap = {
      EncounterStatus.reencounter: 'first_reencounter',
      EncounterStatus.met: 'first_met',
      EncounterStatus.reunion: 'first_reunion',
      EncounterStatus.lost: 'first_lost',
      EncounterStatus.farewell: 'first_farewell',
    };

    // 检测当前状态对应的成就
    final achievementId = statusAchievementMap[record.status];
    if (achievementId != null) {
      final justUnlocked = await achievementRepository.unlockAchievement(achievementId);
      if (justUnlocked) {
        unlockedAchievements.add(achievementId);
      }
    }

    return unlockedAchievements;
  }

  /// 检测时间成就
  /// 
  /// 使用通用方法检测时间相关成就，消除重复代码
  Future<List<String>> _checkTimeAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    // 检测：深夜的错过（22:00后）
    if (record.timestamp.hour >= 22) {
      final justUnlocked = await achievementRepository.unlockAchievement('late_night');
      if (justUnlocked) {
        unlockedAchievements.add('late_night');
      }
    }

    // 检测：清晨的错过（7:00前）
    if (record.timestamp.hour < 7) {
      final justUnlocked = await achievementRepository.unlockAchievement('early_morning');
      if (justUnlocked) {
        unlockedAchievements.add('early_morning');
      }
    }

    return unlockedAchievements;
  }

  /// 检测天气成就
  /// 
  /// 使用通用方法检测天气相关成就，消除重复代码
  Future<List<String>> _checkWeatherAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    // 检测：雨天的错过
    if (record.weather.any((w) =>
        w == Weather.drizzle ||
        w == Weather.lightRain ||
        w == Weather.moderateRain ||
        w == Weather.heavyRain ||
        w == Weather.rainstorm)) {
      final justUnlocked = await achievementRepository.unlockAchievement('rainy_day');
      if (justUnlocked) {
        unlockedAchievements.add('rainy_day');
      }
    }

    return unlockedAchievements;
  }

  /// 检测地点成就
  /// 
  /// 使用通用方法检测地点相关成就，消除重复代码
  Future<List<String>> _checkLocationAchievements(
    EncounterRecord record,
    List<EncounterRecord> allRecords,
  ) async {
    final unlockedAchievements = <String>[];

    // 检测：在同一地点错过5次
    if (record.location.latitude != null && record.location.longitude != null) {
      final sameLocationCount = GeoHelper.countRecordsAtSameLocation(
        allRecords,
        record.location.latitude!,
        record.location.longitude!,
      );
      final justUnlocked = await achievementRepository.updateProgress(
        'same_place_5',
        sameLocationCount,
      );
      if (justUnlocked) {
        unlockedAchievements.add('same_place_5');
      }
    }

    // 检测：地铁常客
    final subwayCount = allRecords.where((r) => r.location.placeType == PlaceType.subway).length;
    final subwayUnlocked = await achievementRepository.updateProgress(
      'subway_regular',
      subwayCount,
    );
    if (subwayUnlocked) {
      unlockedAchievements.add('subway_regular');
    }

    // 检测：咖啡馆邂逅
    final coffeeShopMetCount = allRecords.where((r) =>
        r.location.placeType == PlaceType.coffeeShop && r.status == EncounterStatus.met).length;
    final coffeeUnlocked = await achievementRepository.updateProgress(
      'coffee_shop_met',
      coffeeShopMetCount,
    );
    if (coffeeUnlocked) {
      unlockedAchievements.add('coffee_shop_met');
    }

    // 检测：城市漫游者
    final cityCount = AddressHelper.countUniqueCities(allRecords);
    final cityUnlocked = await achievementRepository.updateProgress(
      'city_wanderer',
      cityCount,
    );
    if (cityUnlocked) {
      unlockedAchievements.add('city_wanderer');
    }

    return unlockedAchievements;
  }

  /// 检测节日成就
  /// 
  /// 使用通用方法检测节日相关成就，消除重复代码
  Future<List<String>> _checkHolidayAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    // 检测：节日的错过
    if (HolidayHelper.isHoliday(record.timestamp)) {
      final justUnlocked = await achievementRepository.unlockAchievement('holiday_missed');
      if (justUnlocked) {
        unlockedAchievements.add('holiday_missed');
      }
    }

    return unlockedAchievements;
  }

  /// 检测成功率成就
  /// 
  /// 使用通用方法检测成功率相关成就，消除重复代码
  Future<List<String>> _checkSuccessRateAchievements(
    List<EncounterRecord> allRecords,
  ) async {
    final unlockedAchievements = <String>[];

    // 检测：成功率达到10%
    final successRate = _calculateSuccessRate(allRecords);
    if (successRate >= 10.0) {
      final justUnlocked = await achievementRepository.unlockAchievement('success_rate_10');
      if (justUnlocked) {
        unlockedAchievements.add('success_rate_10');
      }
    }

    return unlockedAchievements;
  }

  /// 计算成功率（邂逅/重逢的记录占比）
  double _calculateSuccessRate(List<EncounterRecord> records) {
    if (records.isEmpty) return 0.0;

    final successCount = records.where((r) =>
        r.status == EncounterStatus.met || r.status == EncounterStatus.reunion).length;

    return (successCount / records.length * 100).clamp(0.0, 100.0);
  }
}

