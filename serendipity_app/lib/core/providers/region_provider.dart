import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/region_service.dart';
import '../../models/region_data.dart';

/// 地区服务 Provider
/// 
/// 单例模式，全局共享
final regionServiceProvider = Provider<RegionService>((ref) {
  return RegionService();
});

/// 地区数据加载状态 Provider
/// 
/// 职责：
/// - 管理地区数据加载状态
/// - 提供加载方法
/// - 不包含UI逻辑
/// 
/// 遵循原则：
/// - 单一职责：只负责数据加载状态管理
/// - 单一数据源：地区数据统一从 RegionService 获取
class RegionDataNotifier extends StateNotifier<AsyncValue<void>> {
  final RegionService _regionService;

  RegionDataNotifier(this._regionService) : super(const AsyncValue.loading()) {
    _loadData();
  }

  /// 加载地区数据
  Future<void> _loadData() async {
    state = const AsyncValue.loading();
    
    try {
      await _regionService.loadRegions();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 重新加载
  Future<void> reload() async {
    _regionService.reset();
    await _loadData();
  }
}

/// 地区数据加载状态 Provider
final regionDataProvider = StateNotifierProvider<RegionDataNotifier, AsyncValue<void>>((ref) {
  final regionService = ref.watch(regionServiceProvider);
  return RegionDataNotifier(regionService);
});

/// 省份列表 Provider
/// 
/// 依赖 regionDataProvider，确保数据已加载
final provincesProvider = Provider<List<RegionData>>((ref) {
  // 监听加载状态
  final loadState = ref.watch(regionDataProvider);
  
  // 如果未加载完成，返回空列表
  if (loadState.isLoading || loadState.hasError) {
    return [];
  }

  final regionService = ref.watch(regionServiceProvider);
  return regionService.getProvinces();
});

/// 城市列表 Provider（根据选中的省份）
/// 
/// 参数：provinceName - 省份名称
final citiesProvider = Provider.family<List<CityData>, String?>((ref, provinceName) {
  if (provinceName == null) return [];

  final regionService = ref.watch(regionServiceProvider);
  
  try {
    return regionService.getCitiesByProvince(provinceName) ?? [];
  } catch (e) {
    return [];
  }
});

/// 区县列表 Provider（根据选中的省份和城市）
final areasProvider = Provider.family<List<String>, ({String province, String city})>((ref, params) {
  final regionService = ref.watch(regionServiceProvider);
  
  try {
    return regionService.getAreasByCity(params.province, params.city) ?? [];
  } catch (e) {
    return [];
  }
});

/// 地区搜索 Provider
/// 
/// 参数：keyword - 搜索关键词
final regionSearchProvider = Provider.family<List<SelectedRegion>, String>((ref, keyword) {
  if (keyword.isEmpty) return [];

  final regionService = ref.watch(regionServiceProvider);
  
  try {
    return regionService.searchRegions(keyword);
  } catch (e) {
    return [];
  }
});

