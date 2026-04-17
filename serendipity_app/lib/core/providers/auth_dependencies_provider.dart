import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../repositories/custom_server_auth_repository.dart';
import '../repositories/i_auth_repository.dart';
import '../repositories/test_auth_repository.dart';
import '../services/device_identity_service.dart';
import '../services/http_client_service.dart';
import '../services/i_storage_service.dart';

/// 存储服务 Provider
final storageServiceProvider = Provider<IStorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden in main.dart');
});

/// HTTP 客户端服务 Provider
final httpClientServiceProvider = Provider<HttpClientService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final deviceIdentityService = ref.watch(deviceIdentityServiceProvider);
  return HttpClientService(
    storage: storage,
    deviceIdentityService: deviceIdentityService,
  );
});

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return DeviceIdentityService(storage: storage);
});

/// 认证仓储 Provider
/// 
/// 依赖抽象接口 IAuthRepository，不依赖具体实现。
/// 遵循依赖倒置原则（DIP）：切换后端只需修改 AppConfig.serverType。
/// 
/// 后端选择：
/// - ServerType.test：使用 TestAuthRepository（测试模式）
/// - ServerType.customServer：使用 CustomServerAuthRepository（自建服务器）
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  switch (AppConfig.serverType) {
    case ServerType.test:
      return TestAuthRepository();

    case ServerType.customServer:
      final httpClient = ref.watch(httpClientServiceProvider);
      final deviceIdentityService = ref.watch(deviceIdentityServiceProvider);
      return CustomServerAuthRepository(
        httpClient: httpClient,
        deviceIdentityService: deviceIdentityService,
      );
  }
});

