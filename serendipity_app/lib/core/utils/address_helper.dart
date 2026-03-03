import '../../models/encounter_record.dart';
import '../../models/region_data.dart';

/// 地址工具类
/// 
/// 提供地址相关的解析和统计功能：
/// - 从地址字符串中提取省市区信息
/// - 统计不同城市的数量
/// 
/// 调用者：
/// - RecordAchievementChecker：检测城市相关成就
/// - CommunityRepository：从地址提取省市区信息
/// 
/// 设计原则：
/// - 单一职责：只负责地址解析和统计
/// - 无状态：所有方法都是静态的，不依赖实例状态
/// - Fail Fast：参数非法立即返回 null，不抛异常（工具类容错）
class AddressHelper {
  AddressHelper._(); // 私有构造函数，防止实例化

  /// 从地址字符串中提取省市区信息
  /// 
  /// 支持的格式：
  /// - "北京市朝阳区..." -> SelectedRegion(province: null, city: "北京市", area: "朝阳区")
  /// - "上海市浦东新区..." -> SelectedRegion(province: null, city: "上海市", area: "浦东新区")
  /// - "广东省深圳市南山区..." -> SelectedRegion(province: "广东省", city: "深圳市", area: "南山区")
  /// - "江苏省南京市玄武区..." -> SelectedRegion(province: "江苏省", city: "南京市", area: "玄武区")
  /// 
  /// 返回：SelectedRegion 对象，如果无法提取则返回空的 SelectedRegion
  /// 
  /// 调用者：
  /// - CommunityRepository._createPostFromRecord()
  static SelectedRegion extractRegion(String? address) {
    // Fail Fast：地址为空，返回空 SelectedRegion
    if (address == null || address.isEmpty) {
      return const SelectedRegion();
    }

    String? province;
    String? city;
    String? area;

    // 1. 提取省份（如果有）
    final provinceMatch = RegExp(r'^(.+?省)').firstMatch(address);
    if (provinceMatch != null) {
      province = provinceMatch.group(1);
    }

    // 2. 提取城市
    // 如果有省份，从省份后面开始查找市
    final cityStartIndex = province != null ? province.length : 0;
    final cityPattern = RegExp(r'(.+?市)');
    final cityMatch = cityPattern.firstMatch(address.substring(cityStartIndex));
    if (cityMatch != null) {
      city = cityMatch.group(1);
    }

    // 3. 提取区县
    // 如果有城市，从城市后面开始查找区/县
    if (city != null) {
      final areaStartIndex = cityStartIndex + city.length;
      if (areaStartIndex < address.length) {
        // 匹配区、县、市（县级市）
        final areaPattern = RegExp(r'(.+?[区县市])');
        final areaMatch = areaPattern.firstMatch(address.substring(areaStartIndex));
        if (areaMatch != null) {
          area = areaMatch.group(1);
        }
      }
    }

    return SelectedRegion(
      province: province,
      city: city,
      area: area,
    );
  }

  /// 从地址字符串中提取城市名称（向后兼容）
  /// 
  /// 支持的格式：
  /// - "北京市朝阳区..." -> "北京市"
  /// - "上海市浦东新区..." -> "上海市"
  /// - "广东省深圳市..." -> "深圳市"
  /// - "江苏省南京市..." -> "南京市"
  /// 
  /// 返回：城市名称，如果无法提取则返回 null
  /// 
  /// 调用者：
  /// - RecordAchievementChecker.countUniqueCities()
  static String? extractCity(String? address) {
    final region = extractRegion(address);
    return region.city;
  }

  /// 统计不同城市的数量
  /// 
  /// 参数：
  /// - records: 所有记录列表
  /// 
  /// 返回：不同城市的数量
  /// 
  /// 调用者：
  /// - RecordAchievementChecker：检测"城市漫游者"成就
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

