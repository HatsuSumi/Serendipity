import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'i_location_service.dart';
import '../../models/location_result.dart';

/// Geolocator 定位服务实现
/// 
/// 使用 geolocator 和 geocoding 插件实现定位功能。
/// 
/// 调用者：
/// - LocationProvider：通过 ILocationService 接口调用
/// 
/// 设计原则：
/// - 单一职责：只负责定位相关操作
/// - 依赖倒置：实现 ILocationService 接口
/// - Fail Fast：所有异常都被捕获并转换为 LocationResult.failure
class GeolocatorLocationService implements ILocationService {
  /// 定位超时时间（秒）
  static const int _timeoutSeconds = 10;
  
  @override
  Future<bool> requestPermission() async {
    try {
      // 检查定位服务是否启用
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
      
      // 检查当前权限状态
      LocationPermission permission = await Geolocator.checkPermission();
      
      // 如果权限被永久拒绝，无法请求
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
      
      // 如果权限被拒绝，请求权限
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      // 返回是否授予权限
      return permission == LocationPermission.whileInUse ||
             permission == LocationPermission.always;
    } catch (e) {
      // 捕获所有异常，返回 false
      return false;
    }
  }
  
  @override
  Future<bool> checkPermission() async {
    try {
      // 检查定位服务是否启用
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
      
      // 检查权限状态
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
             permission == LocationPermission.always;
    } catch (e) {
      // 捕获所有异常，返回 false
      return false;
    }
  }
  
  @override
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Fail Fast：检查权限
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        return LocationResult.failure(
          errorMessage: '定位权限未授予，请在设置中开启',
        );
      }
      
      // 获取当前位置（带超时）
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          throw Exception('定位超时，请检查网络或GPS信号');
        },
      );
      
      // 尝试逆地理编码（获取地址）
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: _timeoutSeconds),
        );
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          // 拼接地址：国家 + 省 + 市 + 区 + 街道
          final parts = <String>[];
          if (placemark.country != null && placemark.country!.isNotEmpty) {
            parts.add(placemark.country!);
          }
          if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
            parts.add(placemark.administrativeArea!);
          }
          if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            parts.add(placemark.locality!);
          }
          if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
            parts.add(placemark.subLocality!);
          }
          if (placemark.street != null && placemark.street!.isNotEmpty) {
            parts.add(placemark.street!);
          }
          
          address = parts.join('');
        }
      } catch (e) {
        // 逆地理编码失败不影响定位结果，只是没有地址
        address = null;
      }
      
      // 返回成功结果
      return LocationResult.success(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      // 捕获所有异常，返回失败结果
      return LocationResult.failure(
        errorMessage: _extractErrorMessage(e),
      );
    }
  }
  
  @override
  Future<bool> openSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      return false;
    }
  }
  
  /// 提取错误信息
  /// 
  /// 将异常转换为用户友好的错误信息。
  /// 
  /// 调用者：getCurrentLocation()
  String _extractErrorMessage(Object error) {
    final errorString = error.toString();
    
    // 移除 "Exception: " 前缀
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring('Exception: '.length);
    }
    
    // 常见错误处理
    if (errorString.contains('timeout') || errorString.contains('超时')) {
      return '定位超时，请检查网络或GPS信号';
    }
    
    if (errorString.contains('permission') || errorString.contains('权限')) {
      return '定位权限未授予';
    }
    
    if (errorString.contains('service') || errorString.contains('服务')) {
      return '定位服务未启用';
    }
    
    // 默认错误信息
    return '定位失败，请稍后重试';
  }
}

