import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/i_location_service.dart';
import '../services/geolocator_location_service.dart';
import '../../models/location_result.dart';

/// 定位服务 Provider
/// 
/// 提供 ILocationService 的实例。
/// 
/// 调用者：
/// - locationProvider：获取定位服务实例
final locationServiceProvider = Provider<ILocationService>((ref) {
  return GeolocatorLocationService();
});

/// 定位状态
/// 
/// 封装定位操作的状态。
class LocationState {
  /// 是否正在定位
  final bool isLoading;
  
  /// 定位结果（可能为空）
  final LocationResult? result;
  
  /// 权限状态（可能为空）
  final bool? hasPermission;
  
  const LocationState({
    this.isLoading = false,
    this.result,
    this.hasPermission,
  });
  
  /// 复制并修改部分字段
  LocationState copyWith({
    bool? isLoading,
    LocationResult? result,
    bool? hasPermission,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

/// 定位 Provider
/// 
/// 管理定位相关的状态和操作。
/// 
/// 调用者：
/// - CreateRecordPage：创建记录时获取位置
/// - UI 层：显示定位状态和结果
/// 
/// 设计原则：
/// - 单一职责：只负责定位状态管理
/// - 分层约束：UI 层通过 Provider 调用，不直接访问 Service
class LocationNotifier extends StateNotifier<LocationState> {
  final ILocationService _locationService;
  
  LocationNotifier(this._locationService) : super(const LocationState());
  
  /// 检查定位权限
  /// 
  /// 调用者：UI 层（页面初始化时检查权限）
  Future<void> checkPermission() async {
    final hasPermission = await _locationService.checkPermission();
    state = state.copyWith(hasPermission: hasPermission);
  }
  
  /// 请求定位权限
  /// 
  /// 返回：
  /// - true：权限已授予
  /// - false：权限被拒绝
  /// 
  /// 调用者：UI 层（用户点击"开启定位"按钮）
  Future<bool> requestPermission() async {
    final granted = await _locationService.requestPermission();
    state = state.copyWith(hasPermission: granted);
    return granted;
  }
  
  /// 获取当前位置
  /// 
  /// 调用者：UI 层（创建记录时自动获取位置）
  Future<void> getCurrentLocation() async {
    // 设置加载状态
    state = state.copyWith(isLoading: true);
    
    try {
      // 获取位置
      final result = await _locationService.getCurrentLocation();
      
      // 更新状态
      state = state.copyWith(
        isLoading: false,
        result: result,
      );
    } catch (e) {
      // 捕获异常，更新为失败状态
      state = state.copyWith(
        isLoading: false,
        result: LocationResult.failure(
          errorMessage: '定位失败：${e.toString()}',
        ),
      );
    }
  }
  
  /// 打开系统设置
  /// 
  /// 返回：
  /// - true：成功打开设置页面
  /// - false：无法打开设置页面
  /// 
  /// 调用者：UI 层（权限被拒绝时的引导按钮）
  Future<bool> openSettings() async {
    return await _locationService.openSettings();
  }
  
  /// 清空定位结果
  /// 
  /// 调用者：UI 层（用户手动清空定位结果）
  void clearResult() {
    state = state.copyWith(
      result: LocationResult.failure(errorMessage: ''), // 使用空错误信息表示已清空
    );
  }
}

/// 定位 Provider 实例
/// 
/// 调用者：
/// - UI 层：通过 ref.watch(locationProvider) 监听状态
/// - UI 层：通过 ref.read(locationProvider.notifier) 调用方法
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});

