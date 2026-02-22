import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serendipity_app/core/providers/location_provider.dart';
import 'package:serendipity_app/core/services/i_location_service.dart';
import 'package:serendipity_app/models/location_result.dart';

/// Mock 定位服务
class MockLocationService implements ILocationService {
  bool _hasPermission = false;
  bool _shouldSucceed = true;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;
  String? _address;

  /// 设置权限状态
  void setPermission(bool hasPermission) {
    _hasPermission = hasPermission;
  }

  /// 设置定位结果
  void setLocationResult({
    required bool shouldSucceed,
    double? latitude,
    double? longitude,
    String? address,
    String? errorMessage,
  }) {
    _shouldSucceed = shouldSucceed;
    _latitude = latitude;
    _longitude = longitude;
    _address = address;
    _errorMessage = errorMessage;
  }

  @override
  Future<bool> checkPermission() async {
    return _hasPermission;
  }

  @override
  Future<bool> requestPermission() async {
    return _hasPermission;
  }

  @override
  Future<LocationResult> getCurrentLocation() async {
    if (!_shouldSucceed) {
      return LocationResult.failure(
        errorMessage: _errorMessage ?? '定位失败',
      );
    }

    return LocationResult.success(
      latitude: _latitude ?? 39.9042,
      longitude: _longitude ?? 116.4074,
      address: _address,
    );
  }

  @override
  Future<bool> openSettings() async {
    return true;
  }
}

void main() {
  group('LocationProvider', () {
    late MockLocationService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockLocationService();
      container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('初始状态', () {
      test('初始状态应该是未加载', () {
        final state = container.read(locationProvider);

        expect(state.isLoading, false);
        expect(state.result, null);
        expect(state.hasPermission, null);
      });
    });

    group('checkPermission', () {
      test('权限已授予时应更新状态', () async {
        mockService.setPermission(true);

        await container.read(locationProvider.notifier).checkPermission();
        final state = container.read(locationProvider);

        expect(state.hasPermission, true);
      });

      test('权限未授予时应更新状态', () async {
        mockService.setPermission(false);

        await container.read(locationProvider.notifier).checkPermission();
        final state = container.read(locationProvider);

        expect(state.hasPermission, false);
      });
    });

    group('requestPermission', () {
      test('用户授予权限时应返回 true 并更新状态', () async {
        mockService.setPermission(true);

        final granted = await container.read(locationProvider.notifier).requestPermission();
        final state = container.read(locationProvider);

        expect(granted, true);
        expect(state.hasPermission, true);
      });

      test('用户拒绝权限时应返回 false 并更新状态', () async {
        mockService.setPermission(false);

        final granted = await container.read(locationProvider.notifier).requestPermission();
        final state = container.read(locationProvider);

        expect(granted, false);
        expect(state.hasPermission, false);
      });
    });

    group('getCurrentLocation', () {
      test('定位成功时应更新状态', () async {
        mockService.setPermission(true);
        mockService.setLocationResult(
          shouldSucceed: true,
          latitude: 39.9042,
          longitude: 116.4074,
          address: '北京市东城区',
        );

        await container.read(locationProvider.notifier).getCurrentLocation();
        final state = container.read(locationProvider);

        expect(state.isLoading, false);
        expect(state.result, isNotNull);
        expect(state.result!.isSuccess, true);
        expect(state.result!.latitude, 39.9042);
        expect(state.result!.longitude, 116.4074);
        expect(state.result!.address, '北京市东城区');
      });

      test('定位失败时应更新状态', () async {
        mockService.setPermission(true);
        mockService.setLocationResult(
          shouldSucceed: false,
          errorMessage: '定位超时',
        );

        await container.read(locationProvider.notifier).getCurrentLocation();
        final state = container.read(locationProvider);

        expect(state.isLoading, false);
        expect(state.result, isNotNull);
        expect(state.result!.isSuccess, false);
        expect(state.result!.errorMessage, '定位超时');
      });

      test('逆地理编码失败时应返回坐标但地址为空', () async {
        mockService.setPermission(true);
        mockService.setLocationResult(
          shouldSucceed: true,
          latitude: 39.9042,
          longitude: 116.4074,
          address: null,
        );

        await container.read(locationProvider.notifier).getCurrentLocation();
        final state = container.read(locationProvider);

        expect(state.isLoading, false);
        expect(state.result, isNotNull);
        expect(state.result!.isSuccess, true);
        expect(state.result!.latitude, 39.9042);
        expect(state.result!.longitude, 116.4074);
        expect(state.result!.address, null);
      });
    });

    group('openSettings', () {
      test('应该调用服务的 openSettings 方法', () async {
        final opened = await container.read(locationProvider.notifier).openSettings();

        expect(opened, true);
      });
    });

    group('clearResult', () {
      test('应该清空定位结果 - 使用优化后的 copyWith', () async {
        mockService.setPermission(true);
        mockService.setLocationResult(
          shouldSucceed: true,
          latitude: 39.9042,
          longitude: 116.4074,
          address: '北京市东城区',
        );

        // 先检查权限
        await container.read(locationProvider.notifier).checkPermission();
        
        // 再获取位置
        await container.read(locationProvider.notifier).getCurrentLocation();
        var state = container.read(locationProvider);
        expect(state.result, isNotNull);
        expect(state.result!.isSuccess, true);
        expect(state.hasPermission, true);

        // 清空结果
        container.read(locationProvider.notifier).clearResult();
        state = container.read(locationProvider);

        // 清空后 result 和 hasPermission 应该为 null
        expect(state.isLoading, false);
        expect(state.result, null);
        expect(state.hasPermission, null);
      });
    });
  });
}

