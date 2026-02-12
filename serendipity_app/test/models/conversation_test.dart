import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/conversation.dart';

void main() {
  group('Conversation', () {
    test('创建 Conversation 对象（活跃状态）', () {
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: 7));

      final conversation = Conversation(
        id: 'conv001',
        matchId: 'match001',
        userAId: 'userA',
        userBId: 'userB',
        startedAt: now,
        expiresAt: expiresAt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(conversation.id, 'conv001');
      expect(conversation.matchId, 'match001');
      expect(conversation.userAId, 'userA');
      expect(conversation.userBId, 'userB');
      expect(conversation.isActive, true);
      expect(conversation.endedAt, isNull);
      expect(conversation.endedBy, isNull);
    });

    test('创建 Conversation 对象（已结束状态）', () {
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: 7));
      final endedAt = now.add(Duration(days: 3));

      final conversation = Conversation(
        id: 'conv001',
        matchId: 'match001',
        userAId: 'userA',
        userBId: 'userB',
        startedAt: now,
        expiresAt: expiresAt,
        isActive: false,
        endedAt: endedAt,
        endedBy: 'userA',
        createdAt: now,
        updatedAt: now,
      );

      expect(conversation.isActive, false);
      expect(conversation.endedAt, endedAt);
      expect(conversation.endedBy, 'userA');
    });

    test('toJson 转换（活跃状态）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);
      final expiresAt = now.add(Duration(days: 7));

      final conversation = Conversation(
        id: 'conv001',
        matchId: 'match001',
        userAId: 'userA',
        userBId: 'userB',
        startedAt: now,
        expiresAt: expiresAt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = conversation.toJson();

      expect(json['id'], 'conv001');
      expect(json['matchId'], 'match001');
      expect(json['userAId'], 'userA');
      expect(json['userBId'], 'userB');
      expect(json['isActive'], true);
      expect(json['endedAt'], isNull);
      expect(json['endedBy'], isNull);
    });

    test('toJson 转换（已结束状态）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);
      final expiresAt = now.add(Duration(days: 7));
      final endedAt = now.add(Duration(days: 3));

      final conversation = Conversation(
        id: 'conv001',
        matchId: 'match001',
        userAId: 'userA',
        userBId: 'userB',
        startedAt: now,
        expiresAt: expiresAt,
        isActive: false,
        endedAt: endedAt,
        endedBy: 'userA',
        createdAt: now,
        updatedAt: now,
      );

      final json = conversation.toJson();

      expect(json['isActive'], false);
      expect(json['endedAt'], isNotNull);
      expect(json['endedBy'], 'userA');
    });

    test('fromJson 转换（活跃状态）', () {
      final json = {
        'id': 'conv001',
        'matchId': 'match001',
        'userAId': 'userA',
        'userBId': 'userB',
        'startedAt': '2026-02-12T10:00:00.000',
        'expiresAt': '2026-02-19T10:00:00.000',
        'isActive': true,
        'endedAt': null,
        'endedBy': null,
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.id, 'conv001');
      expect(conversation.matchId, 'match001');
      expect(conversation.isActive, true);
      expect(conversation.endedAt, isNull);
      expect(conversation.endedBy, isNull);
    });

    test('fromJson 转换（已结束状态）', () {
      final json = {
        'id': 'conv001',
        'matchId': 'match001',
        'userAId': 'userA',
        'userBId': 'userB',
        'startedAt': '2026-02-12T10:00:00.000',
        'expiresAt': '2026-02-19T10:00:00.000',
        'isActive': false,
        'endedAt': '2026-02-15T10:00:00.000',
        'endedBy': 'userA',
        'createdAt': '2026-02-12T10:00:00.000',
        'updatedAt': '2026-02-12T10:00:00.000',
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.isActive, false);
      expect(conversation.endedAt, DateTime(2026, 2, 15, 10, 0, 0));
      expect(conversation.endedBy, 'userA');
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: 7));

      final original = Conversation(
        id: 'conv001',
        matchId: 'match001',
        userAId: 'userA',
        userBId: 'userB',
        startedAt: now,
        expiresAt: expiresAt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = Conversation.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.matchId, original.matchId);
      expect(restored.userAId, original.userAId);
      expect(restored.userBId, original.userBId);
      expect(restored.isActive, original.isActive);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: 7));

      final original = Conversation(
        id: 'conv001',
        matchId: 'match001',
        userAId: 'userA',
        userBId: 'userB',
        startedAt: now,
        expiresAt: expiresAt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final endedAt = now.add(Duration(days: 3));
      final updated = original.copyWith(
        isActive: false,
        endedAt: endedAt,
        endedBy: 'userA',
      );

      expect(updated.id, original.id);
      expect(updated.isActive, false);
      expect(updated.endedAt, endedAt);
      expect(updated.endedBy, 'userA');
    });

    test('相等性比较', () {
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: 7));

      final conversation1 = Conversation(
        id: 'conv001',
        matchId: 'match001',
        userAId: 'userA',
        userBId: 'userB',
        startedAt: now,
        expiresAt: expiresAt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final conversation2 = Conversation(
        id: 'conv001',
        matchId: 'match001',
        userAId: 'userA',
        userBId: 'userB',
        startedAt: now,
        expiresAt: expiresAt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final conversation3 = Conversation(
        id: 'conv002',
        matchId: 'match001',
        userAId: 'userA',
        userBId: 'userB',
        startedAt: now,
        expiresAt: expiresAt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(conversation1 == conversation2, true);
      expect(conversation1 == conversation3, false);
    });

    test('toString 输出', () {
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: 7));

      final conversation = Conversation(
        id: 'conv001',
        matchId: 'match001',
        userAId: 'userA',
        userBId: 'userB',
        startedAt: now,
        expiresAt: expiresAt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final str = conversation.toString();

      expect(str.contains('conv001'), true);
      expect(str.contains('match001'), true);
      expect(str.contains('true'), true);
    });
  });

  group('Message', () {
    test('创建 Message 对象（未读）', () {
      final now = DateTime.now();

      final message = Message(
        id: 'msg001',
        conversationId: 'conv001',
        senderId: 'userA',
        receiverId: 'userB',
        content: '你好，真的是你！',
        isRead: false,
        sentAt: now,
        createdAt: now,
      );

      expect(message.id, 'msg001');
      expect(message.conversationId, 'conv001');
      expect(message.senderId, 'userA');
      expect(message.receiverId, 'userB');
      expect(message.content, '你好，真的是你！');
      expect(message.isRead, false);
      expect(message.readAt, isNull);
    });

    test('创建 Message 对象（已读）', () {
      final now = DateTime.now();
      final readAt = now.add(Duration(minutes: 5));

      final message = Message(
        id: 'msg001',
        conversationId: 'conv001',
        senderId: 'userA',
        receiverId: 'userB',
        content: '你好，真的是你！',
        isRead: true,
        readAt: readAt,
        sentAt: now,
        createdAt: now,
      );

      expect(message.isRead, true);
      expect(message.readAt, readAt);
    });

    test('toJson 转换（未读）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);

      final message = Message(
        id: 'msg001',
        conversationId: 'conv001',
        senderId: 'userA',
        receiverId: 'userB',
        content: '你好，真的是你！',
        isRead: false,
        sentAt: now,
        createdAt: now,
      );

      final json = message.toJson();

      expect(json['id'], 'msg001');
      expect(json['conversationId'], 'conv001');
      expect(json['senderId'], 'userA');
      expect(json['receiverId'], 'userB');
      expect(json['content'], '你好，真的是你！');
      expect(json['isRead'], false);
      expect(json['readAt'], isNull);
    });

    test('toJson 转换（已读）', () {
      final now = DateTime(2026, 2, 12, 10, 0, 0);
      final readAt = now.add(Duration(minutes: 5));

      final message = Message(
        id: 'msg001',
        conversationId: 'conv001',
        senderId: 'userA',
        receiverId: 'userB',
        content: '你好，真的是你！',
        isRead: true,
        readAt: readAt,
        sentAt: now,
        createdAt: now,
      );

      final json = message.toJson();

      expect(json['isRead'], true);
      expect(json['readAt'], isNotNull);
    });

    test('fromJson 转换（未读）', () {
      final json = {
        'id': 'msg001',
        'conversationId': 'conv001',
        'senderId': 'userA',
        'receiverId': 'userB',
        'content': '你好，真的是你！',
        'isRead': false,
        'readAt': null,
        'sentAt': '2026-02-12T10:00:00.000',
        'createdAt': '2026-02-12T10:00:00.000',
      };

      final message = Message.fromJson(json);

      expect(message.id, 'msg001');
      expect(message.content, '你好，真的是你！');
      expect(message.isRead, false);
      expect(message.readAt, isNull);
    });

    test('fromJson 转换（已读）', () {
      final json = {
        'id': 'msg001',
        'conversationId': 'conv001',
        'senderId': 'userA',
        'receiverId': 'userB',
        'content': '你好，真的是你！',
        'isRead': true,
        'readAt': '2026-02-12T10:05:00.000',
        'sentAt': '2026-02-12T10:00:00.000',
        'createdAt': '2026-02-12T10:00:00.000',
      };

      final message = Message.fromJson(json);

      expect(message.isRead, true);
      expect(message.readAt, DateTime(2026, 2, 12, 10, 5, 0));
    });

    test('toJson 和 fromJson 往返转换', () {
      final now = DateTime.now();

      final original = Message(
        id: 'msg001',
        conversationId: 'conv001',
        senderId: 'userA',
        receiverId: 'userB',
        content: '你好，真的是你！',
        isRead: false,
        sentAt: now,
        createdAt: now,
      );

      final json = original.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.conversationId, original.conversationId);
      expect(restored.senderId, original.senderId);
      expect(restored.receiverId, original.receiverId);
      expect(restored.content, original.content);
      expect(restored.isRead, original.isRead);
    });

    test('copyWith 修改字段', () {
      final now = DateTime.now();

      final original = Message(
        id: 'msg001',
        conversationId: 'conv001',
        senderId: 'userA',
        receiverId: 'userB',
        content: '你好，真的是你！',
        isRead: false,
        sentAt: now,
        createdAt: now,
      );

      final readAt = now.add(Duration(minutes: 5));
      final updated = original.copyWith(
        isRead: true,
        readAt: readAt,
      );

      expect(updated.id, original.id);
      expect(updated.isRead, true);
      expect(updated.readAt, readAt);
    });

    test('相等性比较', () {
      final now = DateTime.now();

      final message1 = Message(
        id: 'msg001',
        conversationId: 'conv001',
        senderId: 'userA',
        receiverId: 'userB',
        content: '你好，真的是你！',
        isRead: false,
        sentAt: now,
        createdAt: now,
      );

      final message2 = Message(
        id: 'msg001',
        conversationId: 'conv001',
        senderId: 'userA',
        receiverId: 'userB',
        content: '你好，真的是你！',
        isRead: false,
        sentAt: now,
        createdAt: now,
      );

      final message3 = Message(
        id: 'msg002',
        conversationId: 'conv001',
        senderId: 'userA',
        receiverId: 'userB',
        content: '是的，好巧！',
        isRead: false,
        sentAt: now,
        createdAt: now,
      );

      expect(message1 == message2, true);
      expect(message1 == message3, false);
    });

    test('toString 输出', () {
      final now = DateTime.now();

      final message = Message(
        id: 'msg001',
        conversationId: 'conv001',
        senderId: 'userA',
        receiverId: 'userB',
        content: '你好，真的是你！',
        isRead: false,
        sentAt: now,
        createdAt: now,
      );

      final str = message.toString();

      expect(str.contains('msg001'), true);
      expect(str.contains('conv001'), true);
      expect(str.contains('false'), true);
    });
  });
}

