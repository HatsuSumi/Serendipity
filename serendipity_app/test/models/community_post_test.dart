import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/community_post.dart';
import 'package:serendipity_app/models/enums.dart';
import 'package:serendipity_app/models/encounter_record.dart';

void main() {
  group('CommunityPost', () {
    test('创建 CommunityPost 对象（完整信息）', () {
      final now = DateTime.now();
      final tags = [
        TagWithNote(tag: '长发', note: '光线不好，可能是深棕色'),
        TagWithNote(tag: '戴眼镜', note: '圆框眼镜，很文艺'),
      ];

      final post = CommunityPost(
        id: 'post001',
        recordId: 'record123',
        timestamp: now,
        address: '北京市朝阳区建国门外大街1号',
        placeName: '常去的那家咖啡馆',
        placeType: PlaceType.subway,
        province: '北京市',
        city: '北京市',
        area: '朝阳区',
        description: '她在读《百年孤独》',
        tags: tags,
        status: EncounterStatus.missed,
        isOwner: true,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(post.id, 'post001');
      expect(post.recordId, 'record123');
      expect(post.address, '北京市朝阳区建国门外大街1号');
      expect(post.placeName, '常去的那家咖啡馆');
      expect(post.placeType, PlaceType.subway);
      expect(post.province, '北京市');
      expect(post.city, '北京市');
      expect(post.area, '朝阳区');
      expect(post.description, '她在读《百年孤独》');
      expect(post.tags.length, 2);
      expect(post.status, EncounterStatus.missed);
      expect(post.isOwner, true);
    });

    test('创建 CommunityPost 对象（最小信息）', () {
      final now = DateTime.now();

      final post = CommunityPost(
        id: 'post001',
        recordId: 'record123',
        timestamp: now,
        description: '她在读《百年孤独》',
        tags: [],
        status: EncounterStatus.missed,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(post.address, isNull);
      expect(post.placeName, isNull);
      expect(post.placeType, isNull);
      expect(post.province, isNull);
      expect(post.city, isNull);
      expect(post.area, isNull);
      expect(post.tags.length, 0);
      expect(post.isOwner, false);
    });

    test('toJson 转换（完整信息）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);
      final tags = [
        TagWithNote(tag: '长发', note: '光线不好，可能是深棕色'),
      ];

      final post = CommunityPost(
        id: 'post001',
        recordId: 'record123',
        timestamp: now,
        address: '北京市朝阳区建国门外大街1号',
        placeName: '常去的那家咖啡馆',
        placeType: PlaceType.subway,
        province: '北京市',
        city: '北京市',
        area: '朝阳区',
        description: '她在读《百年孤独》',
        tags: tags,
        status: EncounterStatus.missed,
        isOwner: true,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = post.toJson();

      expect(json['id'], 'post001');
      expect(json['recordId'], 'record123');
      expect(json['address'], '北京市朝阳区建国门外大街1号');
      expect(json['placeName'], '常去的那家咖啡馆');
      expect(json['placeType'], 'subway');
      expect(json['province'], '北京市');
      expect(json['city'], '北京市');
      expect(json['area'], '朝阳区');
      expect(json['description'], '她在读《百年孤独》');
      expect(json['tags'], isList);
      expect(json['status'], EncounterStatus.missed.name);
      expect(json['isOwner'], true);
    });

    test('toJson 转换（最小信息）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final post = CommunityPost(
        id: 'post001',
        recordId: 'record123',
        timestamp: now,
        description: '她在读《百年孤独》',
        tags: [],
        status: EncounterStatus.missed,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = post.toJson();

      expect(json['address'], isNull);
      expect(json['placeName'], isNull);
      expect(json['placeType'], isNull);
      expect(json['province'], isNull);
      expect(json['city'], isNull);
      expect(json['area'], isNull);
      expect(json['tags'], isEmpty);
    });

    test('fromJson 转换（完整信息）', () {
      final json = {
        'id': 'post001',
        'recordId': 'record123',
        'timestamp': '2026-02-12T10:00:00.000',
        'address': '北京市朝阳区建国门外大街1号',
        'placeName': '常去的那家咖啡馆',
        'placeType': 'subway',
        'province': '北京市',
        'city': '北京市',
        'area': '朝阳区',
        'description': '她在读《百年孤独》',
        'tags': [
          {'tag': '长发', 'note': '光线不好，可能是深棕色'}
        ],
        'status': 'missed',
        'isOwner': true,
        'publishedAt': '2026-02-12T10:00:00.000',
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final post = CommunityPost.fromJson(json);

      expect(post.id, 'post001');
      expect(post.recordId, 'record123');
      expect(post.address, '北京市朝阳区建国门外大街1号');
      expect(post.placeType, PlaceType.subway);
      expect(post.province, '北京市');
      expect(post.city, '北京市');
      expect(post.area, '朝阳区');
      expect(post.tags.length, 1);
      expect(post.status, EncounterStatus.missed);
      expect(post.isOwner, true);
    });

    test('fromJson 转换（最小信息）', () {
      final json = {
        'id': 'post001',
        'recordId': 'record123',
        'timestamp': '2026-02-12T10:00:00.000',
        'address': null,
        'placeName': null,
        'placeType': null,
        'province': null,
        'city': null,
        'area': null,
        'description': '她在读《百年孤独》',
        'tags': [],
        'status': 'missed',
        'publishedAt': '2026-02-12T10:00:00.000',
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final post = CommunityPost.fromJson(json);

      expect(post.address, isNull);
      expect(post.placeName, isNull);
      expect(post.placeType, isNull);
      expect(post.province, isNull);
      expect(post.city, isNull);
      expect(post.area, isNull);
      expect(post.tags.length, 0);
      expect(post.isOwner, false);
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();
      final tags = [
        TagWithNote(tag: '长发', note: '光线不好，可能是深棕色'),
      ];

      final original = CommunityPost(
        id: 'post001',
        recordId: 'record123',
        timestamp: now,
        address: '北京市朝阳区建国门外大街1号',
        placeType: PlaceType.subway,
        province: '北京市',
        city: '北京市',
        area: '朝阳区',
        description: '她在读《百年孤独》',
        tags: tags,
        status: EncounterStatus.missed,
        isOwner: true,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = CommunityPost.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.recordId, original.recordId);
      expect(restored.address, original.address);
      expect(restored.placeType, original.placeType);
      expect(restored.province, original.province);
      expect(restored.city, original.city);
      expect(restored.area, original.area);
      expect(restored.description, original.description);
      expect(restored.status, original.status);
      expect(restored.isOwner, original.isOwner);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();

      final original = CommunityPost(
        id: 'post001',
        recordId: 'record123',
        timestamp: now,
        description: '她在读《百年孤独》',
        tags: [],
        status: EncounterStatus.missed,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        address: '北京市朝阳区建国门外大街1号',
        placeType: PlaceType.subway,
        isOwner: true,
      );

      expect(updated.id, original.id);
      expect(updated.address, '北京市朝阳区建国门外大街1号');
      expect(updated.placeType, PlaceType.subway);
      expect(updated.isOwner, true);
    });

    test('相等性比较', () {
      final now = DateTime.now();

      final post1 = CommunityPost(
        id: 'post001',
        recordId: 'record123',
        timestamp: now,
        description: '她在读《百年孤独》',
        tags: [],
        status: EncounterStatus.missed,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final post2 = CommunityPost(
        id: 'post001',
        recordId: 'record123',
        timestamp: now,
        description: '她在读《百年孤独》',
        tags: [],
        status: EncounterStatus.missed,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final post3 = CommunityPost(
        id: 'post002',
        recordId: 'record123',
        timestamp: now,
        description: '她在读《百年孤独》',
        tags: [],
        status: EncounterStatus.missed,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(post1 == post2, true);
      expect(post1 == post3, false);
    });

    test('toString 输出', () {
      final now = DateTime.now();

      final post = CommunityPost(
        id: 'post001',
        recordId: 'record123',
        timestamp: now,
        description: '她在读《百年孤独》',
        tags: [],
        status: EncounterStatus.missed,
        isOwner: true,
        publishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final str = post.toString();

      expect(str.contains('post001'), true);
      expect(str.contains('missed'), true);
      expect(str.contains('true'), true);
    });
  });
}

