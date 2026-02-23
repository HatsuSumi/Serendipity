import 'dart:math' as math;
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/record_repository.dart';
import '../repositories/story_line_repository.dart';
import '../repositories/check_in_repository.dart';

/// 成就检测服务
/// 
/// 负责检测用户是否满足成就解锁条件
/// 
/// 调用者：
/// - RecordsProvider：记录操作后检测成就
/// - StoryLinesProvider：故事线操作后检测成就
/// - CheckInProvider：签到后检测成就
/// 
/// 设计原则：
/// - 单一职责：只负责成就检测逻辑
/// - Fail Fast：参数校验，立即抛出异常
/// - 不产生副作用：只检测，不修改数据（解锁由Repository负责）
class AchievementDetector {
  final AchievementRepository _achievementRepository;
  final RecordRepository _recordRepository;
  final StoryLineRepository _storyLineRepository;
  final CheckInRepository _checkInRepository;

  AchievementDetector(
    this._achievementRepository,
    this._recordRepository,
    this._storyLineRepository,
    this._checkInRepository,
  );

  /// 检测记录相关成就
  /// 
  /// 在创建或更新记录后调用
  /// 返回新解锁的成就ID列表
  Future<List<String>> checkRecordAchievements(EncounterRecord record) async {
    print('🔍 [AchievementDetector] 开始检测记录相关成就...');
    final unlockedAchievements = <String>[];

    // 获取所有记录
    final allRecords = _recordRepository.getAllRecords();
    final recordCount = allRecords.length;
    print('🔍 [AchievementDetector] 当前记录总数: $recordCount');

    // 检测：第一次错过
    // 兼容历史数据：只要有记录且成就未解锁，就解锁
    if (recordCount >= 1) {
      print('🔍 [AchievementDetector] 检测到有记录（共 $recordCount 条），检查 first_missed 成就...');
      final achievement = await _achievementRepository.getAchievement('first_missed');
      print('🔍 [AchievementDetector] first_missed 成就: ${achievement?.toJson()}');
      if (achievement != null && !achievement.unlocked) {
        print('🎉 [AchievementDetector] 解锁 first_missed 成就！');
        await _achievementRepository.unlockAchievement('first_missed');
        unlockedAchievements.add('first_missed');
      } else if (achievement == null) {
        print('❌ [AchievementDetector] first_missed 成就不存在！');
      } else {
        print('ℹ️ [AchievementDetector] first_missed 成就已解锁');
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
        r.location.placeType == PlaceType.coffeeShop && r.status == EncounterStatus.met
      ).length;
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
    final cityCount = _countUniqueCities(allRecords);
    if (cityCount >= 5) {
      await _achievementRepository.updateProgress('city_wanderer', cityCount);
      final achievement = await _achievementRepository.getAchievement('city_wanderer');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('city_wanderer')) {
        unlockedAchievements.add('city_wanderer');
      }
    } else {
      await _achievementRepository.updateProgress('city_wanderer', cityCount);
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

    return unlockedAchievements;
  }

  /// 检测签到相关成就
  /// 
  /// 在签到后调用
  /// 返回新解锁的成就ID列表
  Future<List<String>> checkCheckInAchievements() async {
    final unlockedAchievements = <String>[];

    // 获取签到统计
    final consecutiveDays = _checkInRepository.calculateConsecutiveDays();
    final totalDays = _checkInRepository.getTotalCheckInDays();

    // 检测：连续7天签到
    if (consecutiveDays >= 7) {
      await _achievementRepository.updateProgress('streak_7_days', consecutiveDays);
      final achievement = await _achievementRepository.getAchievement('streak_7_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('streak_7_days')) {
        unlockedAchievements.add('streak_7_days');
      }
    } else {
      await _achievementRepository.updateProgress('streak_7_days', consecutiveDays);
    }

    // 检测：连续30天签到
    if (consecutiveDays >= 30) {
      await _achievementRepository.updateProgress('streak_30_days', consecutiveDays);
      final achievement = await _achievementRepository.getAchievement('streak_30_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('streak_30_days')) {
        unlockedAchievements.add('streak_30_days');
      }
    } else if (consecutiveDays >= 7) {
      await _achievementRepository.updateProgress('streak_30_days', consecutiveDays);
    }

    // 检测：累计签到100天
    if (totalDays >= 100) {
      await _achievementRepository.updateProgress('checkin_100_days', totalDays);
      final achievement = await _achievementRepository.getAchievement('checkin_100_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('checkin_100_days')) {
        unlockedAchievements.add('checkin_100_days');
      }
    } else {
      await _achievementRepository.updateProgress('checkin_100_days', totalDays);
    }

    // 检测：累计签到365天
    if (totalDays >= 365) {
      await _achievementRepository.updateProgress('checkin_365_days', totalDays);
      final achievement = await _achievementRepository.getAchievement('checkin_365_days');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('checkin_365_days')) {
        unlockedAchievements.add('checkin_365_days');
      }
    } else if (totalDays >= 100) {
      await _achievementRepository.updateProgress('checkin_365_days', totalDays);
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
    } else {
      await _achievementRepository.updateProgress('story_collector', storyLineCount);
    }

    // 检测：故事大师（10条故事线）
    if (storyLineCount >= 10) {
      await _achievementRepository.updateProgress('story_master', storyLineCount);
      final achievement = await _achievementRepository.getAchievement('story_master');
      if (achievement != null && achievement.unlocked && !unlockedAchievements.contains('story_master')) {
        unlockedAchievements.add('story_master');
      }
    } else if (storyLineCount >= 3) {
      await _achievementRepository.updateProgress('story_master', storyLineCount);
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
  /// 从地址中提取城市名称
  /// 
  /// 支持的格式：
  /// - 直辖市：北京市、上海市、天津市、重庆市
  /// - 省级城市：广东省广州市、浙江省杭州市
  /// - 自治区：新疆维吾尔自治区乌鲁木齐市
  int _countUniqueCities(List<EncounterRecord> records) {
    final cities = <String>{};
    for (final record in records) {
      final address = record.location.address;
      if (address != null && address.isNotEmpty) {
        final city = _extractCityFromAddress(address);
        if (city != null) {
          cities.add(city);
        }
      }
    }
    return cities.length;
  }

  /// 从地址中提取城市名称
  /// 
  /// 返回标准化的城市名称（如"北京市"、"广州市"）
  String? _extractCityFromAddress(String address) {
    // 1. 直辖市：北京市、上海市、天津市、重庆市
    final municipalities = ['北京市', '上海市', '天津市', '重庆市'];
    for (final city in municipalities) {
      if (address.contains(city)) {
        return city;
      }
    }

    // 2. 省级城市：匹配 "XX省XX市" 或 "XX自治区XX市"
    final provinceCityPattern = RegExp(
      r'(?:[\u4e00-\u9fa5]+(?:省|自治区))([\u4e00-\u9fa5]+市)',
    );
    final provinceCityMatch = provinceCityPattern.firstMatch(address);
    if (provinceCityMatch != null) {
      return provinceCityMatch.group(1); // 返回城市名（如"广州市"）
    }

    // 3. 只有城市名：匹配 "XX市"（但排除区县）
    final cityPattern = RegExp(r'([\u4e00-\u9fa5]{2,}市)');
    final cityMatch = cityPattern.firstMatch(address);
    if (cityMatch != null) {
      final cityName = cityMatch.group(1)!;
      // 排除常见的区县名（如"朝阳市"可能是区名）
      if (!cityName.endsWith('区市') && !cityName.endsWith('县市')) {
        return cityName;
      }
    }

    return null;
  }

  /// 判断是否为节日
  /// 
  /// 支持的节日：
  /// - 固定日期：元旦、情人节、圣诞节、平安夜、白色情人节、万圣节
  /// - 近似日期：春节（1月21日-2月20日）、七夕（8月1日-8月31日）
  bool _isHoliday(DateTime date) {
    final month = date.month;
    final day = date.day;

    // 固定日期节日
    if (month == 1 && day == 1) return true; // 元旦
    if (month == 2 && day == 14) return true; // 情人节
    if (month == 3 && day == 14) return true; // 白色情人节
    if (month == 5 && day == 20) return true; // 520表白日
    if (month == 10 && day == 31) return true; // 万圣节
    if (month == 11 && day == 11) return true; // 双十一（光棍节）
    if (month == 12 && day == 24) return true; // 平安夜
    if (month == 12 && day == 25) return true; // 圣诞节

    // 春节：农历正月初一，公历通常在1月21日-2月20日之间
    if (month == 1 && day >= 21) return true;
    if (month == 2 && day <= 20) return true;

    // 七夕：农历七月初七，公历通常在8月
    if (month == 8) return true;

    // 中秋节：农历八月十五，公历通常在9月或10月初
    if (month == 9 && day >= 10) return true;
    if (month == 10 && day <= 10) return true;

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
}

