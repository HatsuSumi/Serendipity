import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'i_location_service.dart';
import '../../models/location_result.dart';
import '../config/amap_config.dart';

/// Geolocator 定位服务实现
/// 
/// 使用 geolocator 插件获取 GPS 坐标，使用高德地图 Web API 进行逆地理编码。
/// 
/// 调用者：
/// - LocationProvider：通过 ILocationService 接口调用
/// 
/// 设计原则：
/// - 单一职责：只负责定位相关操作
/// - 依赖倒置：实现 ILocationService 接口
/// - Fail Fast：所有异常都被捕获并转换为 LocationResult.failure
class GeolocatorLocationService implements ILocationService {
  /// GPS 高精度定位超时时间（秒）
  static const int _gpsTimeoutSeconds = 20;

  /// 网络低精度定位超时时间（秒）
  static const int _networkTimeoutSeconds = 5;

  /// 构建高精度定位配置
  ///
  /// 调用者：getCurrentLocation()
  ///
  /// 设计说明：
  /// - Android 显式使用 LocationManager，避免部分真机上 fused provider 长时间无回调
  /// - 其他平台保持默认实现，避免无必要的平台分支扩散
  LocationSettings _buildHighAccuracySettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        forceLocationManager: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
    );
  }

  /// 构建低精度定位配置
  ///
  /// 调用者：getCurrentLocation()
  LocationSettings _buildLowAccuracySettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.low,
        forceLocationManager: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.low,
    );
  }
  
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
      
      // 降级策略：先尝试 GPS 高精度定位，失败则降级到上次已知位置或网络定位
      Position? position;
      
      try {
        // 第一步：尝试 GPS 高精度定位（20秒超时）
        position = await Geolocator.getCurrentPosition(
          locationSettings: _buildHighAccuracySettings(),
        ).timeout(
          const Duration(seconds: _gpsTimeoutSeconds),
          onTimeout: () {
            throw Exception('GPS定位超时');
          },
        );
      } catch (e) {
        // GPS 定位失败，尝试获取上次已知位置（快速降级）
        try {
          position = await Geolocator.getLastKnownPosition();
          
          // 没有上次已知位置，再尝试网络低精度定位
          position ??= await Geolocator.getCurrentPosition(
            locationSettings: _buildLowAccuracySettings(),
          ).timeout(
            const Duration(seconds: _networkTimeoutSeconds),
            onTimeout: () {
              throw Exception('网络定位超时');
            },
          );
        } catch (e) {
          // 所有降级方案都失败，抛出异常
          throw Exception('定位超时，请检查网络或GPS信号');
        }
      }
      
      // 使用高德地图 API 进行逆地理编码（获取地址）
      String? address;
      try {
        address = await _getAddressFromAmap(
          position.latitude,
          position.longitude,
        );
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
      return await Geolocator.openAppSettings();
    } catch (e) {
      return false;
    }
  }
  
  /// 使用高德地图 API 进行逆地理编码
  /// 
  /// 将 GPS 坐标转换为地址文本。
  /// 
  /// 参数：
  /// - [latitude] 纬度
  /// - [longitude] 经度
  /// 
  /// 返回：地址字符串，失败时抛出异常
  /// 
  /// 调用者：getCurrentLocation()
  Future<String> _getAddressFromAmap(double latitude, double longitude) async {
    // 检查 API Key 是否已配置
    if (!AmapConfig.isConfigured) {
      throw Exception('高德地图 API Key 未配置，请在 AmapConfig 中设置');
    }
    
    // 构建请求 URL
    final url = Uri.parse(AmapConfig.geocoderUrl).replace(queryParameters: {
      'key': AmapConfig.apiKey,
      'location': '$longitude,$latitude', // 高德地图格式：经度,纬度
      'output': 'json',
    });
    
    // 发送 HTTP 请求
    final response = await http.get(url).timeout(
      Duration(seconds: AmapConfig.timeoutSeconds),
      onTimeout: () {
        throw Exception('逆地理编码超时');
      },
    );
    
    // 检查 HTTP 状态码
    if (response.statusCode != 200) {
      throw Exception('逆地理编码请求失败：HTTP ${response.statusCode}');
    }
    
    // 解析 JSON 响应
    final data = json.decode(response.body);
    
    // 检查 API 返回状态
    if (data['status'] != '1') {
      throw Exception('逆地理编码失败：${data['info']}');
    }
    
    // 提取地址信息
    final regeocode = data['regeocode'];
    if (regeocode == null) {
      throw Exception('逆地理编码返回数据为空');
    }
    
    // 优先使用 formatted_address（格式化地址）
    final formattedAddress = regeocode['formatted_address'];
    if (formattedAddress != null && formattedAddress.toString().isNotEmpty) {
      return formattedAddress.toString();
    }
    
    // 如果没有 formatted_address，手动拼接地址
    final addressComponent = regeocode['addressComponent'];
    if (addressComponent != null) {
      final parts = <String>[];
      
      // 省
      if (addressComponent['province'] != null) {
        parts.add(addressComponent['province'].toString());
      }
      
      // 市
      if (addressComponent['city'] != null && 
          addressComponent['city'].toString().isNotEmpty &&
          addressComponent['city'].toString() != '[]') {
        parts.add(addressComponent['city'].toString());
      }
      
      // 区
      if (addressComponent['district'] != null) {
        parts.add(addressComponent['district'].toString());
      }
      
      // 街道
      if (addressComponent['township'] != null) {
        parts.add(addressComponent['township'].toString());
      }
      
      if (parts.isNotEmpty) {
        return parts.join('');
      }
    }
    
    throw Exception('无法解析地址信息');
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
    
    // Geolocator 特定错误（通过类型判断）
    if (error is LocationServiceDisabledException) {
      return '定位服务未启用，请在系统设置中开启';
    }
    
    if (error is PermissionDeniedException) {
      return '定位权限被拒绝，请在设置中授予权限';
    }
    
    // 超时错误
    if (errorString.contains('timeout') || errorString.contains('超时')) {
      return '定位超时，请检查网络或GPS信号';
    }
    
    // 权限相关错误
    if (errorString.contains('permission') || errorString.contains('权限')) {
      return '定位权限未授予，请在设置中开启';
    }
    
    // 服务相关错误
    if (errorString.contains('service') || errorString.contains('服务')) {
      return '定位服务未启用，请在系统设置中开启';
    }
    
    // 网络错误
    if (errorString.contains('network') || errorString.contains('网络') ||
        errorString.contains('connection') || errorString.contains('连接')) {
      return '网络连接失败，请检查网络设置';
    }
    
    // 高德地图 API 错误
    if (errorString.contains('高德') || errorString.contains('amap') ||
        errorString.contains('API') || errorString.contains('逆地理编码')) {
      return '地址解析失败，但GPS坐标已获取';
    }
    
    // HTTP 错误
    if (errorString.contains('HTTP') || errorString.contains('status code')) {
      return '地址解析服务异常，请稍后重试';
    }
    
    // 默认错误信息（保留部分原始信息用于调试）
    // 截取前50个字符，避免错误信息过长
    final truncatedError = errorString.length > 50 
        ? '${errorString.substring(0, 50)}...' 
        : errorString;
    return '定位失败：$truncatedError';
  }
}

