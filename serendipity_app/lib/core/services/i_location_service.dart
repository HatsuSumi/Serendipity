import '../../models/location_result.dart';

/// 定位服务接口
/// 
/// 定义定位服务的抽象方法，遵循依赖倒置原则（DIP）。
/// 
/// 调用者：
/// - LocationProvider：状态管理层
/// 
/// 实现者：
/// - GeolocatorLocationService：使用 geolocator 插件的实现
/// 
/// 设计原则：
/// - 依赖倒置原则（DIP）：依赖抽象而非具体实现
/// - 开闭原则（OCP）：可以轻松添加新的定位服务实现
abstract class ILocationService {
  /// 请求定位权限
  /// 
  /// 返回：
  /// - true：权限已授予
  /// - false：权限被拒绝
  /// 
  /// 调用者：LocationProvider.requestPermission()
  Future<bool> requestPermission();
  
  /// 检查定位权限状态
  /// 
  /// 返回：
  /// - true：权限已授予
  /// - false：权限未授予或被拒绝
  /// 
  /// 调用者：LocationProvider.checkPermission()
  Future<bool> checkPermission();
  
  /// 获取当前位置
  /// 
  /// 返回：LocationResult（包含坐标和地址，或错误信息）
  /// 
  /// 调用者：LocationProvider.getCurrentLocation()
  /// 
  /// Fail Fast：
  /// - 如果权限未授予，返回错误结果
  /// - 如果定位失败，返回错误结果
  Future<LocationResult> getCurrentLocation();
  
  /// 打开系统设置页面（引导用户开启定位权限）
  /// 
  /// 返回：
  /// - true：成功打开设置页面
  /// - false：无法打开设置页面
  /// 
  /// 调用者：UI 层（权限被拒绝时的引导按钮）
  Future<bool> openSettings();
}

