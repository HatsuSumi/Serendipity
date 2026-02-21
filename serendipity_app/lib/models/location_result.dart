/// 定位结果
/// 
/// 封装定位操作的结果，包含成功或失败的信息。
/// 
/// 调用者：
/// - ILocationService.getCurrentLocation()：返回定位结果
/// - LocationProvider：处理定位结果
/// 
/// 设计原则：
/// - Fail Fast：明确区分成功和失败状态
/// - 单一职责：只负责封装定位结果
class LocationResult {
  /// 是否成功
  final bool isSuccess;
  
  /// 纬度（成功时非空）
  final double? latitude;
  
  /// 经度（成功时非空）
  final double? longitude;
  
  /// 地址（成功时可能为空，取决于逆地理编码是否成功）
  final String? address;
  
  /// 错误信息（失败时非空）
  final String? errorMessage;
  
  /// 私有构造函数
  LocationResult._({
    required this.isSuccess,
    this.latitude,
    this.longitude,
    this.address,
    this.errorMessage,
  });
  
  /// 创建成功结果
  /// 
  /// 参数：
  /// - latitude：纬度（必填）
  /// - longitude：经度（必填）
  /// - address：地址（可选，逆地理编码可能失败）
  /// 
  /// Fail Fast：坐标不能为空
  factory LocationResult.success({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    return LocationResult._(
      isSuccess: true,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }
  
  /// 创建失败结果
  /// 
  /// 参数：
  /// - errorMessage：错误信息（必填）
  /// 
  /// Fail Fast：错误信息不能为空
  factory LocationResult.failure({
    required String errorMessage,
  }) {
    if (errorMessage.trim().isEmpty) {
      throw ArgumentError('错误信息不能为空');
    }
    
    return LocationResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

