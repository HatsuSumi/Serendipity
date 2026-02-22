import '../../models/encounter_record.dart';

/// 记录相关的工具类
/// 
/// 提供记录数据的通用处理方法，包括地点显示逻辑。
/// 
/// 调用者：
/// - UI 层：显示记录和地点信息
/// - 社区功能：显示社区帖子的地点
/// 
/// 设计原则：
/// - DRY：避免重复的显示逻辑
/// - 单一职责：只负责记录相关的辅助功能
class RecordHelper {
  RecordHelper._(); // 私有构造函数，防止实例化

  /// 获取地点的显示文本（用于记录卡片）
  /// 
  /// 显示优先级：
  /// 1. placeName + placeType 图标（最有温度）
  /// 2. address（标准地址）
  /// 3. placeType 图标 + 标签（至少有个分类）
  /// 4. "未知地点"（实在没有）
  /// 
  /// 调用者：
  /// - RecordCard：显示记录卡片
  /// - RecordDetailPage：显示记录详情
  /// - TimelinePage：显示时间轴
  /// 
  /// 示例：
  /// - 有 placeName + placeType：🚇 常去的那家咖啡馆
  /// - 有 placeName 无 placeType：常去的那家咖啡馆
  /// - 无 placeName 有 address：北京市朝阳区建国门外大街1号
  /// - 无 placeName 有 placeType：🚇 地铁
  /// - 都没有：未知地点
  static String getLocationText(Location location) {
    // 优先级 1：用户输入的地点名称（最有温度）
    if (location.placeName != null && location.placeName!.trim().isNotEmpty) {
      // 如果有场所类型，显示图标
      if (location.placeType != null) {
        return '${location.placeType!.icon} ${location.placeName}';
      }
      return location.placeName!;
    }
    
    // 优先级 2：GPS 获取的地址（标准但冷冰冰）
    if (location.address != null && location.address!.trim().isNotEmpty) {
      // 如果地址太长，截断显示
      if (location.address!.length > 30) {
        return '${location.address!.substring(0, 30)}...';
      }
      return location.address!;
    }
    
    // 优先级 3：场所类型（至少有个分类）
    if (location.placeType != null) {
      return '${location.placeType!.icon} ${location.placeType!.label}';
    }
    
    // 优先级 4：实在没有，显示默认文本
    return '未知地点';
  }
  
  /// 获取地点的完整显示文本（用于详情页）
  /// 
  /// 不截断地址，显示完整信息。
  /// 
  /// 调用者：
  /// - RecordDetailPage：显示完整地点信息
  /// 
  /// 示例：
  /// - 有 placeName + placeType + address：
  ///   🚇 常去的那家咖啡馆
  ///   北京市朝阳区建国门外大街1号
  static String getFullLocationText(Location location) {
    final parts = <String>[];
    
    // 第一行：placeName + placeType 图标
    if (location.placeName != null && location.placeName!.trim().isNotEmpty) {
      if (location.placeType != null) {
        parts.add('${location.placeType!.icon} ${location.placeName}');
      } else {
        parts.add(location.placeName!);
      }
    }
    
    // 第二行：address（如果有且与 placeName 不同）
    if (location.address != null && location.address!.trim().isNotEmpty) {
      parts.add(location.address!);
    }
    
    // 如果都没有，尝试显示 placeType
    if (parts.isEmpty && location.placeType != null) {
      parts.add('${location.placeType!.icon} ${location.placeType!.label}');
    }
    
    // 如果还是没有，显示默认文本
    if (parts.isEmpty) {
      parts.add('未知地点');
    }
    
    return parts.join('\n');
  }
  
  /// 检查地点是否有 GPS 坐标
  /// 
  /// 调用者：
  /// - 地图功能：判断是否可以在地图上显示
  /// 
  /// 返回：
  /// - true：有 GPS 坐标
  /// - false：没有 GPS 坐标
  static bool hasCoordinates(Location location) {
    return location.latitude != null && location.longitude != null;
  }
  
  /// 检查地点是否为空（没有任何信息）
  /// 
  /// 调用者：
  /// - 创建记录页面：判断是否需要提示用户输入地点
  /// 
  /// 返回：
  /// - true：地点为空
  /// - false：地点有信息
  static bool isLocationEmpty(Location location) {
    return location.latitude == null &&
           location.longitude == null &&
           (location.address == null || location.address!.trim().isEmpty) &&
           (location.placeName == null || location.placeName!.trim().isEmpty) &&
           location.placeType == null;
  }
}

