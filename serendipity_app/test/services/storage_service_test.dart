import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:serendipity_app/core/services/storage_service.dart';
import 'package:serendipity_app/models/encounter_record.dart';
import 'package:serendipity_app/models/story_line.dart';
import 'package:serendipity_app/models/achievement.dart';
import 'package:serendipity_app/models/check_in_record.dart';
import 'package:serendipity_app/models/user.dart' as app_user;
import 'package:serendipity_app/models/enums.dart';
import 'dart:io';

void main() {
  group('StorageService Tests', () {
    late StorageService storageService;
    late Directory testDir;

    setUpAll(() async {
      // 创建临时测试目录
      testDir = Directory.systemTemp.createTempSync('hive_test_');
      
      // 初始化 Hive（使用临时目录）
      Hive.init(testDir.path);
      
      // 注册 TypeAdapter（只注册实际存在的）
      Hive.registerAdapter(EncounterStatusAdapter());
      Hive.registerAdapter(EmotionIntensityAdapter());
      Hive.registerAdapter(PlaceTypeAdapter());
      Hive.registerAdapter(WeatherAdapter());
      Hive.registerAdapter(AuthProviderAdapter());
      Hive.registerAdapter(MembershipTierAdapter());
      Hive.registerAdapter(MembershipStatusAdapter());
      Hive.registerAdapter(PaymentMethodAdapter());
      Hive.registerAdapter(PaymentStatusAdapter());
      Hive.registerAdapter(ThemeOptionAdapter());
      Hive.registerAdapter(AchievementCategoryAdapter());
      Hive.registerAdapter(TagWithNoteAdapter());
      Hive.registerAdapter(LocationAdapter());
      Hive.registerAdapter(EncounterRecordAdapter());
      Hive.registerAdapter(StoryLineAdapter());
      Hive.registerAdapter(app_user.UserAdapter());
      Hive.registerAdapter(AchievementAdapter());
      Hive.registerAdapter(CheckInRecordAdapter());
      
      storageService = StorageService();
      await storageService.init();
    });

    tearDownAll(() async {
      await storageService.close();
      await Hive.close();
      
      // 删除临时测试目录
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    });

    setUp(() async {
      // 每个测试前清空数据
      final records = storageService.getAllRecords();
      for (final record in records) {
        await storageService.deleteRecord(record.id);
      }
    });

    test('保存和读取记录', () async {
      // 创建测试记录
      final record = EncounterRecord(
        id: 'test-001',
        timestamp: DateTime.now(),
        location: Location(
          latitude: 39.9087,
          longitude: 116.3975,
          address: '北京市朝阳区建国门外大街1号',
          placeName: '国贸地铁站',
          placeType: PlaceType.subway,
        ),
        description: '地铁上遇到的她',
        tags: [
          TagWithNote(tag: '长发', note: '可能是深棕色'),
          TagWithNote(tag: '戴眼镜'),
        ],
        emotion: EmotionIntensity.slightlyCared,
        status: EncounterStatus.missed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 保存记录
      await storageService.saveRecord(record);

      // 读取记录
      final savedRecord = storageService.getRecord('test-001');

      // 验证
      expect(savedRecord, isNotNull);
      expect(savedRecord!.id, 'test-001');
      expect(savedRecord.description, '地铁上遇到的她');
      expect(savedRecord.status, EncounterStatus.missed);
      expect(savedRecord.tags.length, 2);
      expect(savedRecord.tags[0].tag, '长发');
      expect(savedRecord.tags[0].note, '可能是深棕色');
      expect(savedRecord.location.placeName, '国贸地铁站');
      expect(savedRecord.location.placeType, PlaceType.subway);
    });

    test('获取所有记录', () async {
      // 创建多条记录
      for (int i = 0; i < 5; i++) {
        final record = EncounterRecord(
          id: 'test-$i',
          timestamp: DateTime.now().subtract(Duration(days: i)),
          location: Location(
            latitude: 39.9087,
            longitude: 116.3975,
          ),
          tags: [],
          status: EncounterStatus.missed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await storageService.saveRecord(record);
      }

      // 获取所有记录
      final records = storageService.getAllRecords();

      // 验证
      expect(records.length, 5);
    });

    test('按时间排序获取记录', () async {
      // 创建多条记录（不同时间）
      final now = DateTime.now();
      await storageService.saveRecord(EncounterRecord(
        id: 'test-1',
        timestamp: now.subtract(const Duration(days: 2)),
        location: Location(),
        tags: [],
        status: EncounterStatus.missed,
        createdAt: now,
        updatedAt: now,
      ));
      await storageService.saveRecord(EncounterRecord(
        id: 'test-2',
        timestamp: now.subtract(const Duration(days: 1)),
        location: Location(),
        tags: [],
        status: EncounterStatus.missed,
        createdAt: now,
        updatedAt: now,
      ));
      await storageService.saveRecord(EncounterRecord(
        id: 'test-3',
        timestamp: now,
        location: Location(),
        tags: [],
        status: EncounterStatus.missed,
        createdAt: now,
        updatedAt: now,
      ));

      // 获取排序后的记录
      final records = storageService.getRecordsSortedByTime();

      // 验证（应该按时间倒序）
      expect(records.length, 3);
      expect(records[0].id, 'test-3'); // 最新的
      expect(records[1].id, 'test-2');
      expect(records[2].id, 'test-1'); // 最旧的
    });

    test('删除记录', () async {
      // 创建记录
      final record = EncounterRecord(
        id: 'test-delete',
        timestamp: DateTime.now(),
        location: Location(),
        tags: [],
        status: EncounterStatus.missed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await storageService.saveRecord(record);

      // 验证记录存在
      expect(storageService.getRecord('test-delete'), isNotNull);

      // 删除记录
      await storageService.deleteRecord('test-delete');

      // 验证记录已删除
      expect(storageService.getRecord('test-delete'), isNull);
    });

    test('更新记录', () async {
      // 创建记录
      final record = EncounterRecord(
        id: 'test-update',
        timestamp: DateTime.now(),
        location: Location(),
        description: '原始描述',
        tags: [],
        status: EncounterStatus.missed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await storageService.saveRecord(record);

      // 更新记录
      final updatedRecord = EncounterRecord(
        id: 'test-update',
        timestamp: record.timestamp,
        location: record.location,
        description: '更新后的描述',
        tags: [],
        status: EncounterStatus.reencounter,
        createdAt: record.createdAt,
        updatedAt: DateTime.now(),
      );
      await storageService.updateRecord(updatedRecord);

      // 验证更新
      final saved = storageService.getRecord('test-update');
      expect(saved!.description, '更新后的描述');
      expect(saved.status, EncounterStatus.reencounter);
    });

    test('根据故事线ID获取记录', () async {
      // 创建记录（部分有故事线ID）
      await storageService.saveRecord(EncounterRecord(
        id: 'test-1',
        timestamp: DateTime.now(),
        location: Location(),
        tags: [],
        status: EncounterStatus.missed,
        storyLineId: 'story-001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await storageService.saveRecord(EncounterRecord(
        id: 'test-2',
        timestamp: DateTime.now(),
        location: Location(),
        tags: [],
        status: EncounterStatus.missed,
        storyLineId: 'story-001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await storageService.saveRecord(EncounterRecord(
        id: 'test-3',
        timestamp: DateTime.now(),
        location: Location(),
        tags: [],
        status: EncounterStatus.missed,
        storyLineId: 'story-002',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 获取特定故事线的记录
      final records = storageService.getRecordsByStoryLine('story-001');

      // 验证
      expect(records.length, 2);
      expect(records.every((r) => r.storyLineId == 'story-001'), true);
    });

    test('获取未关联故事线的记录', () async {
      // 创建记录（部分没有故事线ID）
      await storageService.saveRecord(EncounterRecord(
        id: 'test-1',
        timestamp: DateTime.now(),
        location: Location(),
        tags: [],
        status: EncounterStatus.missed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await storageService.saveRecord(EncounterRecord(
        id: 'test-2',
        timestamp: DateTime.now(),
        location: Location(),
        tags: [],
        status: EncounterStatus.missed,
        storyLineId: 'story-001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 获取未关联故事线的记录
      final records = storageService.getRecordsWithoutStoryLine();

      // 验证
      expect(records.length, 1);
      expect(records[0].id, 'test-1');
      expect(records[0].storyLineId, isNull);
    });
  });
}
