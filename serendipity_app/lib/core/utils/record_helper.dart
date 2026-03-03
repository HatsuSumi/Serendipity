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
  /// 显示格式：场所类型 + 地点名称/地址（两行显示）
  /// 
  /// 第一行：场所类型（如果有）
  /// 第二行：地点名称（优先）或地址
  /// 
  /// 调用者：
  /// - RecordCard：显示记录卡片
  /// - RecordDetailPage：显示记录详情
  /// - TimelinePage：显示时间轴
  /// 
  /// 示例：
  /// - 有 placeType + placeName：🚇 地铁站\n常去的那家咖啡馆
  /// - 有 placeType + address：🚇 地铁站\n北京市朝阳区建国门外大街1号
  /// - 有 placeName 无 placeType：常去的那家咖啡馆
  /// - 有 address 无 placeType：北京市朝阳区建国门外大街1号
  /// - 只有 placeType：🚇 地铁站
  /// - 都没有：未知地点
  static String getLocationText(Location location) {
    final parts = <String>[];
    
    // 第一行：场所类型（如果有）
    if (location.placeType != null) {
      parts.add('${location.placeType!.icon} ${location.placeType!.label}');
    }
    
    // 第二行：地点名称（优先）或地址
    if (location.placeName != null && location.placeName!.trim().isNotEmpty) {
      parts.add(location.placeName!);
    } else if (location.address != null && location.address!.trim().isNotEmpty) {
      // 如果地址太长，截断显示
      if (location.address!.length > 30) {
        parts.add('${location.address!.substring(0, 30)}...');
      } else {
        parts.add(location.address!);
      }
    }
    
    // 如果都没有，显示默认文本
    if (parts.isEmpty) {
      return '未知地点';
    }
    
    return parts.join('\n');
  }
  
  /// 获取地点的完整显示文本（用于详情页）
  /// 
  /// 显示格式：场所类型 + 地点名称/地址（多行显示，不截断）
  /// 
  /// 第一行：场所类型（如果有）
  /// 第二行：地点名称（如果有）
  /// 第三行：地址（如果有且与地点名称不同）
  /// 
  /// 调用者：
  /// - RecordDetailPage：显示完整地点信息
  /// 
  /// 示例：
  /// - 有 placeType + placeName + address：
  ///   🚇 地铁站
  ///   常去的那家咖啡馆
  ///   北京市朝阳区建国门外大街1号
  /// - 有 placeType + placeName：
  ///   🚇 地铁站
  ///   常去的那家咖啡馆
  /// - 有 placeType + address：
  ///   🚇 地铁站
  ///   北京市朝阳区建国门外大街1号
  /// - 只有 placeName：常去的那家咖啡馆
  /// - 只有 address：北京市朝阳区建国门外大街1号
  /// - 只有 placeType：🚇 地铁站
  /// - 都没有：未知地点
  static String getFullLocationText(Location location) {
    final parts = <String>[];
    
    // 第一行：场所类型（如果有）
    if (location.placeType != null) {
      parts.add('${location.placeType!.icon} ${location.placeType!.label}');
    }
    
    // 第二行：地点名称（如果有）
    if (location.placeName != null && location.placeName!.trim().isNotEmpty) {
      parts.add(location.placeName!);
    }
    
    // 第三行：地址（如果有）
    if (location.address != null && location.address!.trim().isNotEmpty) {
      parts.add(location.address!);
    }
    
    // 如果都没有，显示默认文本
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

  /// 获取社区帖子的地点显示文本
  /// 
  /// 显示优先级：
  /// 1. placeType + address（最标准）
  /// 2. address（标准地址）
  /// 3. placeName（用户输入，无 GPS 时）
  /// 4. province/city/area 或 "未知地点"
  /// 
  /// 示例：
  /// - 有场所类型 + 地址：`地铁 · 北京市朝阳区建国门外大街1号`
  /// - 只有地址：`北京市朝阳区建国门外大街1号`
  /// - 只有场所类型：`地铁`
  /// - 只有 placeName：`常去的那家咖啡馆`
  /// - 只有省市区：`广东省深圳市南山区`
  /// - 都没有：`未知地点`
  /// 
  /// 调用者：CommunityPostCard._buildLocation()
  static String getCommunityLocationText({
    String? placeTypeLabel,
    String? address,
    String? placeName,
    String? province,
    String? city,
    String? area,
  }) {
    String result = '';

    // 第一部分：场所类型（如果有）
    if (placeTypeLabel != null && placeTypeLabel.isNotEmpty) {
      result = placeTypeLabel;
    }

    // 第二部分：标准地址（如果有）
    if (address != null && address.isNotEmpty) {
      if (result.isNotEmpty) {
        result += ' · $address'; // 场所类型 · 地址
      } else {
        result = address; // 只有地址
      }
    }

    // 第三部分：如果没有 GPS，尝试 placeName
    if (result.isEmpty && placeName != null && placeName.isNotEmpty) {
      result = placeName; // 显示用户输入的地点名称
    }

    // 第四部分：如果都没有，尝试拼接省市区
    if (result.isEmpty) {
      final regionParts = <String>[];
      if (province != null && province.isNotEmpty) {
        regionParts.add(province);
      }
      if (city != null && city.isNotEmpty) {
        regionParts.add(city);
      }
      if (area != null && area.isNotEmpty) {
        regionParts.add(area);
      }
      if (regionParts.isNotEmpty) {
        result = regionParts.join('');
      }
    }

    // 实在没有，显示默认文本
    if (result.isEmpty) {
      result = '未知地点';
    }

    return result;
  }
}

