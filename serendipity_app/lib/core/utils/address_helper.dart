import '../../models/encounter_record.dart';

/// 地址工具类
/// 
/// 提供地址相关的解析和统计功能：
/// - 从地址字符串中提取城市名称
/// - 统计不同城市的数量
/// 
/// 调用者：
/// - RecordAchievementChecker：检测城市相关成就
/// 
/// 设计原则：
/// - 单一职责：只负责地址解析和统计
/// - 无状态：所有方法都是静态的，不依赖实例状态
class AddressHelper {
  AddressHelper._(); // 私有构造函数，防止实例化

  /// 从地址字符串中提取城市名称
  /// 
  /// 支持的格式：
  /// - "北京市朝阳区..." -> "北京市"
  /// - "上海市浦东新区..." -> "上海市"
  /// - "广东省深圳市..." -> "深圳市"
  /// - "江苏省南京市..." -> "南京市"
  /// 
  /// 返回：城市名称，如果无法提取则返回 null
  static String? extractCity(String? address) {
    if (address == null || address.isEmpty) {
      return null;
    }

    // 尝试匹配 "XX市"
    final cityMatch = RegExp(r'([^省]+?市)').firstMatch(address);
    if (cityMatch != null) {
      return cityMatch.group(1);
    }

    // 尝试匹配 "XX省"（如果没有市级信息）
    final provinceMatch = RegExp(r'([^省]+?省)').firstMatch(address);
    if (provinceMatch != null) {
      return provinceMatch.group(1);
    }

    return null;
  }

  /// 统计不同城市的数量
  /// 
  /// 参数：
  /// - records: 所有记录列表
  /// 
  /// 返回：不同城市的数量
  static int countUniqueCities(List<EncounterRecord> records) {
    final cities = <String>{};
    
    for (final record in records) {
      final city = extractCity(record.location.address);
      if (city != null) {
        cities.add(city);
      }
    }
    
    return cities.length;
  }
}

