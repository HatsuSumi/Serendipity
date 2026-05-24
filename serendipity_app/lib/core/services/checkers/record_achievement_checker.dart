import '../../../models/encounter_record.dart';
import '../../../models/enums.dart';
import '../../repositories/record_repository.dart';
import '../../utils/geo_helper.dart';
import '../../utils/address_helper.dart';
import '../../utils/holiday_helper.dart';
import 'base_achievement_checker.dart';

class RecordAchievementChecker extends BaseAchievementChecker {
  final RecordRepository _recordRepository;

  RecordAchievementChecker(
    super.achievementRepository,
    this._recordRepository,
  );

  Future<List<String>> check(EncounterRecord record, String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final unlockedAchievements = <String>[];
    final allRecords = _recordRepository.getRecordsByUser(userId);

    unlockedAchievements.addAll(await _checkRecordCountAchievements(allRecords));
    unlockedAchievements.addAll(await _checkStatusAchievements(record));
    unlockedAchievements.addAll(await _checkTimeAchievements(record));
    unlockedAchievements.addAll(await _checkWeatherAchievements(record));
    unlockedAchievements.addAll(await _checkLocationAchievements(record, allRecords));
    unlockedAchievements.addAll(await _checkHolidayAchievements(record));
    unlockedAchievements.addAll(await _checkSuccessRateAchievements(allRecords));

    return unlockedAchievements;
  }

  Future<List<String>> checkAll(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final unlockedAchievements = <String>[];
    final allRecords = _recordRepository.getRecordsByUser(userId);

    unlockedAchievements.addAll(await _checkRecordCountAchievements(allRecords));
    for (final record in allRecords) {
      unlockedAchievements.addAll(await _checkStatusAchievements(record));
      unlockedAchievements.addAll(await _checkTimeAchievements(record));
      unlockedAchievements.addAll(await _checkWeatherAchievements(record));
      unlockedAchievements.addAll(await _checkLocationAchievements(record, allRecords));
      unlockedAchievements.addAll(await _checkHolidayAchievements(record));
    }
    unlockedAchievements.addAll(await _checkSuccessRateAchievements(allRecords));

    return unlockedAchievements;
  }

  Future<List<String>> _checkRecordCountAchievements(List<EncounterRecord> allRecords) async {
    final unlockedAchievements = <String>[];
    final recordCount = allRecords.length;

    if (recordCount >= 1) {
      final justUnlocked = await achievementRepository.unlockAchievement('first_missed');
      if (justUnlocked) {
        unlockedAchievements.add('first_missed');
      }
    }

    unlockedAchievements.addAll(
      await checkProgressAchievements(
        recordCount,
        ['record_10', 'record_50', 'record_100'],
      ),
    );

    return unlockedAchievements;
  }

  Future<List<String>> _checkStatusAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    const statusAchievementMap = {
      EncounterStatus.reencounter: 'first_reencounter',
      EncounterStatus.met: 'first_met',
      EncounterStatus.reunion: 'first_reunion',
      EncounterStatus.lost: 'first_lost',
      EncounterStatus.farewell: 'first_farewell',
    };

    final achievementId = statusAchievementMap[record.status];
    if (achievementId != null) {
      final justUnlocked = await achievementRepository.unlockAchievement(achievementId);
      if (justUnlocked) {
        unlockedAchievements.add(achievementId);
      }
    }

    return unlockedAchievements;
  }

  Future<List<String>> _checkTimeAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    if (record.timestamp.hour >= 22) {
      final justUnlocked = await achievementRepository.unlockAchievement('late_night');
      if (justUnlocked) {
        unlockedAchievements.add('late_night');
      }
    }

    if (record.timestamp.hour < 7) {
      final justUnlocked = await achievementRepository.unlockAchievement('early_morning');
      if (justUnlocked) {
        unlockedAchievements.add('early_morning');
      }
    }

    return unlockedAchievements;
  }

  Future<List<String>> _checkWeatherAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

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

  Future<List<String>> _checkLocationAchievements(
    EncounterRecord record,
    List<EncounterRecord> allRecords,
  ) async {
    final unlockedAchievements = <String>[];

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

    final subwayCount = allRecords.where((r) => r.location.placeType == PlaceType.subway).length;
    final subwayUnlocked = await achievementRepository.updateProgress('subway_regular', subwayCount);
    if (subwayUnlocked) {
      unlockedAchievements.add('subway_regular');
    }

    final coffeeShopMetCount = allRecords.where((r) =>
        r.location.placeType == PlaceType.coffeeShop && r.status == EncounterStatus.met).length;
    final coffeeUnlocked = await achievementRepository.updateProgress('coffee_shop_met', coffeeShopMetCount);
    if (coffeeUnlocked) {
      unlockedAchievements.add('coffee_shop_met');
    }

    final cityCount = AddressHelper.countUniqueCities(allRecords);
    final cityUnlocked = await achievementRepository.updateProgress('city_wanderer', cityCount);
    if (cityUnlocked) {
      unlockedAchievements.add('city_wanderer');
    }

    return unlockedAchievements;
  }

  Future<List<String>> _checkHolidayAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    if (HolidayHelper.isHoliday(record.timestamp)) {
      final justUnlocked = await achievementRepository.unlockAchievement('holiday_missed');
      if (justUnlocked) {
        unlockedAchievements.add('holiday_missed');
      }
    }

    return unlockedAchievements;
  }

  Future<List<String>> _checkSuccessRateAchievements(List<EncounterRecord> allRecords) async {
    final unlockedAchievements = <String>[];

    final successRate = _calculateSuccessRate(allRecords);
    if (successRate >= 10.0) {
      final justUnlocked = await achievementRepository.unlockAchievement('success_rate_10');
      if (justUnlocked) {
        unlockedAchievements.add('success_rate_10');
      }
    }

    return unlockedAchievements;
  }

  double _calculateSuccessRate(List<EncounterRecord> records) {
    if (records.isEmpty) return 0.0;

    final successCount = records.where((r) =>
        r.status == EncounterStatus.met || r.status == EncounterStatus.reunion).length;

    return (successCount / records.length * 100).clamp(0.0, 100.0);
  }
}
