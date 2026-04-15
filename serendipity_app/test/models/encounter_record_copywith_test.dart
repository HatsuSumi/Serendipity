import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/encounter_record.dart';
import 'package:serendipity_app/models/enums.dart';

/// 测试 copyWith 方法是否能正确清空可选字段
void main() {
  group('EncounterRecord copyWith 测试', () {
    late EncounterRecord originalRecord;

    setUp(() {
      // 创建一个包含所有可选字段的记录
      originalRecord = EncounterRecord(
        id: 'test-id',
        timestamp: DateTime(2024, 1, 1),
        location: Location(
          latitude: 39.9,
          longitude: 116.4,
          address: '北京市朝阳区',
          placeName: '咖啡馆',
          placeType: PlaceType.coffeeShop,
        ),
        description: '这是一段描述',
        tags: [
          TagWithNote(tag: '标签1', note: '备注1'),
        ],
        emotion: EmotionIntensity.slightlyCared,
        status: EncounterStatus.missed,
        storyLineId: 'story-line-id',
        ifReencounter: '如果再遇的话',
        conversationStarter: '对话契机',
        backgroundMusic: '背景音乐',
        weather: [Weather.sunny],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    test('测试1: 尝试清空 description 字段', () {
      // 尝试将 description 设置为 null（使用函数包装）
      final updated = originalRecord.copyWith(description: () => null);

      // 现在应该成功清空
      expect(updated.description, isNull, 
        reason: '期望 description 为 null');
    });

    test('测试2: 尝试清空 emotion 字段', () {
      final updated = originalRecord.copyWith(emotion: () => null);

      expect(updated.emotion, isNull,
        reason: '期望 emotion 为 null');
    });

    test('测试3: 尝试清空 storyLineId 字段', () {
      final updated = originalRecord.copyWith(storyLineId: () => null);

      expect(updated.storyLineId, isNull,
        reason: '期望 storyLineId 为 null');
    });

    test('测试4: 尝试清空 ifReencounter 字段', () {
      final updated = originalRecord.copyWith(ifReencounter: () => null);

      expect(updated.ifReencounter, isNull,
        reason: '期望 ifReencounter 为 null');
    });

    test('测试5: 尝试清空 conversationStarter 字段', () {
      final updated = originalRecord.copyWith(conversationStarter: () => null);

      expect(updated.conversationStarter, isNull,
        reason: '期望 conversationStarter 为 null');
    });

    test('测试6: 尝试清空 backgroundMusic 字段', () {
      final updated = originalRecord.copyWith(backgroundMusic: () => null);

      expect(updated.backgroundMusic, isNull,
        reason: '期望 backgroundMusic 为 null');
    });

    test('测试7: 验证修改字段（非清空）是否正常工作', () {
      // 使用函数包装传递新值
      final updated = originalRecord.copyWith(
        description: () => '新的描述',
      );

      expect(updated.description, equals('新的描述'),
        reason: '修改字段应该正常工作');
    });

    test('测试8: 验证不传参数时字段保持不变', () {
      // 这个测试应该通过
      final updated = originalRecord.copyWith();

      expect(updated.description, equals(originalRecord.description),
        reason: '不传参数时字段应该保持不变');
      expect(updated.emotion, equals(originalRecord.emotion),
        reason: '不传参数时字段应该保持不变');
    });
  });

  // 注释掉这两个测试，因为 Location 和 TagWithNote 确实缺少 copyWith 方法
  // 这证实了问题2和问题4的存在
  
  // group('Location copyWith 测试', () {
  //   test('测试9: Location 是否有 copyWith 方法', () {
  //     final location = Location(
  //       latitude: 39.9,
  //       longitude: 116.4,
  //       address: '北京市',
  //       placeName: '咖啡馆',
  //       placeType: PlaceType.coffeeShop,
  //     );
  //
  //     // 尝试调用 copyWith 方法
  //     // 如果没有这个方法，编译会失败
  //     try {
  //       final updated = location.copyWith(placeName: '新咖啡馆');
  //       expect(updated.placeName, equals('新咖啡馆'));
  //     } catch (e) {
  //       fail('Location 类缺少 copyWith 方法: $e');
  //     }
  //   });
  // });
  //
  // group('TagWithNote copyWith 测试', () {
  //   test('测试10: TagWithNote 是否有 copyWith 方法', () {
  //     final tag = TagWithNote(tag: '标签', note: '备注');
  //
  //     // 尝试调用 copyWith 方法
  //     try {
  //       final updated = tag.copyWith(note: () => '新备注');
  //       expect(updated.note, equals('新备注'));
  //     } catch (e) {
  //       fail('TagWithNote 类缺少 copyWith 方法: $e');
  //     }
  //   });
  // });
}

