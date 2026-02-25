/// 地区数据模型
/// 
/// 职责：
/// - 表示省市区三级数据结构
/// - 提供数据解析方法
/// - 不包含业务逻辑
class RegionData {
  final String name;
  final List<CityData> cities;

  const RegionData({
    required this.name,
    required this.cities,
  });

  factory RegionData.fromJson(Map<String, dynamic> json) {
    return RegionData(
      name: json['name'] as String,
      cities: (json['city'] as List<dynamic>)
          .map((city) => CityData.fromJson(city as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'city': cities.map((city) => city.toJson()).toList(),
    };
  }
}

/// 城市数据模型
class CityData {
  final String name;
  final List<String> areas;

  const CityData({
    required this.name,
    required this.areas,
  });

  factory CityData.fromJson(Map<String, dynamic> json) {
    return CityData(
      name: json['name'] as String,
      areas: (json['area'] as List<dynamic>)
          .map((area) => area as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'area': areas,
    };
  }
}

/// 选中的地区信息
class SelectedRegion {
  final String? province;
  final String? city;
  final String? area;

  const SelectedRegion({
    this.province,
    this.city,
    this.area,
  });

  /// 是否为空
  bool get isEmpty => province == null && city == null && area == null;

  /// 是否完整（三级都选中）
  bool get isComplete => province != null && city != null && area != null;

  /// 获取完整地址字符串
  String get fullAddress {
    final parts = <String>[];
    if (province != null) parts.add(province!);
    if (city != null) parts.add(city!);
    if (area != null) parts.add(area!);
    return parts.join('');
  }

  /// 获取显示文本
  String get displayText {
    if (isEmpty) return '请选择地区';
    return fullAddress;
  }

  SelectedRegion copyWith({
    String? province,
    String? city,
    String? area,
  }) {
    return SelectedRegion(
      province: province ?? this.province,
      city: city ?? this.city,
      area: area ?? this.area,
    );
  }

  /// 清空选择
  SelectedRegion clear() {
    return const SelectedRegion();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedRegion &&
        other.province == province &&
        other.city == city &&
        other.area == area;
  }

  @override
  int get hashCode => Object.hash(province, city, area);
}

