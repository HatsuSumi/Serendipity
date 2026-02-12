import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/records_provider.dart';
import '../timeline/timeline_page.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TimelinePage(), // TA（时间轴）
          Center(child: Text('地图')), // TODO: 地图页面
          Center(child: Text('树洞')), // TODO: 社区页面
          Center(child: Text('我的')), // TODO: 个人页面
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'TA',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '地图',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: '树洞',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                // 跳转到创建记录页面，等待返回
                final result = await context.push('/record/create');
                
                // 如果创建成功，刷新记录列表
                if (result == true && mounted) {
                  ref.read(recordsProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('记录错过'),
            )
          : null,
    );
  }
}

