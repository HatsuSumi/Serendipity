import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 首次启动标记 Provider
/// 
/// 负责检测和管理应用的首次启动状态。
/// 
/// 调用者：
/// - main.dart：应用启动时检查是否首次启动
/// 
/// 设计原则：
/// - 单一职责（SRP）：只负责首次启动标记的读写
/// - 依赖倒置（DIP）：依赖 SharedPreferences 抽象
/// - Fail Fast：SharedPreferences 初始化失败时立即抛异常
/// 
/// 数据流：
/// 1. 应用启动时读取标记
/// 2. 如果是首次启动（标记不存在或为 true），返回 true
/// 3. 同时将标记设置为 false（下次启动不再是首次）
/// 4. 如果不是首次启动，返回 false
class FirstLaunchNotifier extends AsyncNotifier<bool> {
  static const String _key = 'is_first_launch';
  
  @override
  Future<bool> build() async {
    return await _checkAndMarkFirstLaunch();
  }
  
  /// 检查并标记首次启动
  /// 
  /// 返回值：
  /// - true：首次启动
  /// - false：非首次启动
  /// 
  /// 副作用：
  /// - 如果是首次启动，会将标记设置为 false
  Future<bool> _checkAndMarkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 读取标记（默认为 true，即首次启动）
      final isFirst = prefs.getBool(_key) ?? true;
      
      // 如果是首次启动，标记为已启动
      if (isFirst) {
        await prefs.setBool(_key, false);
      }
      
      return isFirst;
    } catch (e) {
      // Fail Fast：SharedPreferences 初始化失败时立即抛异常
      throw StateError('Failed to initialize SharedPreferences: $e');
    }
  }
  
  /// 重置首次启动标记（仅用于测试）
  /// 
  /// 调用者：测试代码
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      
      // 刷新状态
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _checkAndMarkFirstLaunch());
    } catch (e) {
      // Fail Fast：重置失败时立即抛异常
      throw StateError('Failed to reset first launch flag: $e');
    }
  }
}

/// 首次启动标记 Provider
/// 
/// 用法：
/// ```dart
/// final isFirstLaunch = ref.watch(firstLaunchProvider);
/// isFirstLaunch.when(
///   data: (isFirst) => isFirst ? WelcomePage() : MainNavigationPage(),
///   loading: () => LoadingPage(),
///   error: (error, stack) => ErrorPage(error: error),
/// );
/// ```
final firstLaunchProvider = AsyncNotifierProvider<FirstLaunchNotifier, bool>(() {
  return FirstLaunchNotifier();
});

