import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/main_navigation_page.dart';
import '../../features/record/create_record_page.dart';
import '../../features/record/record_detail_page.dart';
import '../../models/encounter_record.dart';

/// 应用路由配置
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // 主导航页（首页）
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainNavigationPage(),
      ),
      
      // 创建记录页
      GoRoute(
        path: '/record/create',
        name: 'createRecord',
        builder: (context, state) => const CreateRecordPage(),
      ),
      
      // 记录详情页
      GoRoute(
        path: '/record/detail',
        name: 'recordDetail',
        builder: (context, state) {
          final record = state.extra as EncounterRecord?;
          if (record == null) {
            // 如果没有传递记录对象，返回错误页面
            return Scaffold(
              appBar: AppBar(title: const Text('错误')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('记录数据丢失'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('返回首页'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RecordDetailPage(record: record);
        },
      ),
    ],
    
    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '页面不存在',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
}

