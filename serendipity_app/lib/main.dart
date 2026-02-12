import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'features/home/main_navigation_page.dart';
import 'models/enums.dart';
import 'models/encounter_record.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Hive
  await Hive.initFlutter();
  
  // 注册所有 TypeAdapter
  // 枚举类型 (typeId: 10-23)
  Hive.registerAdapter(EncounterStatusAdapter());
  Hive.registerAdapter(EmotionIntensityAdapter());
  Hive.registerAdapter(PlaceTypeAdapter());
  Hive.registerAdapter(WeatherAdapter());
  Hive.registerAdapter(MatchStatusAdapter());
  Hive.registerAdapter(MatchConfidenceAdapter());
  Hive.registerAdapter(VerificationChoiceAdapter());
  Hive.registerAdapter(AuthProviderAdapter());
  Hive.registerAdapter(MembershipTierAdapter());
  Hive.registerAdapter(MembershipStatusAdapter());
  Hive.registerAdapter(PaymentMethodAdapter());
  Hive.registerAdapter(PaymentStatusAdapter());
  Hive.registerAdapter(AppThemeAdapter());
  Hive.registerAdapter(CreditChangeReasonAdapter());
  
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serendipity',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const MainNavigationPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
