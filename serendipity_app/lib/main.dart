import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/storage_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/sync_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'features/home/main_navigation_page.dart';
import 'features/auth/welcome_page.dart';
import 'models/enums.dart';
import 'models/encounter_record.dart';
import 'models/story_line.dart';
import 'models/user.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Hive
  await Hive.initFlutter();
  
  // 注册所有 TypeAdapter
  // 枚举类型 (typeId: 10-22)
  Hive.registerAdapter(EncounterStatusAdapter());
  Hive.registerAdapter(EmotionIntensityAdapter());
  Hive.registerAdapter(PlaceTypeAdapter());
  Hive.registerAdapter(WeatherAdapter());
  Hive.registerAdapter(AuthProviderAdapter());
  Hive.registerAdapter(MembershipTierAdapter());
  Hive.registerAdapter(MembershipStatusAdapter());
  Hive.registerAdapter(PaymentMethodAdapter());
  Hive.registerAdapter(PaymentStatusAdapter());
  Hive.registerAdapter(ThemeOptionAdapter());
  
  // 数据模型类型 (typeId: 0-2)
  Hive.registerAdapter(TagWithNoteAdapter());
  Hive.registerAdapter(LocationAdapter());
  Hive.registerAdapter(EncounterRecordAdapter());
  
  // 故事线类型 (typeId: 3)
  Hive.registerAdapter(StoryLineAdapter());
  
  // 用户类型 (typeId: 4)
  Hive.registerAdapter(UserAdapter());
  
  // 初始化存储服务
  await StorageService().init();
  
  // 测试模式下初始化测试用户 box
  if (kDebugMode && AppConfig.enableTestMode) {
    await Hive.openBox<User>('test_users');
    await Hive.openBox('test_session');
    print('🔍 [main] 测试用户 box 已初始化');
  }
  
  // 初始化 Firebase（仅在非测试模式下）
  if (!kDebugMode || !AppConfig.enableTestMode) {
    // Fail Fast：如果初始化失败，显示错误页面
    try {
      await FirebaseService().initialize();
    } catch (e) {
      // Firebase 初始化失败，显示错误页面
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Firebase 初始化失败',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '错误信息：$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '请检查网络连接或稍后重试',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }
  } else {
    print('🔍 [main] 测试模式已启用，跳过 Firebase 初始化');
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// 全局导航器 Key
/// 
/// 用于在认证状态变化时控制导航，避免重建整个 MaterialApp
final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听主题选项变化
    final themeOption = ref.watch(themeOptionProvider);
    
    // 根据主题选项生成对应的主题数据
    final lightTheme = AppTheme.getTheme(themeOption, Brightness.light);
    final darkTheme = AppTheme.getTheme(themeOption, Brightness.dark);
    
    // 确定主题模式
    final themeMode = _getThemeMode(themeOption);
    
    // 监听认证状态
    final authState = ref.watch(authProvider);
    
    print('🔍 [main] authState 变化: ${authState.when(
      data: (user) => user == null ? 'null (未登录)' : 'user: ${user.id}',
      loading: () => 'loading',
      error: (e, _) => 'error: $e',
    )}');
    
    // 监听认证状态变化，处理导航
    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      print('🔍 [main] ref.listen 触发');
      print('🔍 [main] previous: ${previous?.when(
        data: (user) => user == null ? 'null' : 'user: ${user.id}',
        loading: () => 'loading',
        error: (e, _) => 'error: $e',
      )}');
      print('🔍 [main] next: ${next.when(
        data: (user) => user == null ? 'null' : 'user: ${user.id}',
        loading: () => 'loading',
        error: (e, _) => 'error: $e',
      )}');
      
      // 只在从已登录变为未登录时清空导航栈
      final wasLoggedIn = previous?.value != null;
      final isLoggedOut = next.value == null;
      
      if (wasLoggedIn && isLoggedOut) {
        print('🔍 [main] 检测到退出登录，清空导航栈');
        // 使用 Future.microtask 避免在 build 期间修改导航栈
        Future.microtask(() {
          print('🔍 [main] 开始清空导航栈');
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
            (route) => false,
          );
          print('✅ [main] 导航栈已清空，跳转到欢迎页');
        });
      }
    });
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Serendipity',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: authState.when(
        data: (user) {
          print('🔍 [main] 构建 home: ${user == null ? 'WelcomePage' : 'MainNavigationPage'}');
          if (user == null) {
            // 未登录，显示欢迎页
            return const WelcomePage();
          } else {
            // 已登录，显示主页并触发同步
            _triggerSync(ref, user);
            return const MainNavigationPage();
          }
        },
        loading: () => const _LoadingPage(),
        error: (error, stack) => _ErrorPage(error: error),
      ),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // 响应式设计：Web端限制最大宽度为600px
        // 使用 MediaQuery 包裹，避免干扰页面过渡动画
        return MediaQuery(
          data: MediaQuery.of(context),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ClipRect(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// 触发数据同步
  /// 
  /// 调用者：build() - 用户登录后自动调用
  /// 
  /// 注意：使用 Future.microtask 避免在 build 中直接调用异步方法
  void _triggerSync(WidgetRef ref, user) {
    Future.microtask(() async {
      try {
        final syncService = ref.read(syncServiceProvider);
        await syncService.syncAllData(user);
      } catch (e) {
        // 同步失败不影响用户使用
        // 用户可以稍后手动触发同步
      }
    });
  }
  
  /// 根据主题选项确定主题模式
  ThemeMode _getThemeMode(ThemeOption option) {
    switch (option) {
      case ThemeOption.light:
      case ThemeOption.misty:
      case ThemeOption.warm:
      case ThemeOption.autumn:
        return ThemeMode.light;
      case ThemeOption.dark:
      case ThemeOption.midnight:
        return ThemeMode.dark;
      case ThemeOption.system:
        return ThemeMode.system;
    }
  }
}

/// 加载页面
/// 
/// 调用者：MyApp.build() - 检查登录状态时显示
class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// 错误页面
/// 
/// 调用者：MyApp.build() - 认证状态检查失败时显示
class _ErrorPage extends StatelessWidget {
  final Object error;
  
  const _ErrorPage({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                '认证状态检查失败',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '错误信息：$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
