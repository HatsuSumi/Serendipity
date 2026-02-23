import 'dart:math' as math;
import '../../models/encounter_record.dart';

/// 地理位置工具类
/// 
/// 提供GPS相关的计算功能：
/// - 计算两点之间的距离（Haversine公式）
/// - 统计同一地点的记录数量
/// 
/// 调用者：
/// - RecordAchievementChecker：检测地点相关成就
/// 
/// 设计原则：
/// - 单一职责：只负责地理位置计算
/// - 无状态：所有方法都是静态的，不依赖实例状态
class GeoHelper {
  GeoHelper._(); // 私有构造函数，防止实例化

  /// 地球半径（米）
  static const double _earthRadiusMeters = 6371000.0;

  /// 计算两个GPS坐标之间的距离（米）
  /// 
  /// 使用 Haversine 公式计算球面距离
  /// 
  /// 参数：
  /// - lat1, lon1: 第一个点的纬度和经度
  /// - lat2, lon2: 第二个点的纬度和经度
  /// 
  /// 返回：两点之间的距离（米）
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return _earthRadiusMeters * c;
  }

  /// 统计在同一地点（指定距离内）的记录数量
  /// 
  /// 参数：
  /// - records: 所有记录列表
  /// - targetLat, targetLon: 目标位置的纬度和经度
  /// - radiusMeters: 半径（米），默认100米
  /// 
  /// 返回：在指定半径内的记录数量
  static int countRecordsAtSameLocation(
    List<EncounterRecord> records,
    double targetLat,
    double targetLon, {
    double radiusMeters = 100.0,
  }) {
    return records.where((record) {
      final lat = record.location.latitude;
      final lon = record.location.longitude;
      
      // 跳过没有GPS坐标的记录
      if (lat == null || lon == null) {
        return false;
      }
      
      final distance = calculateDistance(targetLat, targetLon, lat, lon);
      return distance < radiusMeters;
    }).length;
  }

  /// 将角度转换为弧度
  static double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}

