import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 开发工具：清空所有本地数据
/// 
/// 使用方法：
/// 1. 在 main.dart 中导入此文件
/// 2. 在 main() 函数中调用 clearAllData()
/// 3. 运行 app 一次
/// 4. 注释掉调用代码，重新运行
Future<void> clearAllData() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Hive
  await Hive.initFlutter();
  
  print('🧹 开始清空所有数据...');
  
  try {
    // 删除所有 Box
    await Hive.deleteBoxFromDisk('records');
    print('✅ 已删除 records box');
    
    await Hive.deleteBoxFromDisk('settings');
    print('✅ 已删除 settings box');
    
    await Hive.deleteBoxFromDisk('story_lines');
    print('✅ 已删除 story_lines box');
    
    await Hive.deleteBoxFromDisk('achievements');
    print('✅ 已删除 achievements box');
    
    await Hive.deleteBoxFromDisk('check_ins');
    print('✅ 已删除 check_ins box');
    
    await Hive.deleteBoxFromDisk('sync_histories');
    print('✅ 已删除 sync_histories box');

    await Hive.deleteBoxFromDisk('favorited_record_snapshots');
    print('✅ 已删除 favorited_record_snapshots box');

    await Hive.deleteBoxFromDisk('favorited_post_snapshots');
    print('✅ 已删除 favorited_post_snapshots box');

    await Hive.deleteBoxFromDisk('memberships');
    print('✅ 已删除 memberships box');
    
    print('🎉 所有数据已清空！');
  } catch (e) {
    print('❌ 清空数据时出错: $e');
  }
}

