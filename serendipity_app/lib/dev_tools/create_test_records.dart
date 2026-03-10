import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import 'dart:convert';
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
      
      // 2. 加载中国地区数据
      print('📍 正在加载中国地区数据...');
      final regionsJson = await rootBundle.loadString('assets/data/china_regions.json');
      final regions = json.decode(regionsJson) as List;
      
      // 构建所有可用的地址组合
      final allAddresses = <Map<String, String>>[];
      for (final province in regions) {
        final provinceName = province['name'] as String;
        final cities = province['city'] as List;
        for (final city in cities) {
          final cityName = city['name'] as String;
          final areas = city['area'] as List;
          for (final area in areas) {
            allAddresses.add({
              'province': provinceName,
              'city': cityName,
              'area': area as String,
            });
          }
        }
      }
      print('✅ 已加载 ${allAddresses.length} 个地址');
      
      // 3. 创建 500 条测试记录
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
      
      // 一些示例描述（通用，不绑定具体场所）
      final sampleDescriptions = [
        '安静地看着手机，偶尔抬起头来望向远处。',
        '戴着耳机，沉浸在自己的世界里。',
        '阳光落在她脸上，整个人显得很温柔。',
        '翻看着什么，神情很专注。',
        '和旁边的人轻声说着话，笑容很自然。',
        '一个人待着，看起来很悠然自在。',
        '行色匆匆，像是有什么重要的事。',
        '低着头若有所思，不知道在想什么。',
        '突然笑了一下，不知道想到了什么开心的事。',
        '安静地等待着，偶尔看一眼周围。',
        '整理了一下头发，抬头的瞬间恰好对上视线。',
        '从包里翻出什么，动作很利落。',
        '随意站着，却有一种说不清的气质。',
        '目光落在某处，沉默而平静。',
        '轻轻叹了口气，然后继续做自己的事。',
      ];
      
      // 一些示例"如果再遇"备忘
      final sampleIfReencounter = [
        '记得主动打个招呼',
        '鼓起勇气说一声你好',
        '希望下次能多看一眼',
        '想知道她叫什么名字',
        '记得微笑回应',
        '下次不要只是擦肩而过',
        '想问问他在忙什么',
        '希望能有机会说上几句话',
      ];
      
      // 一些示例对话契机（通用）
      final sampleConversationStarter = [
        '可以从天气聊起',
        '随便问一个问题，作为开场白',
        '微笑点头，看对方的反应',
        '聊聊最近发生的有趣事情',
        '可以请教对方一个小问题',
        '分享一个共同的瞬间',
        '从对方手上拿的东西聊起',
      ];
      
      // 一些示例背景音乐
      final sampleBackgroundMusic = [
        'Lemon - 米津玄师',
        '晴天 - 周杰伦',
        'Shape of You - Ed Sheeran',
        '告白气球 - 周杰伦',
        'Someone Like You - Adele',
        '演员 - 薛之谦',
        'Perfect - Ed Sheeran',
        '说散就散 - 袁娅维',
        'Faded - Alan Walker',
        '体面 - 于文文',
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
        
        // 随机选择地址
        final addressData = allAddresses[random.nextInt(allAddresses.length)];
        final streetNumber = random.nextInt(999) + 1;
        final address = '${addressData['province']}${addressData['city']}${addressData['area']}某街道${streetNumber}号';
        
        // 随机生成经纬度（中国范围：纬度 18-54，经度 73-135）
        final latitude = 18.0 + random.nextDouble() * 36.0;
        final longitude = 73.0 + random.nextDouble() * 62.0;
        
        // 随机生成地点
        final location = Location(
          latitude: latitude,
          longitude: longitude,
          address: address,
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
        
        // 随机选择"如果再遇"备忘（60% 概率有）
        final ifReencounter = random.nextDouble() < 0.6
            ? sampleIfReencounter[random.nextInt(sampleIfReencounter.length)]
            : null;
        
        // 随机选择对话契机（仅邂逅状态，50% 概率有）
        final conversationStarter = status == EncounterStatus.met && random.nextDouble() < 0.5
            ? sampleConversationStarter[random.nextInt(sampleConversationStarter.length)]
            : null;
        
        // 随机选择背景音乐（40% 概率有）
        final backgroundMusic = random.nextDouble() < 0.4
            ? sampleBackgroundMusic[random.nextInt(sampleBackgroundMusic.length)]
            : null;
        
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
          ifReencounter: ifReencounter,
          conversationStarter: conversationStarter,
          backgroundMusic: backgroundMusic,
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

