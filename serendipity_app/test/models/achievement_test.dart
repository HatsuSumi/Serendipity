import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/achievement.dart';

void main() {
  group('Achievement Model Tests', () {
    test('创建成就 - 所有必填字段', () {
      final achievement = Achievement(
        id: 'test_achievement',
        name: '测试成就',
        description: '这是一个测试成就',
        icon: '🎉',
        category: AchievementCategory.beginner,
      );

      expect(achievement.id, 'test_achievement');
      expect(achievement.name, '测试成就');
      expect(achievement.description, '这是一个测试成就');
      expect(achievement.icon, '🎉');
      expect(achievement.category, AchievementCategory.beginner);
      expect(achievement.unlocked, false);
      expect(achievement.unlockedAt, isNull);
      expect(achievement.progress, isNull);
      expect(achievement.target, isNull);
    });

    test('创建成就 - 包含进度信息', () {
      final achievement = Achievement(
        id: 'progress_achievement',
        name: '进度成就',
        description: '需要完成10次',
        icon: '📝',
        category: AchievementCategory.advanced,
        progress: 5,
        target: 10,
      );

      expect(achievement.hasProgress, true);
      expect(achievement.progress, 5);
      expect(achievement.target, 10);
      expect(achievement.progressPercentage, 50.0);
    });

    test('创建成就 - 已解锁状态', () {
      final unlockedAt = DateTime(2024, 1, 1);
      final achievement = Achievement(
        id: 'unlocked_achievement',
        name: '已解锁成就',
        description: '已经解锁',
        icon: '✅',
        category: AchievementCategory.rare,
        unlocked: true,
        unlockedAt: unlockedAt,
      );

      expect(achievement.unlocked, true);
      expect(achievement.unlockedAt, unlockedAt);
    });

    test('Fail Fast - ID不能为空', () {
      expect(
        () => Achievement(
          id: '',
          name: '测试',
          description: '描述',
          icon: '🎉',
          category: AchievementCategory.beginner,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Fail Fast - 名称不能为空', () {
      expect(
        () => Achievement(
          id: 'test',
          name: '',
          description: '描述',
          icon: '🎉',
          category: AchievementCategory.beginner,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Fail Fast - 已解锁必须有解锁时间', () {
      expect(
        () => Achievement(
          id: 'test',
          name: '测试',
          description: '描述',
          icon: '🎉',
          category: AchievementCategory.beginner,
          unlocked: true,
          // 缺少 unlockedAt
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Fail Fast - 进度不能超过目标', () {
      expect(
        () => Achievement(
          id: 'test',
          name: '测试',
          description: '描述',
          icon: '🎉',
          category: AchievementCategory.beginner,
          progress: 15,
          target: 10,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('toJson 和 fromJson - 基本成就', () {
      final achievement = Achievement(
        id: 'test',
        name: '测试成就',
        description: '测试描述',
        icon: '🎉',
        category: AchievementCategory.beginner,
      );

      final json = achievement.toJson();
      final restored = Achievement.fromJson(json);

      expect(restored.id, achievement.id);
      expect(restored.name, achievement.name);
      expect(restored.description, achievement.description);
      expect(restored.icon, achievement.icon);
      expect(restored.category, achievement.category);
      expect(restored.unlocked, achievement.unlocked);
    });

    test('toJson 和 fromJson - 完整成就', () {
      final unlockedAt = DateTime(2024, 1, 1);
      final achievement = Achievement(
        id: 'test',
        name: '测试成就',
        description: '测试描述',
        icon: '🎉',
        category: AchievementCategory.rare,
        unlocked: true,
        unlockedAt: unlockedAt,
        progress: 5,
        target: 10,
      );

      final json = achievement.toJson();
      final restored = Achievement.fromJson(json);

      expect(restored.id, achievement.id);
      expect(restored.unlocked, true);
      expect(restored.unlockedAt?.toIso8601String(), unlockedAt.toIso8601String());
      expect(restored.progress, 5);
      expect(restored.target, 10);
    });

    test('copyWith - 解锁成就', () {
      final achievement = Achievement(
        id: 'test',
        name: '测试成就',
        description: '测试描述',
        icon: '🎉',
        category: AchievementCategory.beginner,
      );

      final unlockedAt = DateTime.now();
      final unlocked = achievement.copyWith(
        unlocked: true,
        unlockedAt: () => unlockedAt,
      );

      expect(unlocked.unlocked, true);
      expect(unlocked.unlockedAt, unlockedAt);
      expect(unlocked.id, achievement.id);
      expect(unlocked.name, achievement.name);
    });

    test('copyWith - 更新进度', () {
      final achievement = Achievement(
        id: 'test',
        name: '测试成就',
        description: '测试描述',
        icon: '🎉',
        category: AchievementCategory.beginner,
        progress: 5,
        target: 10,
      );

      final updated = achievement.copyWith(
        progress: () => 8,
      );

      expect(updated.progress, 8);
      expect(updated.target, 10);
      expect(updated.progressPercentage, 80.0);
    });

    test('progressPercentage - 边界情况', () {
      // 无进度信息
      final noProgress = Achievement(
        id: 'test',
        name: '测试',
        description: '描述',
        icon: '🎉',
        category: AchievementCategory.beginner,
      );
      expect(noProgress.progressPercentage, 0.0);

      // 0%
      final zero = Achievement(
        id: 'test',
        name: '测试',
        description: '描述',
        icon: '🎉',
        category: AchievementCategory.beginner,
        progress: 0,
        target: 10,
      );
      expect(zero.progressPercentage, 0.0);

      // 100%
      final full = Achievement(
        id: 'test',
        name: '测试',
        description: '描述',
        icon: '🎉',
        category: AchievementCategory.beginner,
        progress: 10,
        target: 10,
      );
      expect(full.progressPercentage, 100.0);
    });
  });

  group('AchievementCategory Tests', () {
    test('所有类别都有正确的属性', () {
      expect(AchievementCategory.beginner.value, 'beginner');
      expect(AchievementCategory.beginner.label, '新手成就');
      expect(AchievementCategory.beginner.icon, '🌱');

      expect(AchievementCategory.advanced.value, 'advanced');
      expect(AchievementCategory.rare.value, 'rare');
      expect(AchievementCategory.storyLine.value, 'story_line');
      expect(AchievementCategory.social.value, 'social');
      expect(AchievementCategory.emotional.value, 'emotional');
      expect(AchievementCategory.special.value, 'special');
    });

    test('类别数量正确', () {
      expect(AchievementCategory.values.length, 7);
    });
  });
}
