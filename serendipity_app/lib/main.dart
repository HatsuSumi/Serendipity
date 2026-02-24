import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/storage_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/notification_service.dart';
import 'core/repositories/record_repository.dart';
import 'core/repositories/check_in_repository.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/first_launch_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/utils/smart_navigator.dart';
import 'features/home/main_navigation_page.dart';
import 'features/auth/welcome_page.dart';
import 'features/record/record_detail_page.dart';
import 'features/story_line/story_line_detail_page.dart';
import 'models/enums.dart';
import 'models/encounter_record.dart';
import 'models/story_line.dart';
import 'models/user.dart';
import 'models/achievement.dart';
import 'models/check_in_record.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Hive
  await Hive.initFlutter();
  
  // 注册所有 TypeAdapter
  // 枚举类型 (typeId: 10-22, 30)
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
  Hive.registerAdapter(AchievementCategoryAdapter());
  
  // 数据模型类型 (typeId: 0-2, 31, 32)
  Hive.registerAdapter(TagWithNoteAdapter());
  Hive.registerAdapter(LocationAdapter());
  Hive.registerAdapter(EncounterRecordAdapter());
  Hive.registerAdapter(AchievementAdapter());
  Hive.registerAdapter(CheckInRecordAdapter());
  
  // 故事线类型 (typeId: 3)
  Hive.registerAdapter(StoryLineAdapter());
  
  // 用户类型 (typeId: 4)
  Hive.registerAdapter(UserAdapter());
  
  // 初始化存储服务
  await StorageService().init();
  
  // 初始化通知服务
  try {
    final storageService = StorageService();
    final checkInRepository = CheckInRepository(storageService);
    final notificationService = NotificationService(checkInRepository);
    await notificationService.initialize();
  } catch (e) {
    // 通知服务初始化失败不影响应用启动
    // 生产环境应记录错误日志
    if (kDebugMode) {
      print('通知服务初始化失败: $e');
    }
  }
  
  // 注册循环页面对（用于智能导航）
  SmartNavigator.registerCyclicPair(RecordDetailPage, StoryLineDetailPage);
  
  // 启用调试模式（仅在开发模式下）
  if (kDebugMode) {
    SmartNavigator.debugMode = true;
  }
  
  // 验证数据一致性（仅在开发模式下）
  if (kDebugMode) {
    try {
      final recordRepo = RecordRepository(StorageService());
      recordRepo.validateDataConsistency();
    } catch (e) {
      // 开发模式下只打印警告，不阻止应用启动
    }
  }
  
  // 测试模式下初始化测试用户 box
  if (kDebugMode && AppConfig.enableTestMode) {
    await Hive.openBox<User>('test_users');
    await Hive.openBox('test_session');
    await Hive.openBox('test_passwords'); // 新增：初始化密码 box
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
    
    // 监听首次启动状态
    final firstLaunchState = ref.watch(firstLaunchProvider);
    
    // 监听认证状态变化，处理退出登录导航
    // 遵循原则：不在 build 中产生副作用，使用 ref.listen
    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      // 只在从已登录变为未登录时跳转到欢迎页
      // 注意：不清空导航栈，保留用户的浏览历史
      final wasLoggedIn = previous?.value != null;
      final isLoggedOut = next.value == null;
      
      if (wasLoggedIn && isLoggedOut) {
        // 使用 Future.microtask 避免在 build 期间修改导航栈
        // 遵循原则：异步操作必须处理异常
        Future.microtask(() {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
            (route) => false,
          );
        });
      }
    });
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Serendipity',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: _buildHome(authState, firstLaunchState, ref),
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
  
  /// 构建主页
  /// 
  /// 遵循原则：
  /// - 单一职责（SRP）：只负责根据状态决定显示哪个页面
  /// - 用户体验优先：加载和错误状态也显示主页，不阻碍用户使用
  /// - Fail Fast：状态异常时有明确的 fallback
  /// 
  /// 逻辑：
  /// 1. 首次启动 → 显示欢迎页（无论是否登录）
  /// 2. 非首次启动 → 显示主页（无论是否登录）
  /// 3. 已登录 → 触发云端同步
  /// 4. 加载中/错误 → 显示主页（不阻碍用户使用）
  Widget _buildHome(
    AsyncValue<User?> authState,
    AsyncValue<bool> firstLaunchState,
    WidgetRef ref,
  ) {
    // 处理首次启动状态加载中或错误的情况
    // 遵循原则：用户体验优先，不阻碍用户使用
    return firstLaunchState.when(
      data: (isFirstLaunch) {
        // 首次启动，显示欢迎页
        if (isFirstLaunch) {
          return const WelcomePage();
        }
        
        // 非首次启动，根据登录状态决定是否触发同步
        return authState.when(
          data: (user) {
            // 已登录，触发云端同步
            if (user != null) {
              _triggerSync(ref, user);
            }
            
            // 无论是否登录，都显示主页（支持离线模式）
            return const MainNavigationPage();
          },
          loading: () {
            // 加载中也显示主页，不阻碍用户使用
            return const MainNavigationPage();
          },
          error: (error, stack) {
            // 错误时也显示主页，不阻碍用户使用
            return const MainNavigationPage();
          },
        );
      },
      loading: () {
        // 首次启动状态加载中，显示加载页面
        return const _LoadingPage();
      },
      error: (error, stack) {
        // 首次启动状态检查失败，显示错误页面
        return _ErrorPage(error: error);
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
