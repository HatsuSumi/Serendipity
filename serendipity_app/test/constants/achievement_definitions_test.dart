import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/core/constants/achievement_definitions.dart';
import 'package:serendipity_app/models/achievement.dart';

void main() {
  group('AchievementDefinitions Tests', () {
    test('所有成就定义都存在', () {
      expect(AchievementDefinitions.all.length, 27);
    });

    test('成就ID唯一性', () {
      final ids = AchievementDefinitions.all.map((a) => a.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length, reason: '成就ID必须唯一');
    });

    test('所有成就都有必填字段', () {
      for (final achievement in AchievementDefinitions.all) {
        expect(achievement.id.isNotEmpty, true, reason: '${achievement.name}: ID不能为空');
        expect(achievement.name.isNotEmpty, true, reason: '${achievement.id}: 名称不能为空');
        expect(achievement.description.isNotEmpty, true, reason: '${achievement.id}: 描述不能为空');
        expect(achievement.icon.isNotEmpty, true, reason: '${achievement.id}: 图标不能为空');
      }
    });

    test('新手成就数量正确', () {
      final beginnerAchievements = AchievementDefinitions.all
          .where((a) => a.category == AchievementCategory.beginner)
          .toList();
      expect(beginnerAchievements.length, 3);
      
      // 验证具体成就
      expect(beginnerAchievements.any((a) => a.id == 'first_missed'), true);
      expect(beginnerAchievements.any((a) => a.id == 'record_10'), true);
      expect(beginnerAchievements.any((a) => a.id == 'streak_7_days'), true);
    });

    test('进阶成就数量正确', () {
      final advancedAchievements = AchievementDefinitions.all
          .where((a) => a.category == AchievementCategory.advanced)
          .toList();
      expect(advancedAchievements.length, 7);
    });

    test('稀有成就数量正确', () {
      final rareAchievements = AchievementDefinitions.all
          .where((a) => a.category == AchievementCategory.rare)
          .toList();
      expect(rareAchievements.length, 4);
    });

    test('故事线成就数量正确', () {
      final storyLineAchievements = AchievementDefinitions.all
          .where((a) => a.category == AchievementCategory.storyLine)
          .toList();
      expect(storyLineAchievements.length, 4);
    });

    test('社交成就数量正确', () {
      final socialAchievements = AchievementDefinitions.all
          .where((a) => a.category == AchievementCategory.social)
          .toList();
      expect(socialAchievements.length, 2);
    });

    test('情感成就数量正确', () {
      final emotionalAchievements = AchievementDefinitions.all
          .where((a) => a.category == AchievementCategory.emotional)
          .toList();
      expect(emotionalAchievements.length, 3);
    });

    test('特殊场景成就数量正确', () {
      final specialAchievements = AchievementDefinitions.all
          .where((a) => a.category == AchievementCategory.special)
          .toList();
      expect(specialAchievements.length, 4);
    });

    test('getById - 找到存在的成就', () {
      final achievement = AchievementDefinitions.getById('first_missed');
      expect(achievement, isNotNull);
      expect(achievement!.id, 'first_missed');
      expect(achievement.name, '第一次错过');
    });

    test('getById - 不存在的成就返回null', () {
      final achievement = AchievementDefinitions.getById('non_existent');
      expect(achievement, isNull);
    });

    test('getByCategory - 返回正确的成就列表', () {
      final beginnerAchievements = AchievementDefinitions.getByCategory(
        AchievementCategory.beginner,
      );
      expect(beginnerAchievements.length, 3);
      expect(
        beginnerAchievements.every((a) => a.category == AchievementCategory.beginner),
        true,
      );
    });

    test('进度型成就有正确的target值', () {
      final progressAchievements = AchievementDefinitions.all
          .where((a) => a.hasProgress)
          .toList();

      for (final achievement in progressAchievements) {
        expect(achievement.target, isNotNull);
        expect(achievement.target! > 0, true, reason: '${achievement.id}: target必须大于0');
        expect(achievement.progress, isNotNull);
        expect(achievement.progress! >= 0, true, reason: '${achievement.id}: progress必须>=0');
      }
    });

    test('所有成就默认未解锁', () {
      for (final achievement in AchievementDefinitions.all) {
        expect(achievement.unlocked, false, reason: '${achievement.id}: 默认应该未解锁');
        expect(achievement.unlockedAt, isNull, reason: '${achievement.id}: 默认没有解锁时间');
      }
    });

    test('验证关键成就存在', () {
      // 新手成就
      expect(AchievementDefinitions.getById('first_missed'), isNotNull);
      expect(AchievementDefinitions.getById('record_10'), isNotNull);
      expect(AchievementDefinitions.getById('streak_7_days'), isNotNull);

      // 进阶成就
      expect(AchievementDefinitions.getById('first_reencounter'), isNotNull);
      expect(AchievementDefinitions.getById('first_met'), isNotNull);
      expect(AchievementDefinitions.getById('first_reunion'), isNotNull);

      // 稀有成就
      expect(AchievementDefinitions.getById('record_50'), isNotNull);
      expect(AchievementDefinitions.getById('record_100'), isNotNull);
      expect(AchievementDefinitions.getById('success_rate_10'), isNotNull);
      expect(AchievementDefinitions.getById('streak_30_days'), isNotNull);

      // 故事线成就
      expect(AchievementDefinitions.getById('first_story_line'), isNotNull);
      expect(AchievementDefinitions.getById('story_collector'), isNotNull);
      expect(AchievementDefinitions.getById('story_master'), isNotNull);
      expect(AchievementDefinitions.getById('true_love'), isNotNull);

      // 社交成就
      expect(AchievementDefinitions.getById('first_community_post'), isNotNull);
      expect(AchievementDefinitions.getById('community_regular'), isNotNull);

      // 情感成就
      expect(AchievementDefinitions.getById('first_lost'), isNotNull);
      expect(AchievementDefinitions.getById('first_farewell'), isNotNull);
      expect(AchievementDefinitions.getById('new_beginning'), isNotNull);

      // 特殊场景成就
      expect(AchievementDefinitions.getById('subway_regular'), isNotNull);
      expect(AchievementDefinitions.getById('coffee_shop_met'), isNotNull);
      expect(AchievementDefinitions.getById('city_wanderer'), isNotNull);
      expect(AchievementDefinitions.getById('holiday_missed'), isNotNull);
    });

    test('验证进度型成就的target值', () {
      expect(AchievementDefinitions.getById('record_10')!.target, 10);
      expect(AchievementDefinitions.getById('record_50')!.target, 50);
      expect(AchievementDefinitions.getById('record_100')!.target, 100);
      expect(AchievementDefinitions.getById('streak_7_days')!.target, 7);
      expect(AchievementDefinitions.getById('streak_30_days')!.target, 30);
      expect(AchievementDefinitions.getById('same_place_5')!.target, 5);
      expect(AchievementDefinitions.getById('story_collector')!.target, 3);
      expect(AchievementDefinitions.getById('story_master')!.target, 10);
      expect(AchievementDefinitions.getById('true_love')!.target, 10);
      expect(AchievementDefinitions.getById('community_regular')!.target, 10);
      expect(AchievementDefinitions.getById('subway_regular')!.target, 10);
      expect(AchievementDefinitions.getById('coffee_shop_met')!.target, 5);
      expect(AchievementDefinitions.getById('city_wanderer')!.target, 5);
    });
  });
}

