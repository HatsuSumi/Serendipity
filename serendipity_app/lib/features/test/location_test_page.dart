import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/location_provider.dart';
import '../../core/utils/location_helper.dart';
import '../../models/encounter_record.dart';

/// GPS 定位测试页面
/// 
/// 用于测试 GPS 定位服务的各项功能。
/// 
/// 测试项目：
/// 1. 检查定位权限
/// 2. 请求定位权限
/// 3. 获取当前位置
/// 4. 显示定位结果
/// 5. 打开系统设置
class LocationTestPage extends ConsumerWidget {
  const LocationTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS 定位测试'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 权限状态
            _buildPermissionStatus(locationState),
            const SizedBox(height: 16),
            
            // 定位状态
            _buildLocationStatus(locationState),
            const SizedBox(height: 16),
            
            // 操作按钮
            _buildActionButtons(context, ref, locationState),
            const SizedBox(height: 16),
            
            // 定位结果
            if (locationState.result != null)
              _buildLocationResult(locationState),
          ],
        ),
      ),
    );
  }
  
  /// 权限状态卡片
  Widget _buildPermissionStatus(LocationState state) {
    final hasPermission = state.hasPermission;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📍 定位权限状态',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  hasPermission == true
                      ? Icons.check_circle
                      : hasPermission == false
                          ? Icons.cancel
                          : Icons.help,
                  color: hasPermission == true
                      ? Colors.green
                      : hasPermission == false
                          ? Colors.red
                          : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  hasPermission == true
                      ? '已授予'
                      : hasPermission == false
                          ? '未授予'
                          : '未检查',
                  style: TextStyle(
                    fontSize: 16,
                    color: hasPermission == true
                        ? Colors.green
                        : hasPermission == false
                            ? Colors.red
                            : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 定位状态卡片
  Widget _buildLocationStatus(LocationState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌍 定位状态',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (state.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    state.result?.isSuccess == true
                        ? Icons.location_on
                        : Icons.location_off,
                    color: state.result?.isSuccess == true
                        ? Colors.green
                        : Colors.grey,
                  ),
                const SizedBox(width: 8),
                Text(
                  state.isLoading
                      ? '定位中...'
                      : state.result?.isSuccess == true
                          ? '定位成功'
                          : state.result != null
                              ? '定位失败'
                              : '未开始定位',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 操作按钮
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    LocationState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 检查权限
        ElevatedButton.icon(
          onPressed: state.isLoading
              ? null
              : () async {
                  await ref.read(locationProvider.notifier).checkPermission();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.hasPermission == true
                              ? '✅ 已有定位权限'
                              : '❌ 未授予定位权限',
                        ),
                      ),
                    );
                  }
                },
          icon: const Icon(Icons.check),
          label: const Text('检查定位权限'),
        ),
        const SizedBox(height: 8),
        
        // 请求权限
        ElevatedButton.icon(
          onPressed: state.isLoading
              ? null
              : () async {
                  final granted = await ref
                      .read(locationProvider.notifier)
                      .requestPermission();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? '✅ 权限已授予'
                              : '❌ 权限被拒绝',
                        ),
                      ),
                    );
                  }
                },
          icon: const Icon(Icons.location_on),
          label: const Text('请求定位权限'),
        ),
        const SizedBox(height: 8),
        
        // 获取位置
        ElevatedButton.icon(
          onPressed: state.isLoading
              ? null
              : () async {
                  await ref.read(locationProvider.notifier).getCurrentLocation();
                },
          icon: const Icon(Icons.my_location),
          label: const Text('获取当前位置'),
        ),
        const SizedBox(height: 8),
        
        // 打开设置
        ElevatedButton.icon(
          onPressed: state.isLoading
              ? null
              : () async {
                  final opened = await ref
                      .read(locationProvider.notifier)
                      .openSettings();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          opened
                              ? '✅ 已打开系统设置'
                              : '❌ 无法打开系统设置',
                        ),
                      ),
                    );
                  }
                },
          icon: const Icon(Icons.settings),
          label: const Text('打开系统设置'),
        ),
        const SizedBox(height: 8),
        
        // 清空结果
        if (state.result != null)
          OutlinedButton.icon(
            onPressed: state.isLoading
                ? null
                : () {
                    ref.read(locationProvider.notifier).clearResult();
                  },
            icon: const Icon(Icons.clear),
            label: const Text('清空结果'),
          ),
      ],
    );
  }
  
  /// 定位结果卡片
  Widget _buildLocationResult(LocationState state) {
    final result = state.result!;
    
    if (!result.isSuccess) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    '定位失败',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.errorMessage ?? '未知错误',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    // 成功结果
    final location = Location(
      latitude: result.latitude,
      longitude: result.longitude,
      address: result.address,
    );
    
    return Builder(
      builder: (context) {
        // 使用主题颜色
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Card(
          color: isDark 
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isDark 
                          ? theme.colorScheme.primary
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '定位成功',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark 
                            ? theme.colorScheme.primary
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // GPS 坐标
                _buildInfoRow('纬度', result.latitude?.toString() ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow('经度', result.longitude?.toString() ?? '-'),
                const SizedBox(height: 8),
                
                // 地址
                _buildInfoRow(
                  '地址',
                  result.address ?? '逆地理编码失败',
                ),
                const SizedBox(height: 16),
                
                // LocationHelper 测试
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'LocationHelper 测试：',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'getDisplayLocation',
                  LocationHelper.getDisplayLocation(location),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'hasCoordinates',
                  LocationHelper.hasCoordinates(location).toString(),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'isEmpty',
                  LocationHelper.isEmpty(location).toString(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label：',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}

