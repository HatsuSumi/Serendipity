import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/story_line.dart';

void main() {
  group('StoryLine', () {
    test('创建 StoryLine 对象', () {
      final now = DateTime.now();
      final storyLine = StoryLine(
        id: 'story_1',
        name: '地铁上的她',
        recordIds: ['record_1', 'record_2', 'record_3'],
        createdAt: now,
        updatedAt: now,
      );

      expect(storyLine.id, 'story_1');
      expect(storyLine.name, '地铁上的她');
      expect(storyLine.recordIds.length, 3);
      expect(storyLine.recordIds[0], 'record_1');
      expect(storyLine.createdAt, now);
      expect(storyLine.updatedAt, now);
    });

    test('toJson 转换', () {
      final now = DateTime(2026, 2, 11, 12, 0, 0);
      final storyLine = StoryLine(
        id: 'story_1',
        name: '咖啡馆的他',
        recordIds: ['record_1', 'record_2'],
        createdAt: now,
        updatedAt: now,
      );

      final json = storyLine.toJson();

      expect(json['id'], 'story_1');
      expect(json['name'], '咖啡馆的他');
      expect(json['recordIds'], ['record_1', 'record_2']);
      expect(json['createdAt'], now.toIso8601String());
      expect(json['updatedAt'], now.toIso8601String());
    });

    test('fromJson 转换', () {
      final json = {
        'id': 'story_1',
        'name': '图书馆的女孩',
        'recordIds': ['record_1', 'record_2', 'record_3'],
        'createdAt': '2026-02-11T12:00:00.000',
        'updatedAt': '2026-02-11T13:00:00.000',
      };

      final storyLine = StoryLine.fromJson(json);

      expect(storyLine.id, 'story_1');
      expect(storyLine.name, '图书馆的女孩');
      expect(storyLine.recordIds.length, 3);
      expect(storyLine.recordIds[2], 'record_3');
      expect(storyLine.createdAt, DateTime(2026, 2, 11, 12, 0, 0));
      expect(storyLine.updatedAt, DateTime(2026, 2, 11, 13, 0, 0));
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();
      final original = StoryLine(
        id: 'story_1',
        name: '地铁上的她',
        recordIds: ['record_1', 'record_2'],
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = StoryLine.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.recordIds, original.recordIds);
      // 注意：DateTime 往返转换后会丢失微秒精度
      expect(
        restored.createdAt.millisecondsSinceEpoch,
        original.createdAt.millisecondsSinceEpoch,
      );
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();
      final original = StoryLine(
        id: 'story_1',
        name: '地铁上的她',
        recordIds: ['record_1'],
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        name: '咖啡馆的她',
        recordIds: ['record_1', 'record_2'],
      );

      expect(updated.id, original.id); // 未修改
      expect(updated.name, '咖啡馆的她'); // 已修改
      expect(updated.recordIds.length, 2); // 已修改
      expect(updated.createdAt, original.createdAt); // 未修改
    });

    test('相等性比较', () {
      final now = DateTime.now();
      final storyLine1 = StoryLine(
        id: 'story_1',
        name: '地铁上的她',
        recordIds: ['record_1', 'record_2'],
        createdAt: now,
        updatedAt: now,
      );

      final storyLine2 = StoryLine(
        id: 'story_1',
        name: '地铁上的她',
        recordIds: ['record_1', 'record_2'],
        createdAt: now,
        updatedAt: now,
      );

      final storyLine3 = StoryLine(
        id: 'story_2',
        name: '地铁上的她',
        recordIds: ['record_1', 'record_2'],
        createdAt: now,
        updatedAt: now,
      );

      expect(storyLine1 == storyLine2, true); // 相同
      expect(storyLine1 == storyLine3, false); // ID 不同
    });

    test('toString 输出', () {
      final now = DateTime.now();
      final storyLine = StoryLine(
        id: 'story_1',
        name: '地铁上的她',
        recordIds: ['record_1', 'record_2', 'record_3'],
        createdAt: now,
        updatedAt: now,
      );

      final str = storyLine.toString();

      expect(str.contains('story_1'), true);
      expect(str.contains('地铁上的她'), true);
      expect(str.contains('recordCount: 3'), true);
    });

    test('空记录列表', () {
      final now = DateTime.now();
      final storyLine = StoryLine(
        id: 'story_1',
        name: '新故事线',
        recordIds: [],
        createdAt: now,
        updatedAt: now,
      );

      expect(storyLine.recordIds.isEmpty, true);
      expect(storyLine.recordIds.length, 0);
    });
  });
}

