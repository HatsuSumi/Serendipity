import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/encounter_record.dart';
import 'package:serendipity_app/models/enums.dart';

void main() {
  group('TagWithNote', () {
    test('创建 TagWithNote 对象', () {
      final tag = TagWithNote(
        tag: '长发',
        note: '光线不好，可能是深棕色',
      );

      expect(tag.tag, '长发');
      expect(tag.note, '光线不好，可能是深棕色');
    });

    test('创建 TagWithNote 对象（无备注）', () {
      final tag = TagWithNote(tag: '戴眼镜');

      expect(tag.tag, '戴眼镜');
      expect(tag.note, isNull);
    });

    test('toJson 转换', () {
      final tag = TagWithNote(
        tag: '长发',
        note: '光线不好，可能是深棕色',
      );

      final json = tag.toJson();

      expect(json['tag'], '长发');
      expect(json['note'], '光线不好，可能是深棕色');
    });

    test('fromJson 转换', () {
      final json = {
        'tag': '戴眼镜',
        'note': '圆框眼镜，很文艺',
      };

      final tag = TagWithNote.fromJson(json);

      expect(tag.tag, '戴眼镜');
      expect(tag.note, '圆框眼镜，很文艺');
    });
  });

  group('Location', () {
    test('创建 Location 对象（完整信息）', () {
      final location = Location(
        latitude: 39.9087,
        longitude: 116.3975,
        address: '北京市朝阳区建国门外大街1号',
        placeName: '常去的那家咖啡馆',
        placeType: PlaceType.coffeeShop,
      );

      expect(location.latitude, 39.9087);
      expect(location.longitude, 116.3975);
      expect(location.address, '北京市朝阳区建国门外大街1号');
      expect(location.placeName, '常去的那家咖啡馆');
      expect(location.placeType, PlaceType.coffeeShop);
    });

    test('创建 Location 对象（仅 GPS）', () {
      final location = Location(
        latitude: 39.9087,
        longitude: 116.3975,
      );

      expect(location.latitude, 39.9087);
      expect(location.longitude, 116.3975);
      expect(location.address, isNull);
      expect(location.placeName, isNull);
      expect(location.placeType, isNull);
    });

    test('toJson 转换', () {
      final location = Location(
        latitude: 39.9087,
        longitude: 116.3975,
        address: '北京市朝阳区建国门外大街1号',
        placeName: '常去的那家咖啡馆',
        placeType: PlaceType.subway,
      );

      final json = location.toJson();

      expect(json['latitude'], 39.9087);
      expect(json['longitude'], 116.3975);
      expect(json['address'], '北京市朝阳区建国门外大街1号');
      expect(json['placeName'], '常去的那家咖啡馆');
      expect(json['placeType'], 'subway');
    });

    test('fromJson 转换', () {
      final json = {
        'latitude': 39.9087,
        'longitude': 116.3975,
        'address': '北京市朝阳区建国门外大街1号',
        'placeName': '常去的那家咖啡馆',
        'placeType': 'coffee_shop',
      };

      final location = Location.fromJson(json);

      expect(location.latitude, 39.9087);
      expect(location.longitude, 116.3975);
      expect(location.address, '北京市朝阳区建国门外大街1号');
      expect(location.placeName, '常去的那家咖啡馆');
      expect(location.placeType, PlaceType.coffeeShop);
    });
  });

  group('EncounterRecord', () {
    test('创建 EncounterRecord 对象（完整信息）', () {
      final now = DateTime.now();
      final record = EncounterRecord(
        id: 'record_1',
        timestamp: now,
        location: Location(
          latitude: 39.9087,
          longitude: 116.3975,
          address: '北京市朝阳区建国门外大街1号',
        ),
        description: '她在读《百年孤独》',
        tags: [
          TagWithNote(tag: '长发', note: '光线不好，可能是深棕色'),
          TagWithNote(tag: '戴眼镜'),
        ],
        emotion: EmotionIntensity.thoughtOnWayHome,
        status: EncounterStatus.missed,
        storyLineId: 'story_1',
        ifReencounter: '如果再遇到，我想搭话',
        backgroundMusic: '《遇见》',
        weather: Weather.sunny,
        createdAt: now,
        updatedAt: now,
      );

      expect(record.id, 'record_1');
      expect(record.timestamp, now);
      expect(record.description, '她在读《百年孤独》');
      expect(record.tags.length, 2);
      expect(record.emotion, EmotionIntensity.thoughtOnWayHome);
      expect(record.status, EncounterStatus.missed);
      expect(record.storyLineId, 'story_1');
    });

    test('创建 EncounterRecord 对象（最小信息）', () {
      final now = DateTime.now();
      final record = EncounterRecord(
        id: 'record_1',
        timestamp: now,
        location: Location(latitude: 39.9087, longitude: 116.3975),
        tags: [],
        status: EncounterStatus.missed,
        createdAt: now,
        updatedAt: now,
      );

      expect(record.id, 'record_1');
      expect(record.description, isNull);
      expect(record.tags.isEmpty, true);
      expect(record.emotion, isNull);
      expect(record.storyLineId, isNull);
    });

    test('toJson 转换', () {
      final now = DateTime(2026, 2, 11, 18, 30, 0);
      final record = EncounterRecord(
        id: 'record_1',
        timestamp: now,
        location: Location(
          latitude: 39.9087,
          longitude: 116.3975,
          address: '北京市朝阳区建国门外大街1号',
        ),
        description: '她在读《百年孤独》',
        tags: [
          TagWithNote(tag: '长发', note: '光线不好，可能是深棕色'),
        ],
        emotion: EmotionIntensity.thoughtOnWayHome,
        status: EncounterStatus.missed,
        createdAt: now,
        updatedAt: now,
      );

      final json = record.toJson();

      expect(json['id'], 'record_1');
      expect(json['timestamp'], now.toIso8601String());
      expect(json['description'], '她在读《百年孤独》');
      expect(json['tags'], isList);
      expect((json['tags'] as List).length, 1);
      expect(json['emotion'], EmotionIntensity.thoughtOnWayHome.value);
      expect(json['status'], EncounterStatus.missed.value);
    });

    test('fromJson 转换', () {
      final json = {
        'id': 'record_1',
        'timestamp': '2026-02-11T18:30:00.000',
        'location': {
          'latitude': 39.9087,
          'longitude': 116.3975,
          'address': '北京市朝阳区建国门外大街1号',
          'placeName': null,
          'placeType': null,
        },
        'description': '她在读《百年孤独》',
        'tags': [
          {'tag': '长发', 'note': '光线不好，可能是深棕色'},
          {'tag': '戴眼镜', 'note': null},
        ],
        'emotion': 3,
        'status': 1,
        'storyLineId': 'story_1',
        'ifReencounter': null,
        'conversationStarter': null,
        'backgroundMusic': null,
        'weather': 1,
        'createdAt': '2026-02-11T18:30:00.000',
        'updatedAt': '2026-02-11T18:30:00.000',
      };

      final record = EncounterRecord.fromJson(json);

      expect(record.id, 'record_1');
      expect(record.timestamp, DateTime(2026, 2, 11, 18, 30, 0));
      expect(record.description, '她在读《百年孤独》');
      expect(record.tags.length, 2);
      expect(record.tags[0].tag, '长发');
      expect(record.tags[0].note, '光线不好，可能是深棕色');
      expect(record.emotion, EmotionIntensity.thoughtOnWayHome);
      expect(record.status, EncounterStatus.missed);
      expect(record.storyLineId, 'story_1');
      expect(record.weather, Weather.sunny);
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();
      final original = EncounterRecord(
        id: 'record_1',
        timestamp: now,
        location: Location(
          latitude: 39.9087,
          longitude: 116.3975,
          address: '北京市朝阳区建国门外大街1号',
          placeName: '常去的那家咖啡馆',
          placeType: PlaceType.coffeeShop,
        ),
        description: '她在读《百年孤独》',
        tags: [
          TagWithNote(tag: '长发', note: '光线不好，可能是深棕色'),
          TagWithNote(tag: '戴眼镜'),
        ],
        emotion: EmotionIntensity.thoughtOnWayHome,
        status: EncounterStatus.missed,
        storyLineId: 'story_1',
        weather: Weather.sunny,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = EncounterRecord.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.description, original.description);
      expect(restored.tags.length, original.tags.length);
      expect(restored.emotion, original.emotion);
      expect(restored.status, original.status);
      expect(restored.storyLineId, original.storyLineId);
      expect(restored.weather, original.weather);
    });

    test('邂逅状态的对话契机', () {
      final now = DateTime.now();
      final record = EncounterRecord(
        id: 'record_1',
        timestamp: now,
        location: Location(latitude: 39.9087, longitude: 116.3975),
        tags: [],
        status: EncounterStatus.met,
        conversationStarter: '她掉了一本书，我帮她捡起来',
        createdAt: now,
        updatedAt: now,
      );

      expect(record.status, EncounterStatus.met);
      expect(record.conversationStarter, '她掉了一本书，我帮她捡起来');
    });
  });
}

