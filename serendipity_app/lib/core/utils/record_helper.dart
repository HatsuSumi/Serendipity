import '../../models/encounter_record.dart';

/// 记录相关的工具类
/// 
/// 提供记录数据的通用处理方法
class RecordHelper {
  RecordHelper._(); // 私有构造函数，防止实例化

  /// 获取记录的地点显示文本
  /// 
  /// 优先级：placeName > address > placeType > '未知地点'
  /// 
  /// 示例：
  /// ```dart
  /// final locationText = RecordHelper.getLocationText(record);
  /// ```
  static String getLocationText(EncounterRecord record) {
    // 优先使用地点名称
    if (record.location.placeName != null && record.location.placeName!.isNotEmpty) {
      return record.location.placeName!;
    }
    
    // 其次使用详细地址
    if (record.location.address != null && record.location.address!.isNotEmpty) {
      return record.location.address!;
    }
    
    // 再次使用场所类型
    if (record.location.placeType != null) {
      return record.location.placeType!.label;
    }
    
    // 默认返回未知地点
    return '未知地点';
  }
}

