import '../../../models/encounter_record.dart';
import '../../../models/enums.dart';
import '../../repositories/achievement_repository.dart';
import '../../repositories/record_repository.dart';
import '../../utils/geo_helper.dart';
import '../../utils/address_helper.dart';
import '../../utils/holiday_helper.dart';

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
class RecordAchievementChecker {
  final AchievementRepository _achievementRepository;
  final RecordRepository _recordRepository;

  RecordAchievementChecker(
    this._achievementRepository,
    this._recordRepository,
  );

  /// 检测记录相关成就
  /// 
  /// 参数：
  /// - record: 当前创建或更新的记录
  /// 
  /// 返回：新解锁的成就ID列表
  Future<List<String>> check(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    // 获取所有记录
    final allRecords = _recordRepository.getAllRecords();

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
  Future<List<String>> _checkRecordCountAchievements(
    List<EncounterRecord> allRecords,
  ) async {
    final unlockedAchievements = <String>[];
    final recordCount = allRecords.length;

    // 检测：第一次错过
    if (recordCount >= 1) {
      final achievement = await _achievementRepository.getAchievement('first_missed');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('first_missed');
        unlockedAchievements.add('first_missed');
      }
    }

    // 检测：记录10次错过
    if (recordCount >= 10) {
      await _achievementRepository.updateProgress('record_10', recordCount);
      final achievement = await _achievementRepository.getAchievement('record_10');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('record_10')) {
        unlockedAchievements.add('record_10');
      }
    } else {
      await _achievementRepository.updateProgress('record_10', recordCount);
    }

    // 检测：错过50个人
    if (recordCount >= 50) {
      await _achievementRepository.updateProgress('record_50', recordCount);
      final achievement = await _achievementRepository.getAchievement('record_50');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('record_50')) {
        unlockedAchievements.add('record_50');
      }
    } else if (recordCount >= 10) {
      await _achievementRepository.updateProgress('record_50', recordCount);
    }

    // 检测：错过100个人
    if (recordCount >= 100) {
      await _achievementRepository.updateProgress('record_100', recordCount);
      final achievement = await _achievementRepository.getAchievement('record_100');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('record_100')) {
        unlockedAchievements.add('record_100');
      }
    } else if (recordCount >= 50) {
      await _achievementRepository.updateProgress('record_100', recordCount);
    }

    return unlockedAchievements;
  }

  /// 检测状态成就
  Future<List<String>> _checkStatusAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    // 检测：第一次再遇
    if (record.status == EncounterStatus.reencounter) {
      final achievement = await _achievementRepository.getAchievement('first_reencounter');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('first_reencounter');
        unlockedAchievements.add('first_reencounter');
      }
    }

    // 检测：第一次邂逅
    if (record.status == EncounterStatus.met) {
      final achievement = await _achievementRepository.getAchievement('first_met');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('first_met');
        unlockedAchievements.add('first_met');
      }
    }

    // 检测：第一次重逢
    if (record.status == EncounterStatus.reunion) {
      final achievement = await _achievementRepository.getAchievement('first_reunion');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('first_reunion');
        unlockedAchievements.add('first_reunion');
      }
    }

    // 检测：第一次失联
    if (record.status == EncounterStatus.lost) {
      final achievement = await _achievementRepository.getAchievement('first_lost');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('first_lost');
        unlockedAchievements.add('first_lost');
      }
    }

    // 检测：第一次别离
    if (record.status == EncounterStatus.farewell) {
      final achievement = await _achievementRepository.getAchievement('first_farewell');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('first_farewell');
        unlockedAchievements.add('first_farewell');
      }
    }

    return unlockedAchievements;
  }

  /// 检测时间成就
  Future<List<String>> _checkTimeAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    // 检测：深夜的错过（22:00后）
    if (record.timestamp.hour >= 22) {
      final achievement = await _achievementRepository.getAchievement('late_night');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('late_night');
        unlockedAchievements.add('late_night');
      }
    }

    // 检测：清晨的错过（7:00前）
    if (record.timestamp.hour < 7) {
      final achievement = await _achievementRepository.getAchievement('early_morning');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('early_morning');
        unlockedAchievements.add('early_morning');
      }
    }

    return unlockedAchievements;
  }

  /// 检测天气成就
  Future<List<String>> _checkWeatherAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    // 检测：雨天的错过
    if (record.weather.any((w) =>
        w == Weather.drizzle ||
        w == Weather.lightRain ||
        w == Weather.moderateRain ||
        w == Weather.heavyRain ||
        w == Weather.rainstorm)) {
      final achievement = await _achievementRepository.getAchievement('rainy_day');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('rainy_day');
        unlockedAchievements.add('rainy_day');
      }
    }

    return unlockedAchievements;
  }

  /// 检测地点成就
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
      if (sameLocationCount >= 5) {
        await _achievementRepository.updateProgress('same_place_5', sameLocationCount);
        final achievement = await _achievementRepository.getAchievement('same_place_5');
        if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('same_place_5')) {
          unlockedAchievements.add('same_place_5');
        }
      } else {
        await _achievementRepository.updateProgress('same_place_5', sameLocationCount);
      }
    }

    // 检测：地铁常客
    if (record.location.placeType == PlaceType.subway) {
      final subwayCount = allRecords.where((r) => r.location.placeType == PlaceType.subway).length;
      if (subwayCount >= 10) {
        await _achievementRepository.updateProgress('subway_regular', subwayCount);
        final achievement = await _achievementRepository.getAchievement('subway_regular');
        if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('subway_regular')) {
          unlockedAchievements.add('subway_regular');
        }
      } else {
        await _achievementRepository.updateProgress('subway_regular', subwayCount);
      }
    }

    // 检测：咖啡馆邂逅
    if (record.location.placeType == PlaceType.coffeeShop && record.status == EncounterStatus.met) {
      final coffeeShopMetCount = allRecords.where((r) =>
          r.location.placeType == PlaceType.coffeeShop && r.status == EncounterStatus.met).length;
      if (coffeeShopMetCount >= 5) {
        await _achievementRepository.updateProgress('coffee_shop_met', coffeeShopMetCount);
        final achievement = await _achievementRepository.getAchievement('coffee_shop_met');
        if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('coffee_shop_met')) {
          unlockedAchievements.add('coffee_shop_met');
        }
      } else {
        await _achievementRepository.updateProgress('coffee_shop_met', coffeeShopMetCount);
      }
    }

    // 检测：城市漫游者
    final cityCount = AddressHelper.countUniqueCities(allRecords);
    if (cityCount >= 5) {
      await _achievementRepository.updateProgress('city_wanderer', cityCount);
      final achievement = await _achievementRepository.getAchievement('city_wanderer');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('city_wanderer')) {
        unlockedAchievements.add('city_wanderer');
      }
    } else {
      await _achievementRepository.updateProgress('city_wanderer', cityCount);
    }

    return unlockedAchievements;
  }

  /// 检测节日成就
  Future<List<String>> _checkHolidayAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    // 检测：节日的错过
    if (HolidayHelper.isHoliday(record.timestamp)) {
      final achievement = await _achievementRepository.getAchievement('holiday_missed');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('holiday_missed');
        unlockedAchievements.add('holiday_missed');
      }
    }

    return unlockedAchievements;
  }

  /// 检测成功率成就
  Future<List<String>> _checkSuccessRateAchievements(
    List<EncounterRecord> allRecords,
  ) async {
    final unlockedAchievements = <String>[];

    // 检测：成功率达到10%
    final successRate = _calculateSuccessRate(allRecords);
    if (successRate >= 10.0) {
      final achievement = await _achievementRepository.getAchievement('success_rate_10');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('success_rate_10');
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

