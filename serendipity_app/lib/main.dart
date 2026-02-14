import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/storage_service.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'models/enums.dart';
import 'models/encounter_record.dart';

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
  
  // 初始化存储服务
  await StorageService().init();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

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
    
    return MaterialApp.router(
      title: 'Serendipity',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
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
