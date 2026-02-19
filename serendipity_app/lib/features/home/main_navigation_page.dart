import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/message_provider.dart';
import '../../core/utils/message_helper.dart';
import '../timeline/timeline_page.dart';
import '../story_line/story_lines_page.dart';
import '../settings/settings_page.dart';
import '../record/create_record_page.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // 在下一帧检查是否有待显示的消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = ref.read(messageProvider);
      if (message != null && mounted) {
        // 显示消息
        switch (message.type) {
          case MessageType.success:
            MessageHelper.showSuccess(context, message.message);
            break;
          case MessageType.error:
            MessageHelper.showError(context, message.message);
            break;
          case MessageType.info:
            MessageHelper.showSuccess(context, message.message);
            break;
        }
        
        // 清除消息
        ref.read(messageProvider.notifier).clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 监听全局消息（用于页面已加载后的消息）
    ref.listen<AppMessage?>(messageProvider, (previous, next) {
      if (next != null) {
        // 根据消息类型显示不同的提示
        switch (next.type) {
          case MessageType.success:
            MessageHelper.showSuccess(context, next.message);
            break;
          case MessageType.error:
            MessageHelper.showError(context, next.message);
            break;
          case MessageType.info:
            // 暂时使用 showSuccess，以后可以添加 showInfo
            MessageHelper.showSuccess(context, next.message);
            break;
        }
        
        // 清除消息，避免重复显示
        Future.microtask(() {
          ref.read(messageProvider.notifier).clear();
        });
      }
    });
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TimelinePage(), // 时间轴
          StoryLinesPage(), // 故事线
          Center(child: Text('地图')), // TODO: 地图页面
          Center(child: Text('树洞')), // TODO: 社区页面
          SettingsPage(), // 我的
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
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: '故事线',
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
              heroTag: 'create_record_fab',
              onPressed: () async {
                // 使用 Navigator.push 以便自定义动画
                final result = await Navigator.of(context).push<bool>(
                  PageRouteBuilder(
                    opaque: false, // 允许透过新页面看到底层
                    barrierColor: Colors.black54, // 添加半透明遮罩
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const CreateRecordPage();
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      // 从底部滑入动画
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOutCubic;
                      
                      var slideTween = Tween(begin: begin, end: end).chain(
                        CurveTween(curve: curve),
                      );
                      
                      return SlideTransition(
                        position: animation.drive(slideTween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                    reverseTransitionDuration: const Duration(milliseconds: 400),
                  ),
                );
                
                // 如果创建成功，让 Provider 失效并自动重新加载
                if (result == true && mounted) {
                  ref.invalidate(recordsProvider);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('创建记录'),
            )
          : null,
    );
  }
}

