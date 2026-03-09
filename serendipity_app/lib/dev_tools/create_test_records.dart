import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/encounter_record.dart';
import '../models/enums.dart';
import '../core/services/storage_service.dart';
import '../core/repositories/custom_server_auth_repository.dart';
import '../core/services/http_client_service.dart';

/// 开发工具：创建测试记录
/// 
/// 使用方法：
/// 1. 在 main.dart 中导入此文件
/// 2. 在 main() 函数中调用 createTestRecords()
/// 3. 运行 app 一次
/// 4. 注释掉调用代码，重新运行
Future<void> createTestRecords() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Hive
  await Hive.initFlutter();
  
  // 注册 TypeAdapter
  Hive.registerAdapter(EncounterStatusAdapter());
  Hive.registerAdapter(EmotionIntensityAdapter());
  Hive.registerAdapter(PlaceTypeAdapter());
  Hive.registerAdapter(WeatherAdapter());
  Hive.registerAdapter(TagWithNoteAdapter());
  Hive.registerAdapter(LocationAdapter());
  Hive.registerAdapter(EncounterRecordAdapter());
  
  // 初始化存储服务
  final storageService = StorageService();
  await storageService.init();
  
  print('🚀 开始创建测试账号和记录...');
  
  try {
    // 1. 先清除所有 Token（确保从全新状态开始）
    final httpClient = HttpClientService(storage: storageService);
    await httpClient.clearTokens();
    print('🧹 已清除旧的登录状态');
    
    // 2. 创建测试账号
    final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
    final testPassword = '111111';
    print('📧 正在注册账号: $testEmail');
    final authRepo = CustomServerAuthRepository(httpClient: httpClient);
    
    try {
      final result = await authRepo.signUpWithEmail(
        testEmail,
        testPassword,
      );
      print('✅ 账号注册成功！用户ID: ${result.user.id}');
      print('📧 邮箱: $testEmail');
      print('🔑 密码: $testPassword');
      
      // 2. 创建 500 条测试记录
      print('📝 开始创建 500 条测试记录...');
      final random = Random();
      final uuid = Uuid();
      final now = DateTime.now();
      
      // 所有可用的枚举值
      final statuses = EncounterStatus.values;
      final emotions = EmotionIntensity.values;
      final placeTypes = PlaceType.values;
      final weathers = Weather.values;
      
      // 一些示例标签
      final sampleTags = [
        '短发', '长发', '卷发', '直发',
        '眼镜', '帽子', '口罩', '耳机',
        '白衬衫', '黑T恤', '牛仔裤', '运动鞋',
        '背包', '手机', '咖啡', '书',
        '微笑', '安静', '匆忙', '悠闲',
      ];
      
      // 一些示例描述
      final sampleDescriptions = [
        '在地铁上看到的，戴着耳机在看书。',
        '咖啡馆里坐在窗边，阳光洒在脸上。',
        '公园里遛狗，笑得很开心。',
        '书店里翻看着一本书，很专注的样子。',
        '电影院门口等人，一直在看手机。',
        '超市里挑选水果，很认真的样子。',
        '健身房里跑步，汗水湿透了衣服。',
        '图书馆里安静地学习，桌上堆满了书。',
        '餐厅里和朋友聊天，笑声很爽朗。',
        '街道上匆匆走过，似乎在赶时间。',
      ];
      
      for (int i = 0; i < 500; i++) {
        // 随机生成时间（过去一年内）
        final daysAgo = random.nextInt(365);
        final hoursAgo = random.nextInt(24);
        final minutesAgo = random.nextInt(60);
        final timestamp = now.subtract(
          Duration(days: daysAgo, hours: hoursAgo, minutes: minutesAgo),
        );
        
        // 随机选择状态
        final status = statuses[random.nextInt(statuses.length)];
        
        // 随机选择情绪强度（80% 概率有）
        final emotion = random.nextDouble() < 0.8
            ? emotions[random.nextInt(emotions.length)]
            : null;
        
        // 随机选择场所类型
        final placeType = placeTypes[random.nextInt(placeTypes.length)];
        
        // 随机生成地点
        final location = Location(
          latitude: 39.9 + random.nextDouble() * 0.2, // 北京附近
          longitude: 116.3 + random.nextDouble() * 0.2,
          address: '北京市朝阳区某街道${random.nextInt(100)}号',
          placeName: placeType.label,
          placeType: placeType,
        );
        
        // 随机选择 2-4 个标签
        final tagCount = 2 + random.nextInt(3);
        final selectedTags = <String>[];
        while (selectedTags.length < tagCount) {
          final tag = sampleTags[random.nextInt(sampleTags.length)];
          if (!selectedTags.contains(tag)) {
            selectedTags.add(tag);
          }
        }
        final tags = selectedTags.map((tag) => TagWithNote(tag: tag)).toList();
        
        // 随机选择描述（70% 概率有）
        final description = random.nextDouble() < 0.7
            ? sampleDescriptions[random.nextInt(sampleDescriptions.length)]
            : null;
        
        // 随机选择天气（1-3 个）
        final weatherCount = 1 + random.nextInt(3);
        final selectedWeathers = <Weather>[];
        while (selectedWeathers.length < weatherCount) {
          final weather = weathers[random.nextInt(weathers.length)];
          if (!selectedWeathers.contains(weather)) {
            selectedWeathers.add(weather);
          }
        }
        
        // 创建记录
        final record = EncounterRecord(
          id: uuid.v4(), // 使用标准 UUID
          timestamp: timestamp,
          location: location,
          description: description,
          tags: tags,
          emotion: emotion,
          status: status,
          weather: selectedWeathers,
          createdAt: timestamp,
          updatedAt: timestamp,
          isPinned: false,
          ownerId: result.user.id, // 绑定到测试账号
        );
        
        // 保存记录
        await storageService.saveRecord(record);
        
        // 每 50 条打印一次进度
        if ((i + 1) % 50 == 0) {
          print('✅ 已创建 ${i + 1} 条记录');
        }
      }
      
      print('🎉 成功创建 500 条测试记录！');
      print('📊 账号信息：');
      print('   邮箱: $testEmail');
      print('   密码: $testPassword');
      print('   用户ID: ${result.user.id}');
      
    } catch (e) {
      print('❌ 注册或创建记录失败: $e');
      print('💡 提示：请重新运行脚本');
    }
    
  } catch (e) {
    print('❌ 创建测试数据时出错: $e');
  }
}

