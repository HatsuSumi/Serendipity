import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/region_data.dart';

/// 地区数据服务
/// 
/// 职责：
/// - 加载地区数据
/// - 提供地区数据查询
/// - 不包含UI逻辑
/// 
/// 遵循原则：
/// - 单一职责：只负责地区数据管理
/// - Fail Fast：数据加载失败立即抛出异常
class RegionService {
  static const String _dataPath = 'assets/data/china_regions.json';
  
  List<RegionData>? _regions;
  bool _isLoaded = false;

  /// 加载地区数据
  /// 
  /// 抛出异常：
  /// - 文件不存在
  /// - JSON 解析失败
  Future<void> loadRegions() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(_dataPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      
      _regions = jsonList
          .map((json) => RegionData.fromJson(json as Map<String, dynamic>))
          .toList();
      
      _isLoaded = true;
    } catch (e) {
      throw Exception('加载地区数据失败: $e');
    }
  }

  /// 获取所有省份
  /// 
  /// 必须先调用 loadRegions()
  List<RegionData> getProvinces() {
    if (!_isLoaded || _regions == null) {
      throw StateError('地区数据未加载，请先调用 loadRegions()');
    }
    return _regions!;
  }

  /// 根据省份名获取城市列表
  /// 
  /// 返回 null 表示省份不存在
  List<CityData>? getCitiesByProvince(String provinceName) {
    if (!_isLoaded || _regions == null) {
      throw StateError('地区数据未加载，请先调用 loadRegions()');
    }

    final province = _regions!.firstWhere(
      (region) => region.name == provinceName,
      orElse: () => throw ArgumentError('省份不存在: $provinceName'),
    );

    return province.cities;
  }

  /// 根据省份和城市名获取区县列表
  /// 
  /// 返回 null 表示城市不存在
  List<String>? getAreasByCity(String provinceName, String cityName) {
    if (!_isLoaded || _regions == null) {
      throw StateError('地区数据未加载，请先调用 loadRegions()');
    }

    final cities = getCitiesByProvince(provinceName);
    if (cities == null) return null;

    final city = cities.firstWhere(
      (c) => c.name == cityName,
      orElse: () => throw ArgumentError('城市不存在: $cityName'),
    );

    return city.areas;
  }

  /// 搜索地区（支持省、市、区）
  /// 
  /// 返回匹配的地区列表
  List<SelectedRegion> searchRegions(String keyword) {
    if (!_isLoaded || _regions == null) {
      throw StateError('地区数据未加载，请先调用 loadRegions()');
    }

    if (keyword.isEmpty) return [];

    final results = <SelectedRegion>[];
    final lowerKeyword = keyword.toLowerCase();

    for (final province in _regions!) {
      // 搜索省份
      if (province.name.toLowerCase().contains(lowerKeyword)) {
        results.add(SelectedRegion(province: province.name));
      }

      // 搜索城市
      for (final city in province.cities) {
        if (city.name.toLowerCase().contains(lowerKeyword)) {
          results.add(SelectedRegion(
            province: province.name,
            city: city.name,
          ));
        }

        // 搜索区县
        for (final area in city.areas) {
          if (area.toLowerCase().contains(lowerKeyword)) {
            results.add(SelectedRegion(
              province: province.name,
              city: city.name,
              area: area,
            ));
          }
        }
      }
    }

    return results;
  }

  /// 重置服务（用于测试）
  void reset() {
    _regions = null;
    _isLoaded = false;
  }
}

