import 'dart:math' as math;
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/record_repository.dart';
import '../repositories/story_line_repository.dart';

/// 成就检测服务
/// 
/// 负责检测用户是否满足成就解锁条件
/// 
/// 调用者：
/// - RecordsProvider：记录操作后检测成就
/// - StoryLinesProvider：故事线操作后检测成就
/// 
/// 设计原则：
/// - 单一职责：只负责成就检测逻辑
/// - Fail Fast：参数校验，立即抛出异常
/// - 不产生副作用：只检测，不修改数据（解锁由Repository负责）
class AchievementDetector {
  final AchievementRepository _achievementRepository;
  final RecordRepository _recordRepository;
  final StoryLineRepository _storyLineRepository;

  AchievementDetector(
    this._achievementRepository,
    this._recordRepository,
    this._storyLineRepository,
  );

  /// 检测记录相关成就
  /// 
  /// 在创建或更新记录后调用
  /// 返回新解锁的成就ID列表
  Future<List<String>> checkRecordAchievements(EncounterRecord record) async {
    final unlockedAchievements = <String>[];

    // 获取所有记录
    final allRecords = _recordRepository.getAllRecords();
    final recordCount = allRecords.length;

    // 检测：第一次错过
    if (recordCount == 1) {
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
    }

    // 检测：错过50个人
    if (recordCount >= 50) {
      await _achievementRepository.updateProgress('record_50', recordCount);
      final achievement = await _achievementRepository.getAchievement('record_50');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('record_50')) {
        unlockedAchievements.add('record_50');
      }
    }

    // 检测：错过100个人
    if (recordCount >= 100) {
      await _achievementRepository.updateProgress('record_100', recordCount);
      final achievement = await _achievementRepository.getAchievement('record_100');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('record_100')) {
        unlockedAchievements.add('record_100');
      }
    }

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

    // 检测：在同一地点错过5次
    if (record.location.latitude != null && record.location.longitude != null) {
      final sameLocationCount = _countRecordsAtSameLocation(
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
      }
    }

    // 检测：咖啡馆邂逅
    if (record.location.placeType == PlaceType.coffeeShop && record.status == EncounterStatus.met) {
      final coffeeShopMetCount = allRecords.where((r) => 
        r.location.placeType == PlaceType.coffeeShop && r.status == EncounterStatus.met
      ).length;
      if (coffeeShopMetCount >= 5) {
        await _achievementRepository.updateProgress('coffee_shop_met', coffeeShopMetCount);
        final achievement = await _achievementRepository.getAchievement('coffee_shop_met');
        if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('coffee_shop_met')) {
          unlockedAchievements.add('coffee_shop_met');
        }
      }
    }

    // 检测：城市漫游者
    final cityCount = _countUniqueCities(allRecords);
    if (cityCount >= 5) {
      await _achievementRepository.updateProgress('city_wanderer', cityCount);
      final achievement = await _achievementRepository.getAchievement('city_wanderer');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('city_wanderer')) {
        unlockedAchievements.add('city_wanderer');
      }
    }

    // 检测：节日的错过
    if (_isHoliday(record.timestamp)) {
      final achievement = await _achievementRepository.getAchievement('holiday_missed');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('holiday_missed');
        unlockedAchievements.add('holiday_missed');
      }
    }

    // 检测：成功率达到10%
    final successRate = _calculateSuccessRate(allRecords);
    if (successRate >= 10.0) {
      final achievement = await _achievementRepository.getAchievement('success_rate_10');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('success_rate_10');
        unlockedAchievements.add('success_rate_10');
      }
    }

    // 检测：连续天数
    final consecutiveDays = _calculateConsecutiveDays(allRecords);
    if (consecutiveDays >= 7) {
      await _achievementRepository.updateProgress('streak_7_days', consecutiveDays);
      final achievement = await _achievementRepository.getAchievement('streak_7_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('streak_7_days')) {
        unlockedAchievements.add('streak_7_days');
      }
    }
    if (consecutiveDays >= 30) {
      await _achievementRepository.updateProgress('streak_30_days', consecutiveDays);
      final achievement = await _achievementRepository.getAchievement('streak_30_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('streak_30_days')) {
        unlockedAchievements.add('streak_30_days');
      }
    }

    return unlockedAchievements;
  }

  /// 检测故事线相关成就
  /// 
  /// 在创建或更新故事线后调用
  /// 返回新解锁的成就ID列表
  Future<List<String>> checkStoryLineAchievements() async {
    final unlockedAchievements = <String>[];

    // 获取所有故事线
    final allStoryLines = _storyLineRepository.getAllStoryLines();
    final storyLineCount = allStoryLines.length;

    // 检测：第一条故事线
    if (storyLineCount == 1) {
      final achievement = await _achievementRepository.getAchievement('first_story_line');
      if (achievement != null && !achievement.unlocked) {
        await _achievementRepository.unlockAchievement('first_story_line');
        unlockedAchievements.add('first_story_line');
      }
    }

    // 检测：故事收集者（3条故事线）
    if (storyLineCount >= 3) {
      await _achievementRepository.updateProgress('story_collector', storyLineCount);
      final achievement = await _achievementRepository.getAchievement('story_collector');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('story_collector')) {
        unlockedAchievements.add('story_collector');
      }
    }

    // 检测：故事大师（10条故事线）
    if (storyLineCount >= 10) {
      await _achievementRepository.updateProgress('story_master', storyLineCount);
      final achievement = await _achievementRepository.getAchievement('story_master');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('story_master')) {
        unlockedAchievements.add('story_master');
      }
    }

    // 检测：真爱无价（同一个人的故事线达到10条记录）
    for (final storyLine in allStoryLines) {
      if (storyLine.recordIds.length >= 10) {
        final achievement = await _achievementRepository.getAchievement('true_love');
        if (achievement != null && !achievement.unlocked) {
          await _achievementRepository.unlockAchievement('true_love');
          unlockedAchievements.add('true_love');
          break;
        }
      }
    }

    return unlockedAchievements;
  }

  /// 计算在同一地点（GPS < 100米）的记录数量
  int _countRecordsAtSameLocation(List<EncounterRecord> records, double lat, double lon) {
    return records.where((r) {
      if (r.location.latitude == null || r.location.longitude == null) {
        return false;
      }
      final distance = _calculateDistance(
        lat,
        lon,
        r.location.latitude!,
        r.location.longitude!,
      );
      return distance < 100; // 100米内
    }).length;
  }

  /// 计算两个GPS坐标之间的距离（米）
  /// 使用 Haversine 公式
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // 地球半径（米）
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// 计算不同城市的数量
  /// 
  /// 从地址中提取城市名称（简单实现）
  int _countUniqueCities(List<EncounterRecord> records) {
    final cities = <String>{};
    for (final record in records) {
      final address = record.location.address;
      if (address != null && address.isNotEmpty) {
        // 简单提取：假设地址格式为 "省份+城市+区县+街道"
        // 例如："北京市朝阳区建国门外大街1号" -> "北京市"
        final cityMatch = RegExp(r'([\u4e00-\u9fa5]+市)').firstMatch(address);
        if (cityMatch != null) {
          cities.add(cityMatch.group(1)!);
        }
      }
    }
    return cities.length;
  }

  /// 判断是否为节日
  bool _isHoliday(DateTime date) {
    // 春节（农历正月初一，简化为公历1月或2月）
    // 情人节（2月14日）
    // 圣诞节（12月25日）
    // 元旦（1月1日）
    // 七夕（农历七月初七，简化为公历8月）
    
    if (date.month == 1 && date.day == 1) return true; // 元旦
    if (date.month == 2 && date.day == 14) return true; // 情人节
    if (date.month == 12 && date.day == 25) return true; // 圣诞节
    
    // 简化判断：1月或2月的任意一天可能是春节
    if (date.month == 1 || date.month == 2) return true;
    
    // 简化判断：8月的任意一天可能是七夕
    if (date.month == 8) return true;
    
    return false;
  }

  /// 计算成功率（邂逅+重逢的记录占比）
  double _calculateSuccessRate(List<EncounterRecord> records) {
    if (records.isEmpty) return 0.0;
    
    final successCount = records.where((r) => 
      r.status == EncounterStatus.met || r.status == EncounterStatus.reunion
    ).length;
    
    return (successCount / records.length * 100);
  }

  /// 计算连续天数
  /// 
  /// 从今天往前推，连续有记录的天数
  int _calculateConsecutiveDays(List<EncounterRecord> records) {
    if (records.isEmpty) return 0;

    // 按日期分组（忽略时间）
    final recordDates = records.map((r) {
      final date = r.timestamp;
      return DateTime(date.year, date.month, date.day);
    }).toSet().toList();

    recordDates.sort((a, b) => b.compareTo(a)); // 降序排列

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 如果今天没有记录，返回0
    if (!recordDates.contains(todayDate)) {
      return 0;
    }

    int consecutiveDays = 1;
    DateTime currentDate = todayDate;

    for (int i = 1; i < recordDates.length; i++) {
      final previousDate = currentDate.subtract(const Duration(days: 1));
      if (recordDates.contains(previousDate)) {
        consecutiveDays++;
        currentDate = previousDate;
      } else {
        break;
      }
    }

    return consecutiveDays;
  }
}

