import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/network_monitor_service.dart';
import 'core/services/push_token_sync_service.dart';
import 'core/repositories/check_in_repository.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/first_launch_provider.dart';
import 'core/providers/user_settings_provider.dart' show notificationServiceProvider;
import 'core/theme/app_theme.dart';
import 'core/utils/smart_navigator.dart';
import 'features/home/main_navigation_page.dart';
import 'features/auth/welcome_page.dart';
import 'features/record/record_detail_page.dart';
import 'features/story_line/story_line_detail_page.dart';
import 'models/enums.dart';
import 'models/encounter_record.dart';
import 'models/story_line.dart';
import 'models/user.dart' as app_user;
import 'models/achievement.dart';
import 'models/check_in_record.dart';
import 'models/sync_history.dart';
// import 'dev_tools/clear_all_data.dart'; // 🧹 开发工具
// import 'dev_tools/create_test_records.dart'; // 📝 创建测试记录

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🧹 开发工具：清空所有数据（测试用）
  // await clearAllData();
  // return; // 清空完后直接退出，不启动 app

  // 📝 开发工具：创建测试记录（测试用）
  // await createTestRecords();
  // return; // 创建完后直接退出，不启动 app
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) {
      print('Firebase 初始化失败: $e');
    }
  }

  // 初始化 Hive
  await Hive.initFlutter();
  
  // 注册所有 TypeAdapter
  // 枚举类型 (typeId: 10-22, 30, 34)
  Hive.registerAdapter(EncounterStatusAdapter());
  Hive.registerAdapter(EmotionIntensityAdapter());
  Hive.registerAdapter(PlaceTypeAdapter());
  Hive.registerAdapter(WeatherAdapter());
  Hive.registerAdapter(AuthProviderAdapter());
  Hive.registerAdapter(MembershipTierAdapter());
  Hive.registerAdapter(MembershipStatusAdapter());
  Hive.registerAdapter(ThemeOptionAdapter());
  Hive.registerAdapter(AchievementCategoryAdapter());
  Hive.registerAdapter(SyncSourceAdapter());
  
  // 数据模型类型 (typeId: 0-2, 31, 32, 33)
  Hive.registerAdapter(TagWithNoteAdapter());
  Hive.registerAdapter(LocationAdapter());
  Hive.registerAdapter(EncounterRecordAdapter());
  Hive.registerAdapter(AchievementAdapter());
  Hive.registerAdapter(CheckInRecordAdapter());
  Hive.registerAdapter(SyncHistoryAdapter());
  
  // 故事线类型 (typeId: 3)
  Hive.registerAdapter(StoryLineAdapter());
  
  // 用户类型 (typeId: 4)
  Hive.registerAdapter(app_user.UserAdapter());
  
  // 初始化存储服务
  final storageService = StorageService();
  await storageService.init();
  
  // 初始化通知服务
  final checkInRepository = CheckInRepository(storageService);
  final notificationService = NotificationService(checkInRepository);

  try {
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
  
  // 运行应用，并提供 storageServiceProvider 的实现
  runApp(
    ProviderScope(
      overrides: [
        // 提供 StorageService 实例给所有 Provider
        storageServiceProvider.overrideWithValue(storageService),
        // 提供已初始化的 NotificationService 单实例给所有 Provider
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

/// 全局导航器 Key
/// 
/// 用于在认证状态变化时控制导航，避免重建整个 MaterialApp
final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // 启动网络监听（在下一帧执行，避免在构建期间访问 Provider）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(networkMonitorServiceProvider).startMonitoring(ref);
      unawaited(ref.read(pushTokenSyncServiceProvider).initialize());
      unawaited(ref.read(pushTokenSyncServiceProvider).syncForAuthenticatedUser());
    });
  }
  
  @override
  void dispose() {
    // 停止网络监听
    ref.read(networkMonitorServiceProvider).stopMonitoring();
    unawaited(ref.read(pushTokenSyncServiceProvider).dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
  /// 3. 加载中/错误 → 显示主页（不阻碍用户使用）
  /// 
  /// 注意：数据同步由 AuthNotifier 自动处理，无需在此触发
  Widget _buildHome(
    AsyncValue<app_user.User?> authState,
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
        
        // 非首次启动，显示主页（无论是否登录，支持离线模式）
        return authState.when(
          data: (user) => const MainNavigationPage(),
          loading: () => const MainNavigationPage(),
          error: (error, stack) => const MainNavigationPage(),
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
