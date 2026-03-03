import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// 测试数据生成脚本
/// 
/// 用途：生成随机的社区帖子测试数据
/// 运行方式：dart run test/generate_test_posts.dart
/// 
/// 注意：只生成后端 CommunityPostResponseDto 需要的字段

void main() async {
  print('开始生成测试数据...');
  
  // 加载地区数据
  final regionsFile = File('assets/data/china_regions.json');
  final regionsJson = jsonDecode(await regionsFile.readAsString()) as List;
  
  // 解析地区数据
  final regions = <Map<String, dynamic>>[];
  for (final province in regionsJson) {
    final provinceName = province['name'] as String;
    final cities = province['city'] as List;
    
    for (final city in cities) {
      final cityName = city['name'] as String;
      final areas = city['area'] as List<dynamic>;
      
      for (final area in areas) {
        regions.add({
          'province': provinceName,
          'city': cityName,
          'area': area as String,
        });
      }
    }
  }
  
  print('已加载 ${regions.length} 个地区');
  
  // 生成测试帖子
  final posts = <Map<String, dynamic>>[];
  final random = Random();
  
  // 生成 500 个帖子
  for (int i = 0; i < 500; i++) {
    final region = regions[random.nextInt(regions.length)];
    final post = generateRandomPost(i + 1, region, random);
    posts.add(post);
  }
  
  // 保存到文件
  final outputFile = File('test/test_posts.json');
  await outputFile.writeAsString(
    JsonEncoder.withIndent('  ').convert(posts),
  );
  
  print('✅ 已生成 ${posts.length} 个测试帖子');
  print('📁 保存位置: ${outputFile.path}');
  
  // 统计信息
  final statusCount = <String, int>{};
  final regionCount = <String, int>{};
  
  for (final post in posts) {
    final status = post['status'] as String;
    statusCount[status] = (statusCount[status] ?? 0) + 1;
    
    final province = post['province'] as String;
    regionCount[province] = (regionCount[province] ?? 0) + 1;
  }
  
  print('\n📊 统计信息：');
  print('状态分布：');
  statusCount.forEach((status, count) {
    print('  $status: $count');
  });
  
  print('\n地区分布（前10）：');
  final sortedRegions = regionCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (int i = 0; i < min(10, sortedRegions.length); i++) {
    final entry = sortedRegions[i];
    print('  ${entry.key}: ${entry.value}');
  }
}

/// 生成随机帖子
/// 
/// 字段说明（严格匹配后端 CommunityPostResponseDto）：
/// - id: 帖子ID
/// - recordId: 关联的记录ID
/// - timestamp: 相遇时间
/// - address: 详细地址（可选）
/// - placeName: 地点名称（可选）
/// - placeType: 场所类型（可选）
/// - province: 省份（可选）
/// - city: 城市（可选）
/// - area: 区县（可选）
/// - description: 描述（可选）
/// - tags: 标签数组
/// - status: 状态（必填，字符串）
/// - publishedAt: 发布时间
/// - createdAt: 创建时间
/// - updatedAt: 更新时间
Map<String, dynamic> generateRandomPost(
  int index,
  Map<String, dynamic> region,
  Random random,
) {
  final now = DateTime.now();
  final timestamp = now.subtract(Duration(
    days: random.nextInt(365),
    hours: random.nextInt(24),
    minutes: random.nextInt(60),
  ));
  
  final status = _randomStatus(random);
  final placeType = _randomPlaceType(random);
  final hasDescription = random.nextDouble() < 0.7; // 70% 概率有描述
  final hasAddress = random.nextDouble() < 0.8; // 80% 概率有 GPS 地址
  
  return {
    'id': 'test_post_$index',
    'recordId': 'test_record_$index',
    'timestamp': timestamp.toIso8601String(),
    if (hasAddress) 'address': _randomAddress(region, random),
    if (hasAddress) 'province': region['province'],
    if (hasAddress) 'city': region['city'],
    if (hasAddress) 'area': region['area'],
    'placeName': _randomPlaceName(placeType, random),
    'placeType': placeType,
    if (hasDescription) 'description': _randomDescription(status, random),
    'tags': _randomTags(random),
    'status': status,
    'publishedAt': timestamp.toIso8601String(),
    'createdAt': timestamp.toIso8601String(),
    'updatedAt': timestamp.toIso8601String(),
  };
}

/// 随机状态（匹配 EncounterStatus 枚举的 name）
String _randomStatus(Random random) {
  const statuses = ['missed', 'avoid', 'reencounter', 'met', 'farewell', 'lost', 'reunion'];
  return statuses[random.nextInt(statuses.length)];
}

/// 随机场所类型（匹配 PlaceType 枚举的 value）
String _randomPlaceType(Random random) {
  const types = [
    'subway', 'bus', 'train', 'airport', 'coffee_shop', 'restaurant', 
    'bar', 'tea_house', 'dessert_shop', 'mall', 'supermarket', 'bookstore',
    'park', 'cinema', 'museum', 'art_gallery', 'aquarium', 'zoo', 
    'amusement_park', 'gym', 'swimming_pool', 'stadium', 'library', 
    'school', 'office', 'hospital', 'clinic', 'hotel', 'beach', 
    'mountain', 'street', 'other'
  ];
  return types[random.nextInt(types.length)];
}

/// 随机详细地址
String _randomAddress(Map<String, dynamic> region, Random random) {
  final streets = ['中山路', '人民路', '解放路', '建设路', '文化路', '和平路', '友谊路', '光明路'];
  final street = streets[random.nextInt(streets.length)];
  final number = random.nextInt(999) + 1;
  
  return '${region['province']}${region['city']}${region['area']}${street}${number}号';
}

/// 随机地点名称
String _randomPlaceName(String placeType, Random random) {
  final placeNames = {
    'subway': ['地铁1号线', '地铁2号线', '地铁10号线', '国贸站', '三里屯站', '西单站'],
    'bus': ['公交301路', '公交特2路', '公交快1路', '公交站台'],
    'cafe': ['星巴克', '瑞幸咖啡', '太平洋咖啡', 'Costa', '独立咖啡馆', '街角咖啡'],
    'restaurant': ['海底捞', '西贝莜面村', '外婆家', '绿茶餐厅', '小吃街', '美食广场'],
    'library': ['市图书馆', '区图书馆', '大学图书馆', '24小时书店'],
    'bookstore': ['西西弗书店', '言几又', '方所', '诚品书店', '新华书店'],
    'park': ['中央公园', '人民公园', '森林公园', '湿地公园', '体育公园'],
    'gym': ['健身房', '游泳馆', '瑜伽馆', '羽毛球馆', '篮球场'],
    'mall': ['万达广场', '大悦城', '银泰百货', '购物中心', '商业街'],
    'street': ['步行街', '商业街', '美食街', '酒吧街', '文化街'],
  };
  
  final names = placeNames[placeType] ?? ['某个地方'];
  return names[random.nextInt(names.length)];
}

/// 随机描述
String _randomDescription(String status, Random random) {
  final descriptions = {
    'missed': [
      '又在地铁上看到了，这次坐在对面，但还是没敢说话。',
      '在咖啡馆排队时遇到了，想打招呼但最后还是算了。',
      '路过时擦肩而过，心跳加速，但脚步没停。',
      '在书店看到了，假装在看书，其实一直在偷看。',
      '公交车上又遇到了，这次距离很近，但还是没勇气。',
    ],
    'avoid': [
      '远远看到了，假装没看见，低头玩手机。',
      '在商场遇到了，赶紧躲到另一个店里。',
      '看到TA走过来，立刻转身走了另一条路。',
      '在餐厅看到了，选了个背对的位置坐下。',
      '电梯里遇到了，假装看手机，一句话都没说。',
    ],
    'reencounter': [
      '这次鼓起勇气看了一眼，TA好像也注意到我了。',
      '在公园散步时又遇到了，这次对视了几秒。',
      '咖啡馆里又见面了，TA对我笑了一下。',
      '图书馆里又碰到了，这次坐得很近。',
      '健身房又遇到了，感觉TA也在注意我。',
    ],
    'met': [
      '终于说话了！聊了很久，感觉很好。',
      '今天主动打招呼了，TA很友好，交换了联系方式。',
      '在咖啡馆聊了一下午，发现有很多共同话题。',
      '一起吃了顿饭，气氛很好，约了下次见面。',
      '聊得很投机，感觉找到了知音。',
    ],
    'farewell': [
      '今天说了再见，不知道什么时候能再见。',
      'TA要去外地了，有点舍不得。',
      '分别的时候有点难过，但还会保持联系。',
      '各自忙各自的，见面的机会越来越少了。',
      '今天正式告别了，希望一切都好。',
    ],
    'lost': [
      '很久没联系了，发消息也不回。',
      '换了号码，找不到人了。',
      '社交账号都删了，完全失联了。',
      '搬家了，不知道去了哪里。',
      '彻底失去联系了，有点遗憾。',
    ],
    'reunion': [
      '没想到又遇到了！好久不见，变化很大。',
      '时隔多年再次相遇，感慨万千。',
      '在意想不到的地方重逢了，真是缘分。',
      '又见面了，一切都还是那么熟悉。',
      '重逢的感觉真好，聊了很多过去的事。',
    ],
  };
  
  final options = descriptions[status] ?? ['记录了这次相遇。'];
  return options[random.nextInt(options.length)];
}

/// 随机标签（匹配 TagDto 格式）
List<Map<String, String>> _randomTags(Random random) {
  const tagOptions = [
    '黑色长发', '短发', '卷发', '马尾', '眼镜', '口罩',
    '白色T恤', '黑色外套', '牛仔裤', '运动鞋', '背包',
    '耳机', '手机', '书', '咖啡', '雨伞', '帽子',
    '围巾', '手表', '项链', '戒指'
  ];
  
  final count = random.nextInt(5) + 1; // 1-5 个标签
  final tags = <Map<String, String>>[];
  final usedTags = <String>{};
  
  for (int i = 0; i < count; i++) {
    var tag = tagOptions[random.nextInt(tagOptions.length)];
    
    // 避免重复标签
    while (usedTags.contains(tag)) {
      tag = tagOptions[random.nextInt(tagOptions.length)];
    }
    usedTags.add(tag);
    
    final hasNote = random.nextDouble() < 0.3; // 30% 概率有备注
    
    tags.add({
      'tag': tag,
      if (hasNote) 'note': _randomTagNote(random),
    });
  }
  
  return tags;
}

/// 随机标签备注
String _randomTagNote(Random random) {
  const notes = [
    '很好看', '很特别', '印象深刻', '很配',
    '很有气质', '很温柔', '很帅气', '很可爱'
  ];
  return notes[random.nextInt(notes.length)];
}
