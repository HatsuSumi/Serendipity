import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/location_result.dart';

void main() {
  group('LocationResult', () {
    group('success', () {
      test('创建成功结果时应包含坐标和地址', () {
        final result = LocationResult.success(
          latitude: 39.9042,
          longitude: 116.4074,
          address: '北京市东城区',
        );

        expect(result.isSuccess, true);
        expect(result.latitude, 39.9042);
        expect(result.longitude, 116.4074);
        expect(result.address, '北京市东城区');
        expect(result.errorMessage, null);
      });

      test('创建成功结果时地址可以为空', () {
        final result = LocationResult.success(
          latitude: 39.9042,
          longitude: 116.4074,
        );

        expect(result.isSuccess, true);
        expect(result.latitude, 39.9042);
        expect(result.longitude, 116.4074);
        expect(result.address, null);
        expect(result.errorMessage, null);
      });
    });

    group('failure', () {
      test('创建失败结果时应包含错误信息', () {
        final result = LocationResult.failure(
          errorMessage: '定位权限未授予',
        );

        expect(result.isSuccess, false);
        expect(result.latitude, null);
        expect(result.longitude, null);
        expect(result.address, null);
        expect(result.errorMessage, '定位权限未授予');
      });

      test('创建失败结果时错误信息不能为空 - Fail Fast', () {
        expect(
          () => LocationResult.failure(errorMessage: ''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('创建失败结果时错误信息不能只包含空格 - Fail Fast', () {
        expect(
          () => LocationResult.failure(errorMessage: '   '),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

